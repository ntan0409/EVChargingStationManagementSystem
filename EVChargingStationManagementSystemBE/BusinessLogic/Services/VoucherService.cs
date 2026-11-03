using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.VoucherDto;
using Infrastructure.Data;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services;

public class VoucherService(EVCSMSContext db) : IVoucherService
{
    private static IServiceResult Ok(object? data, string message = "Lấy voucher thành công") => new ServiceResult(Const.SUCCESS_READ_CODE, message, data);
    private static IServiceResult Fail(string message) => new ServiceResult(Const.FAIL_UPDATE_CODE, message);
    private static IServiceResult Missing() => new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy voucher hoặc phiên sạc của bạn.");

    public async Task<IServiceResult> GetAvailableVouchers()
    {
        var now = DateTime.Now;
        return Ok(await db.Vouchers.AsNoTracking().Where(v => v.IsActive && v.ValidFrom <= now && v.ValidTo >= now)
            .OrderByDescending(v => v.ValidFrom).ProjectToType<VoucherDto>().ToListAsync());
    }

    public Task<IServiceResult> RedeemVoucher(Guid accountId, Guid voucherId) => DatabaseWork.Write(db, async () =>
    {
        var now = DateTime.Now;
        var driver = await db.EVDrivers.FirstOrDefaultAsync(d => !d.IsDeleted && d.AccountId == accountId);
        var voucher = await db.Vouchers.FirstOrDefaultAsync(v => v.Id == voucherId && v.IsActive);
        if (driver == null || voucher == null) return Missing();
        if (voucher.ValidFrom > now || voucher.ValidTo < now) return Fail("Voucher chưa có hiệu lực hoặc đã hết hạn.");
        if (!ValidValue(voucher)) return Fail("Giá trị voucher chưa hợp lệ.");
        if (voucher.RequiredPoints < 0 || driver.Point < voucher.RequiredPoints) return Fail("Điểm thưởng không đủ để đổi voucher.");
        if (await db.UserVouchers.AnyAsync(uv => uv.EVDriverId == driver.Id && uv.VoucherId == voucherId &&
            uv.Status != "Expired" && uv.ExpiryDate >= now)) return Fail("Bạn đã đổi voucher này.");
        driver.Point -= voucher.RequiredPoints;
        driver.UpdatedAt = now;
        var owned = new UserVoucher
        {
            Id = Guid.NewGuid(), EVDriverId = driver.Id, VoucherId = voucher.Id, Voucher = voucher,
            AssignedDate = now, RedeemDate = now, ExpiryDate = voucher.ValidTo,
            Status = "Redeemed", CreatedAt = now, UpdatedAt = now
        };
        db.UserVouchers.Add(owned);
        await db.SaveChangesAsync();
        return Ok(OwnedDto(owned), "Đã đổi voucher trên máy chủ.");
    });

    public Task<IServiceResult> UseVoucher(Guid userVoucherId, Guid sessionId, Guid? accountId = null) => DatabaseWork.Write(db, async () =>
    {
        if (accountId == null) return Fail("Cần xác minh tài khoản để áp dụng voucher.");
        var owned = await db.UserVouchers.Include(v => v.Voucher).Include(v => v.EVDriver)
            .FirstOrDefaultAsync(v => v.Id == userVoucherId && v.EVDriver.AccountId == accountId && !v.EVDriver.IsDeleted);
        var session = await db.ChargingSessions.FirstOrDefaultAsync(s => s.Id == sessionId && !s.IsDeleted && s.UserId == accountId);
        if (owned == null || session == null) return Missing();
        if (owned.Status == "Used" && owned.SessionId == sessionId)
            return Ok(OwnedDto(owned), "Voucher đã được áp dụng cho phiên này.");
        var now = DateTime.Now;
        if (owned.Status != "Redeemed" || owned.ExpiryDate < now || !owned.Voucher.IsActive ||
            owned.Voucher.ValidFrom > now || owned.Voucher.ValidTo < now)
            return Fail("Voucher không còn đủ điều kiện sử dụng.");
        if (session.Status != "Completed") return Fail("Chỉ áp dụng voucher sau khi dừng sạc và trước khi thanh toán.");
        if (await db.Set<Payment>().AnyAsync(p => !p.IsDeleted && p.ChargingSessionId == sessionId))
            return Fail("Hóa đơn đã được tạo; không thể thay đổi voucher hoặc số tiền.");
        if (await db.UserVouchers.AnyAsync(v => v.SessionId == sessionId && v.Status == "Used"))
            return Fail("Phiên đã sử dụng voucher; không được giảm giá cộng dồn.");
        if (!ValidValue(owned.Voucher)) return Fail("Giá trị voucher không hợp lệ.");
        var discount = owned.Voucher.VoucherType == "Discount"
            ? session.Cost * owned.Voucher.Value / 100 : owned.Voucher.Value;
        session.Cost = decimal.Round(Math.Max(0, session.Cost - discount), 2, MidpointRounding.AwayFromZero);
        session.UpdatedAt = now;
        owned.SessionId = sessionId;
        owned.StationId = await db.ChargingPosts.Where(p => p.Id == session.ChargingPostId).Select(p => p.StationId).FirstAsync();
        owned.Status = "Used";
        owned.UsedDate = owned.UpdatedAt = now;
        await db.SaveChangesAsync();
        return Ok(OwnedDto(owned), "Máy chủ đã áp dụng voucher và cập nhật chi phí phiên.");
    });

