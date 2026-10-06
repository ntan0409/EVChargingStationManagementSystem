using Common.Enum.VehicleModel;
using System.Text.Json.Serialization;

namespace Common.DTOs.VehicleModelDto
{
    public class VehicleModelViewDetailDto
    {
        public Guid Id { get; set; }
        public string ModelName { get; set; } = string.Empty;
        //public string Brand { get; set; } = string.Empty;
        public int ModelYear { get; set; }
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public VehicleTypeEnum VehicleType { get; set; } = VehicleTypeEnum.Unknown;
        public int BatteryCapacityKWh { get; set; } 
        public int RecommendedChargingPowerKW { get; set; } 
        public string ImageUrl { get; set; } = string.Empty;
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public VehicleModelStatus Status { get; set; } = VehicleModelStatus.Unknown;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
        public Guid CreatedBy { get; set; }
    }
}
