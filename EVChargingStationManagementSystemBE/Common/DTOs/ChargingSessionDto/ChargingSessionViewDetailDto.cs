using Common.Enum.ChargingSession;
using Common.Enum.VehicleModel;
using System.Text.Json.Serialization;

namespace Common.DTOs.ChargingSessionDto
{
    public class ChargingSessionViewDetailDto
    {
        public Guid Id { get; set; }
        public Guid ChargingPostId { get; set; }
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public ChargingSessionStatus Status { get; set; } = ChargingSessionStatus.Unknown;

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public VehicleTypeEnum VehicleType { get; set; } = VehicleTypeEnum.Unknown;
        public string? Phone { get; set; }
        public int BatteryCapacityKWh { get; set; }
        public int InitialBatteryLevelPercent { get; set; }
        public int ExpectedEnergiesKWh { get; set; }
        public int PowerRateKW { get; set; }
        public decimal? TotalEnergyConsumedKWh { get; set; }
        public decimal? Cost { get; set; }
    }
}
