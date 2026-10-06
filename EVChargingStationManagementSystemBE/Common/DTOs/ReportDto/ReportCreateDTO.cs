using System;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ReportDto
{
    public class ReportCreateDTO
    {
        [Required, MaxLength(200)]
        public string Title { get; set; }

        [Required]
        public string ReportType { get; set; } // e.g., Bug, Feature Request, Maintenance, Other

        [Required]
        public string Severity { get; set; } // e.g., Low, Medium, High, Critical

        public string? Description { get; set; } //  nên cho nullable để tránh lỗi khi không nhập

        //[Required]
        //public Guid ReportedById { get; set; } // ID người báo cáo

        public Guid? StationId { get; set; } // Liên kết với trạm sạc
        public Guid? PostId { get; set; } // Liên kết với cột sạc
    }
}