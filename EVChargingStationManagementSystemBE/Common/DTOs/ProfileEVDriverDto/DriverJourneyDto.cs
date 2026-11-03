using Common.DTOs.BookingDto;

namespace Common.DTOs.ProfileEVDriverDto;

public class DriverJourneyDto
{
    public Guid AccountId { get; set; }
    public bool ProfileCompleted { get; set; }
    public bool CanBook { get; set; }
    public bool CanChangeVehicle { get; set; }
    public List<string> MissingRequirements { get; set; } = [];
    public List<Guid> EligibleVehicleModelIds { get; set; } = [];
    public BookingViewDto? ActiveBooking { get; set; }
    public Guid? CurrentSessionId { get; set; }
    public string? CurrentSessionStatus { get; set; }
}
