using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.ChargingSessionDto;
using Infrastructure.Data;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace BusinessLogic.Services;

public class ChargingSessionService(EVCSMSContext db, DriverJourneyService journey, IConfiguration config) : IChargingSessionService
{
    public async Task<IServiceResult> GetList()
    {
        var rows = await db.ChargingSessions.AsNoTracking().Where(s => !s.IsDeleted)
            .OrderByDescending(s => s.StartTime).ProjectToType<ChargingSessionViewListDto>().ToListAsync();
        return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, rows);
    }

    public async Task<IServiceResult> GetById(Guid id, Guid? accountId = null)
    {
        var session = await db.ChargingSessions.AsNoTracking().FirstOrDefaultAsync(s =>
            !s.IsDeleted && s.Id == id && (accountId == null || s.UserId == null || s.UserId == accountId));
        return await LiveSnapshot(session);
    }

    public async Task<IServiceResult> GetByConnector(Guid connectorId, Guid? accountId = null)
    {
        var session = await db.ChargingSessions.AsNoTracking().Where(s => !s.IsDeleted &&
            s.ConnectorId == connectorId &&
            (accountId == null || s.UserId == null || s.UserId == accountId))
            .OrderByDescending(s => s.CreatedAt).FirstOrDefaultAsync();
        return Snapshot(session);
    }

    public async Task<IServiceResult> GetCurrent(Guid accountId)
    {
        var session = await db.ChargingSessions.AsNoTracking().Where(s => !s.IsDeleted &&
            s.UserId == accountId && (s.Status == "Charging" || s.Status == "Completed"))
            .OrderByDescending(s => s.CreatedAt).FirstOrDefaultAsync();
        return await LiveSnapshot(session);
    }

    public Task<IServiceResult> Start(ChargingSessionStartDto dto, Guid? accountId = null) =>
        DatabaseWork.Write(db, async () =>
        {
            if (dto.InitialBatteryLevelPercent < 0 || dto.ExpectedEnergiesKWh > 100 ||
                dto.InitialBatteryLevelPercent >= dto.ExpectedEnergiesKWh)
                return Fail("Thông số pin không hợp lệ.");

            var connector = await db.Set<Connector>().Include(c => c.ChargingPost)
                .ThenInclude(p => p.ChargingStationNavigation)
                .FirstOrDefaultAsync(c => c.Id == dto.ConnectorId && !c.IsDeleted);
            if (connector == null || connector.ChargingPost.IsDeleted ||
                connector.ChargingPost.ChargingStationNavigation.IsDeleted)
                return Missing("Không tìm thấy cổng, trụ hoặc trạm sạc.");

            if (connector.ChargingPost.Status != "Available" && connector.ChargingPost.Status != "Busy")
                return Fail("Trụ sạc không hoạt động.");

            if (connector.ChargingPost.ChargingStationNavigation.Status != "Active" &&
                connector.ChargingPost.ChargingStationNavigation.Status != "Busy")
                return Fail("Trạm sạc không hoạt động.");

            // Kiểm tra xem cổng này có phiên sạc nào đang chạy dở chưa
            if (await db.ChargingSessions.AnyAsync(s => !s.IsDeleted && s.ConnectorId == connector.Id &&
                (s.Status == "Charging" || s.Status == "Completed")))
                return Fail("Cổng đang có phiên sạc hoặc còn hóa đơn chưa thanh toán.");

            var now = DateTime.Now;
            bool hasBooking = dto.BookingId != null && dto.BookingId != Guid.Empty;

            if (hasBooking)
            {
                // Luồng có booking
                var booking = await db.Bookings.FirstOrDefaultAsync(b => b.Id == dto.BookingId && !b.IsDeleted);
                if (booking == null || booking.ConnectorId != dto.ConnectorId ||
                    booking.Status != "InProgress" || now < booking.StartTime.AddMinutes(-15) || now > booking.EndTime)
                    return Fail("Lịch đặt chưa check-in, hết hiệu lực hoặc không khớp xe/cổng của bạn.");

                if (accountId != null && booking.BookedBy != accountId)
                    return Fail("Lịch đặt không thuộc tài khoản của bạn.");

                if (dto.VehicleModelId != null && booking.VehicleModelId != dto.VehicleModelId)
                    return Fail("Xe không khớp với lịch đặt.");
            }
            else
            {
                // Luồng vãng lai / không booking: kiểm tra slot có bị người khác đặt trước trong khoảng thời gian này không
                var hasConflictingBooking = await db.Bookings.AnyAsync(b => !b.IsDeleted &&
                    b.ConnectorId == dto.ConnectorId &&
                    (b.Status == "Reserved" || b.Status == "Scheduled" || b.Status == "InProgress") &&
                    b.StartTime <= now.AddMinutes(30) && b.EndTime >= now);

                if (hasConflictingBooking)
                    return Fail("Cổng này đang có lịch đặt trước của khách hàng khác. Vui lòng chọn cổng trống khác.");
            }

            // Xử lý thông tin người dùng / tài xế
            EVDriverProfile? driver = null;
            if (accountId != null && accountId != Guid.Empty)
            {
                driver = await db.EVDrivers.FirstOrDefaultAsync(d => d.AccountId == accountId && !d.IsDeleted);
                if (await db.ChargingSessions.AnyAsync(s => !s.IsDeleted && s.UserId == accountId &&
                    (s.Status == "Charging" || s.Status == "Completed")))
                    return Fail("Bạn còn phiên đang sạc hoặc chưa thanh toán. Hãy mở lại phiên hiện tại.");
            }
            else if (!string.IsNullOrWhiteSpace(dto.Phone))
            {
                var userByPhone = await db.Users.Include(u => u.EVDriverProfile)
                    .FirstOrDefaultAsync(u => !u.IsDeleted && u.PhoneNumber == dto.Phone.Trim());
                if (userByPhone != null)
                {
                    accountId = userByPhone.Id;
                    driver = userByPhone.EVDriverProfile;
                }
            }

            // Kiểm tra mẫu xe nếu có truyền
            if (dto.VehicleModelId != null && dto.VehicleModelId != Guid.Empty)
            {
                var vehicle = await db.VehicleModels.AsNoTracking().FirstOrDefaultAsync(v =>
                    v.Id == dto.VehicleModelId && !v.IsDeleted);
                if (vehicle != null && connector.ChargingPost.VehicleTypeSupported != vehicle.VehicleType)
                    return Fail("Loại xe không tương thích với trụ sạc.");
            }

            var session = new ChargingSession
            {
                Id = Guid.NewGuid(),
                ConnectorId = connector.Id,
                ChargingPostId = connector.ChargingPostId,
                UserId = accountId,
                DriverId = driver?.Id,
                VehicleModelId = dto.VehicleModelId,
                BookingId = dto.BookingId,
                BatteryCapacityKWh = dto.BatteryCapacityKWh > 0 ? dto.BatteryCapacityKWh : 80,
                InitialBatteryLevelPercent = dto.InitialBatteryLevelPercent,
                ExpectedEnergiesKWh = dto.ExpectedEnergiesKWh,
                PowerRateKW = connector.ChargingPost.MaxPowerKw,
                StartTime = now,
                CreatedAt = now,
                UpdatedAt = now,
                Status = "Charging"
            };

            connector.Status = "Charging";
            connector.IsPluggedIn = true;
            connector.IsLocked = true;
            connector.UpdatedAt = now;

            db.ChargingSessions.Add(session);
            await db.SaveChangesAsync();
            return Snapshot(session);
        });

    public Task<IServiceResult> Stop(ChargingSessionStopDto dto, Guid sessionId, Guid? accountId = null) =>
        DatabaseWork.Write(db, async () =>
        {
            var session = await db.ChargingSessions.Include(s => s.Connector).FirstOrDefaultAsync(s =>
                s.Id == sessionId && !s.IsDeleted &&
                (accountId == null || s.UserId == null || s.UserId == accountId));
            if (session == null) return Missing("Không tìm thấy phiên sạc của bạn.");
            var energy = dto.EnergyDeliveredKWh;
            if (dto.DemoReading)
            {
                if (!DemoEnabled) return Fail("Số đo mô phỏng chỉ dùng trên backend TeamDemo.");
                if (session.Status == "Completed") return Snapshot(session);
                energy = DemoEnergy(session, DateTime.Now);
            }
            if (energy == null || !double.IsFinite(energy.Value) || energy < 0 ||
                energy > session.BatteryCapacityKWh || energy < session.EnergyDeliveredKWh)
                return Fail("Số đo điện năng không hợp lệ. Cần số đo thực từ cổng sạc.");
            if (session.Status == "Completed" && session.EnergyDeliveredKWh == energy)
                return Snapshot(session);
            if (session.Status != "Charging") return Fail("Phiên không ở trạng thái đang sạc.");
            var price = await CurrentPrice();
            if (price is null or <= 0)
                return Fail("Máy chủ chưa cấu hình đơn giá điện hợp lệ.");
            session.EnergyDeliveredKWh = energy.Value;
            session.Cost = CalculateCost(energy.Value, price.Value);
            session.Status = "Completed";
            session.EndTime = session.UpdatedAt = DateTime.Now;
            session.Connector.Status = "InUse";
            session.Connector.UpdatedAt = DateTime.Now;
            await db.SaveChangesAsync();
            return Snapshot(session);
        });

    private bool DemoEnabled => config["ChargingDemo:Enabled"] == "true" &&
        db.Database.GetDbConnection().Database == "EVCSMS_TeamDemo";

    private static double DemoEnergy(ChargingSession session, DateTime now)
    {
        if (session.StartTime == null || session.BatteryCapacityKWh <= 0)
            return session.EnergyDeliveredKWh;

        var elapsed = now - session.StartTime.Value;
        var estimate = Math.Clamp(elapsed.TotalHours * 12, 0, session.BatteryCapacityKWh);
        return Math.Max(Math.Round(estimate, 2), session.EnergyDeliveredKWh);
    }

    private Task<decimal?> CurrentPrice()
    {
        var now = DateTime.Now;
        return db.SystemConfigurations.AsNoTracking().Where(c =>
            !c.IsDeleted && c.Name == "PRICE_PER_kWH" && c.EffectedDateFrom <= now &&
            (c.EffectedDateTo == null || c.EffectedDateTo >= now))
            .OrderByDescending(c => c.EffectedDateFrom).Select(c => c.MinValue).FirstOrDefaultAsync();
    }

    private static decimal CalculateCost(double energy, decimal price) =>
        decimal.Round((decimal)energy * price, 2, MidpointRounding.AwayFromZero);

    private async Task<IServiceResult> LiveSnapshot(ChargingSession? session)
    {
        if (session?.Status != "Charging" || !DemoEnabled) return Snapshot(session);
        // The callers use AsNoTracking. Only Stop persists the final reading.
        session.EnergyDeliveredKWh = DemoEnergy(session, DateTime.Now);
        var price = await CurrentPrice();
        if (price is > 0)
            session.Cost = CalculateCost(session.EnergyDeliveredKWh, price.Value);
        return Snapshot(session);
    }

    private IServiceResult Snapshot(ChargingSession? session)
    {
        if (session == null) return Missing("Không tìm thấy phiên sạc.");
        var detail = session.Adapt<ChargingSessionViewDetailDto>();
        detail.DemoReadingEnabled = DemoEnabled;
        return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, detail);
    }
    private static IServiceResult Fail(string message) => new ServiceResult(Const.FAIL_UPDATE_CODE, message);
    private static IServiceResult Missing(string message) => new ServiceResult(Const.WARNING_NO_DATA_CODE, message);
}
