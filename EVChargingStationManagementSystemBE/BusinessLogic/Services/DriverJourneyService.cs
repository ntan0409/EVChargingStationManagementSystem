using Common.DTOs.ProfileEVDriverDto;
using Common.DTOs.BookingDto;
using Infrastructure.Data;
using Infrastructure.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services;

// Server-owned policy ported from original FE Booking.jsx and BE booking rules.
// No persisted/local "completed" boolean; every read is recomputed from current DB state.
public class DriverJourneyService(EVCSMSContext db)
{
    public static readonly string[] ActiveBookingStatuses = ["Scheduled", "Reserved", "CheckedIn", "InProgress", "Waiting"];
    public static bool HasProfileValue(string? value) => !string.IsNullOrWhiteSpace(value) &&
        !value.Contains("Chưa cập nhật", StringComparison.OrdinalIgnoreCase);
    public static bool Supported(VehicleModel vehicle) => !vehicle.IsDeleted && vehicle.Status == "Active" &&
        vehicle.BatteryCapacityKWh > 0 && (vehicle.VehicleType == "Car" || vehicle.VehicleType == "Bike") &&
        vehicle.RecommendedChargingPowerKW >= 0;

    public async Task<DriverJourneyDto?> GetState(Guid accountId)
    {
        var driver = await db.EVDrivers.AsNoTracking().Include(d => d.UserAccount)
            .Include(d => d.UserVehicles).ThenInclude(v => v.VehicleModel)
            .FirstOrDefaultAsync(d => d.AccountId == accountId && !d.IsDeleted);
        if (driver == null || driver.UserAccount == null || driver.UserAccount.IsDeleted) return null;
        var account = driver.UserAccount;
        var missing = new List<string>();
        if (!HasProfileValue(account.Name)) missing.Add("name");
        if (!HasProfileValue(account.PhoneNumber)) missing.Add("phoneNumber");
        if (!account.EmailConfirmed) missing.Add("emailVerification");
        if (account.Status != "Active" || driver.Status != "Active") missing.Add("accountInactive");
        var eligible = driver.UserVehicles.Where(v => Supported(v.VehicleModel)).Select(v => v.VehicleModelId).ToList();
        if (eligible.Count == 0) missing.Add("supportedVehicle");
        var booking = await db.Bookings.AsNoTracking().Where(b => !b.IsDeleted && b.BookedBy == accountId &&
            ActiveBookingStatuses.Contains(b.Status)).OrderByDescending(b => b.CreatedAt)
            .Select(b => new BookingViewDto { Id = b.Id, StationId = b.StationId,
                VehicleModelId = b.VehicleModelId, ConnectorId = b.ConnectorId,
                CheckInCode = b.CheckInCode, Status = b.Status, StartTime = b.StartTime, EndTime = b.EndTime,
                StationName = b.ChargingStationNavigation.StationName, BookedBy = b.BookedBy }).FirstOrDefaultAsync();
        var session = await db.ChargingSessions.AsNoTracking().Where(s => !s.IsDeleted && s.UserId == accountId &&
            (s.Status == "Charging" || s.Status == "Completed")).OrderByDescending(s => s.CreatedAt)
            .Select(s => new { s.Id, s.Status }).FirstOrDefaultAsync();
        return new DriverJourneyDto { AccountId = accountId, MissingRequirements = missing,
            ProfileCompleted = missing.Count == 0, EligibleVehicleModelIds = eligible,
            CanBook = missing.Count == 0 && !driver.IsBookingLocked && booking == null && session == null,
            CanChangeVehicle = booking == null && session == null,
            ActiveBooking = booking, CurrentSessionId = session?.Id, CurrentSessionStatus = session?.Status };
    }
}
