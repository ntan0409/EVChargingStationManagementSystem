using Common.Enum.ChargingStation;
using System.Text.Json.Serialization;

namespace Common.DTOs.ChargingStationDto
{
    public class ChargingStationViewGeneralDto
    {
        public Guid Id { get; set; }
        public string StationName { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string Province { get; set; } = string.Empty;
        public string Latitude { get; set; } = string.Empty;
        public string Longitude { get; set; } = string.Empty;

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public ChargingStationStatus Status { get; set; } = ChargingStationStatus.Unknown;
        public Guid OperatorId { get; set; }

        public string? OperatorName { get; set; } = string.Empty;
        public string? OperatorPhone { get; set; } = string.Empty;
    }
}
