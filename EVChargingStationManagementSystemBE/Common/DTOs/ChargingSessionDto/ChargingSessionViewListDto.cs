using Common.Enum.ChargingSession;
using Common.Enum.VehicleModel;
using System.Text.Json.Serialization;

namespace Common.DTOs.ChargingSessionDto
{
    public class ChargingSessionViewListDto
    {
        public Guid Id { get; set; }
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public ChargingSessionStatus Status { get; set; } = ChargingSessionStatus.Unknown;
        public string EnergyDeliveredKWh { get; set; } = string.Empty;
        public decimal? Cost { get; set; }
    }
}