    public async Task<IServiceResult> GetMyVouchers(Guid accountId)
    {
        var owned = await db.UserVouchers.AsNoTracking().Include(v => v.Voucher).Include(v => v.EVDriver)
            .Where(v => v.EVDriver.AccountId == accountId && !v.EVDriver.IsDeleted)
            .OrderByDescending(v => v.AssignedDate).ToListAsync();
        return Ok(owned.Select(OwnedDto).ToList());
    }

    private static bool ValidValue(Voucher voucher) => voucher.Value >= 0 &&
        (voucher.VoucherType == "Amount" || (voucher.VoucherType == "Discount" && voucher.Value <= 100));

    private static UserVoucherDto OwnedDto(UserVoucher v) => new()
    {
        Id = v.Id, EVDriverId = v.EVDriverId, VoucherId = v.VoucherId, StationId = v.StationId, SessionId = v.SessionId,
        AssignedDate = v.AssignedDate, RedeemDate = v.RedeemDate, UsedDate = v.UsedDate,
        ExpiryDate = v.ExpiryDate, Status = v.Status, Note = v.Note,
        VoucherName = v.Voucher.Name, VoucherValue = v.Voucher.Value, VoucherType = v.Voucher.VoucherType
    };

    public Task<IServiceResult> CreateVoucher(VoucherCreateDto dto) => DatabaseWork.Write(db, async () =>
    {
        var voucher = dto.Adapt<Voucher>();
        if (!ValidValue(voucher) || voucher.RequiredPoints < 0 || voucher.ValidFrom > voucher.ValidTo)
            return Fail("Thông số voucher không hợp lệ.");
        voucher.Id = Guid.NewGuid(); voucher.IsActive = true;
        db.Vouchers.Add(voucher); await db.SaveChangesAsync();
        return Ok(voucher.Adapt<VoucherDto>(), "Tạo voucher thành công.");
    });

    public Task<IServiceResult> UpdateVoucher(VoucherUpdateDto dto, Guid id) => DatabaseWork.Write(db, async () =>
    {
        var voucher = await db.Vouchers.FirstOrDefaultAsync(v => v.Id == id);
        if (voucher == null) return Missing();
        if (await db.UserVouchers.AnyAsync(v => v.VoucherId == id && v.Status != "Expired"))
            return Fail("Voucher đã phát hành; không thay đổi điều kiện của voucher đang sử dụng.");
        dto.Adapt(voucher); voucher.Id = id;
        if (!ValidValue(voucher) || voucher.RequiredPoints < 0 || voucher.ValidFrom > voucher.ValidTo)
            return Fail("Thông số voucher không hợp lệ.");
        await db.SaveChangesAsync(); return Ok(voucher.Adapt<VoucherDto>(), "Cập nhật thành công.");
    });

    public Task<IServiceResult> DeleteVoucher(Guid id) => DatabaseWork.Write(db, async () =>
    {
        var voucher = await db.Vouchers.FirstOrDefaultAsync(v => v.Id == id);
        if (voucher == null) return Missing();
        voucher.IsActive = false; await db.SaveChangesAsync(); return Ok(null, "Đã vô hiệu voucher.");
    });

    public async Task<IServiceResult> GetAllVouchersForAdmin() => Ok(await db.Vouchers.AsNoTracking()
        .OrderByDescending(v => v.ValidFrom).ProjectToType<VoucherDto>().ToListAsync());

    public Task<IServiceResult> ExpireVoucher(Guid id) => DatabaseWork.Write(db, async () =>
    {
        var voucher = await db.UserVouchers.FirstOrDefaultAsync(v => v.Id == id);
        if (voucher == null) return Missing();
        if (voucher.ExpiryDate < DateTime.Now && voucher.Status != "Used")
        { voucher.Status = "Expired"; voucher.UpdatedAt = DateTime.Now; await db.SaveChangesAsync(); }
        return Ok(null, "Đã kiểm tra hạn sử dụng.");
    });

    public async Task<int> ExpireAllExpiredVouchers()
    {
        var expired = await db.UserVouchers.Where(v => v.Status != "Used" && v.Status != "Expired" && v.ExpiryDate < DateTime.Now).ToListAsync();
        foreach (var voucher in expired) { voucher.Status = "Expired"; voucher.UpdatedAt = DateTime.Now; }
        await db.SaveChangesAsync(); return expired.Count;
    }
}
