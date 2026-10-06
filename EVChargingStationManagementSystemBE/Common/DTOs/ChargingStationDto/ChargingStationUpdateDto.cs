namespace Common.DTOs.ChargingStationDto
{
    public class ChargingStationUpdateDto
    {
        public string? StationName { get; set; }
        public string? Location { get; set; }
        public string? Province { get; set; }
        public string? Latitude { get; set; }
        public string? Longitude { get; set; }
        public Guid? OperatorId { get; set; } // Nhân viên quản lý
    }
}
