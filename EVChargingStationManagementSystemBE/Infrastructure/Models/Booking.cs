using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class Booking
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public DateTime StartTime { get; set; }

        [Required]
        public DateTime EndTime { get; set; }

        [MaxLength(30)]
        public string Status { get; set; } = "Scheduled";
        // e.g., Scheduled, CheckedIn, Charging, Completed, Cancelled

        public string CheckInCode { get; set; } // Mã để EV driver nhập tại trạm

        public double? CurrentBattery { get; set; }
        public double? TargetBattery { get; set; }
        public double? EstimatedEnergyKWh { get; set; }
        public double? ActualEnergyKWh { get; set; }
        public DateTime? ActualStartTime { get; set; }
        public DateTime? ActualEndTime { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public bool IsDeleted { get; set; } = false;

        //  Gắn với Connector (đầu sạc cụ thể)
        [ForeignKey("Connector")]
        public Guid? ConnectorId { get; set; }
        public Connector ConnectorNavigation { get; set; }

        //  Trạm sạc chứa connector
        [ForeignKey("ChargingStation")]
        public Guid StationId { get; set; }
        public ChargingStation ChargingStationNavigation { get; set; }

        //  Người đặt
        [ForeignKey("UserAccount")]
        public Guid BookedBy { get; set; }
        public UserAccount BookedByNavigation { get; set; }
    }
}
