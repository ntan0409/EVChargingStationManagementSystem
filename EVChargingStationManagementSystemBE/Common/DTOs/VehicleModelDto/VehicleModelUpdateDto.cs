using Common.Enum.VehicleModel;

namespace Common.DTOs.VehicleModelDto
{
    public class VehicleModelUpdateDto
    {
        public string? ModelName { get; set; }
        //public string? Brand { get; set; }
        public int ModelYear { get; set; }
        public VehicleTypeEnum VehicleType { get; set; }
        public int BatteryCapacityKWh { get; set; }
        public int RecommendedChargingPowerKW { get; set; }
        public string? ImageUrl { get; set; }
    }
}
