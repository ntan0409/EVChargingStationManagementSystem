using System;

namespace Common.DTOs.ProfileStaffDto
{
    public class StaffViewDto
    {
        //  Thông tin Staff
        public Guid Id { get; set; }
        public Guid AccountId { get; set; }

        //  Thông tin cá nhân (lấy từ UserAccount)
        public string? Name { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public string? ProfilePictureUrl { get; set; }

        //  Thông tin làm việc
        public string? WorkingLocation { get; set; }

        //  Trạng thái
        public string Status { get; set; } = "Active";

        //  Thông tin hệ thống
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
