using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class ChargingSession
    {
        [Key]
        public Guid Id { get; set; }
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; } // Nullable for ongoing sessions
        public double EnergyDeliveredKWh { get; set; } // Total energy delivered in kWh
        [Precision(18, 2)]
        public decimal Cost { get; set; } = 0; // Total cost of the session
        public string Status { get; set; } = "Charging"; // e.g., InProgress, Completed, Cancelled
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;
        public int BatteryCapacityKWh { get; set; } // Battery capacity of the vehicle in kWh
        public int InitialBatteryLevelPercent { get; set; } // Initial battery level in percentage
        public int ExpectedEnergiesKWh { get; set; } // Expected energy to be charged in kWh
        public int PowerRateKW { get; set; } // Charging power rate in kW

        [ForeignKey("Connector")]
        public Guid ConnectorId { get; set; }
        public Connector Connector { get; set; }

        [ForeignKey("ChargingPost")]
        public Guid ChargingPostId { get; set; }
        public ChargingPost ChargingPost { get; set; }

        public Guid? DriverId { get; set; }

        public Guid? VehicleModelId { get; set; }
        //[ForeignKey("UserVehicle")]
        public UserVehicle UserVehicle { get; set; }

        [ForeignKey("UserAccount")]
        public Guid? UserId { get; set; }
        public UserAccount User { get; set; }

        [ForeignKey("Booking")]
        public Guid? BookingId { get; set; } // Nullable if not booked
        public Booking Booking { get; set; }

        //public ICollection<Transaction> Transactions { get; set; } = [];
    }
}
