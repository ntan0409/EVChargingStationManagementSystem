using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Common.DTOs.ReportDto
{
    public class ReportCreateByUserDto
    {
        [Required, MaxLength(200)]
        public string Title { get; set; }

        [Required]
        public string ReportType { get; set; }

        [Required]
        public string Severity { get; set; }

        public string? Description { get; set; }
    }
}
