using System;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ProfileStaffDto
{
    public class StaffUpdateAdminDto
    {
        // ====== SCStaff ======
        [Required(ErrorMessage = "StaffId là bắt buộc")]
        public Guid StaffId { get; set; }

        [StringLength(255, ErrorMessage = "Nơi làm việc không vượt quá 255 ký tự.")]
        public string? WorkingLocation { get; set; }

        [RegularExpression("Active|Inactive", ErrorMessage = "Trạng thái chỉ được là Active hoặc Inactive.")]
        public string? Status { get; set; }

        // ====== UserAccount ======
        [StringLength(100, ErrorMessage = "Tên không vượt quá 100 ký tự.")]
        public string? Name { get; set; }

        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        public string? Email { get; set; }

        [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
        [MaxLength(15)]
        public string? PhoneNumber { get; set; }

        [StringLength(255, ErrorMessage = "Địa chỉ không vượt quá 255 ký tự.")]
        public string? Address { get; set; }

        [MaxLength(255)]
        public string? ProfilePictureUrl { get; set; }
    }
}
