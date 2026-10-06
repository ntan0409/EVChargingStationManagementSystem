using System;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ProfileStaffDto
{
    public class StaffUpdateStatusDto
    {
        [Required(ErrorMessage = "StaffId là bắt buộc")]
        public Guid StaffId { get; set; }

        [Required(ErrorMessage = "Trạng thái không được để trống")]
        [MaxLength(20, ErrorMessage = "Trạng thái không vượt quá 20 ký tự.")]
        [RegularExpression("Active|Inactive", ErrorMessage = "Trạng thái chỉ được là Active hoặc Inactive.")]
        public string Status { get; set; } = "Active";
    }
}
