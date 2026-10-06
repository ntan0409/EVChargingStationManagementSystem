using System;

namespace Common.DTOs.ReportDto
{
    public class ViewReportDTO
    {
        public Guid Id { get; set; }
        public string Title { get; set; }
        public string ReportType { get; set; } // e.g., Bug, Feature Request, Maintenance, Other
        public string Severity { get; set; } // e.g., Low, Medium, High, Critical
        public string? Description { get; set; }
        public string Status { get; set; } // e.g., Open, In Progress, Resolved, Closed

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public DateTime? ResolvedAt { get; set; }

        public bool IsDeleted { get; set; }

        // Reporter info
        public Guid ReportedById { get; set; }
        public string? ReportedByName { get; set; }
        public string? RoleName { get; set; }
        // Related station/post
        public Guid? StationId { get; set; }
        public string? StationName { get; set; }

        public Guid? PostId { get; set; }
        public string? PostName { get; set; }
    }
}