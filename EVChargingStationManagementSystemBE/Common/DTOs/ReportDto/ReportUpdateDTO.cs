using System;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ReportDto
{
    public class ReportUpdateDTO
    {
        [Required]
        public Guid Id { get; set; }

        [MaxLength(200)]
        public string? Title { get; set; }

        public string? ReportType { get; set; } // e.g., Bug, Feature Request, Maintenance, Other
        public string? Severity { get; set; } // e.g., Low, Medium, High, Critical
        public string? Description { get; set; }

        public string? Status { get; set; } // e.g., Open, In Progress, Resolved, Closed
        public DateTime? ResolvedAt { get; set; }

        public Guid? StationId { get; set; }
        public Guid? PostId { get; set; }
    }
}