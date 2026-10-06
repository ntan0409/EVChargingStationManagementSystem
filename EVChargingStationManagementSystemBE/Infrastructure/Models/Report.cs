using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class Report
    {
        [Key]
        public Guid Id { get; set; }
        [Required, MaxLength(200)]
        public string Title { get; set; }
        [Required]
        public string ReportType { get; set; } // e.g., Bug, Feature Request, Maintenance, Other
        [Required]
        public string Severity { get; set; } // e.g., Low, Medium, High, Critical
        public string Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public string Status { get; set; } = "Open"; // e.g., Open, In Progress, Resolved, Closed
        public DateTime? ResolvedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;

        [ForeignKey("UserAccount")]
        public Guid ReportedById { get; set; } // ID of the user who reported the issue
        public UserAccount ReportedBy { get; set; }

        [ForeignKey("ChargingStation")]
        public Guid? StationId { get; set; } // ID of the related charging station (if applicable)
        public ChargingStation ChargingStation { get; set; }

        [ForeignKey("ChargingPost")]
        public Guid? PostId { get; set; } // ID of the related charging post (if applicable)
        public ChargingPost ChargingPost { get; set; }
    }
}
