using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class ChargingPost
    {
        [Key]
        public Guid Id { get; set; }
        [MaxLength(100)]
        public string PostName { get; set; }
        public string ConnectorType { get; set; } // e.g., Type2, CCS, CHAdeMO
        public string VehicleTypeSupported { get; set; } // e.g., Car, Bike
        public int MaxPowerKw { get; set; } // Maximum power output in kW
        public int TotalConnectors { get; set; } = 0;// Number of connectors available
        public int AvailableConnectors { get; set; } = 0;// Number of connectors currently available
        public string Status { get; set; } = "Available"; // e.g., Available, In Use, Out of Service
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;

        [ForeignKey("ChargingStation")]
        public Guid StationId { get; set; }
        public ChargingStation ChargingStationNavigation { get; set; }

        public ICollection<ChargingSession> ChargingSessions { get; set; } = [];
        public ICollection<Connector> Connectors { get; set; } = [];
        public ICollection<Report> Reports { get; set; } = [];
        //public ICollection<PowerOutputKWPerPost> PowerOutputKWPerPosts { get; set; } = [];
    }
}
