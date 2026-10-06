using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class VehicleModel
    {
        [Key]
        public Guid Id { get; set; }

        [Required, MaxLength(100)]
        public string ModelName { get; set; }
        public string Brand { get; set; }
        public int ModelYear { get; set; }
        public string VehicleType { get; set; } // e.g., Sedan, SUV, Truck
        public int BatteryCapacityKWh { get; set; } // Battery capacity in kWh
        public int RecommendedChargingPowerKW { get; set; } // Recommended charging power in kW
        public string ImageUrl { get; set; }
        public string Status { get; set; } = "Active";
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;

        [ForeignKey("UserAccount")]
        public Guid CreatedBy { get; set; }
        public UserAccount UserAccountNavigation { get; set; }

        public ICollection<UserVehicle> UserVehicles { get; set; } = [];
    }
}
