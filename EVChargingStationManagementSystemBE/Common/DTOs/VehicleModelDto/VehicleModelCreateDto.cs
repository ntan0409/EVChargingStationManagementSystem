using Common.Enum.VehicleModel;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.VehicleModelDto
{
    public class VehicleModelCreateDto
    {
        [Required, MaxLength(100)]
        public string ModelName { get; set; } = string.Empty;
        //[Required, MaxLength(100)]
        //public string Brand { get; set; } = string.Empty;
        public int ModelYear { get; set; }
        [Required]
        public VehicleTypeEnum VehicleType { get; set; }
        public int BatteryCapacityKWh { get; set; }
        public int RecommendedChargingPowerKW { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
    }
}
