using System;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ProfileStaffDto
{
    public class StaffUpdateDto
    {
        [Required(ErrorMessage = "StaffId là bắt buộc")]
        public Guid StaffId { get; set; }

        [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
        [MaxLength(15)]
        public string? PhoneNumber { get; set; }

        [StringLength(255, ErrorMessage = "Địa chỉ không vượt quá 255 ký tự.")]
        public string? Address { get; set; }

        [MaxLength(255, ErrorMessage = "URL ảnh đại diện không vượt quá 255 ký tự.")]
        public string? ProfilePictureUrl { get; set; }
    }
}
