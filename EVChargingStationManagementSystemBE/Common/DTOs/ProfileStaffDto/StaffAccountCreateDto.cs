using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Common.DTOs.ProfileStaffDto
{
    public class StaffAccountCreateDto
    {
        [Required(ErrorMessage = "Email không được để trống")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        public string Email { get; set; }

        [Required(ErrorMessage = "Mật khẩu không được để trống")]
        [MinLength(8, ErrorMessage = "Mật khẩu phải có ít nhất 8 ký tự")]
        [RegularExpression(@"^(?=.*[A-Z])(?=.*[a-z])(?=.*\W).{8,}$",
       ErrorMessage = "Mật khẩu phải có ít nhất 1 chữ hoa, 1 chữ thường, 1 ký tự đặc biệt và tối thiểu 8 ký tự")]
        public string Password { get; set; }


        [Required(ErrorMessage = "Xác nhận mật khẩu không được để trống")]
        [Compare("Password", ErrorMessage = "Mật khẩu xác nhận không khớp")]
        public string ConfirmPassword { get; set; }

    
        [Required(ErrorMessage = "Họ và tên không được để trống")]
        [MaxLength(100)]
        public string Name { get; set; }

        [RegularExpression(@"^(?:\+84|0)(?:3[2-9]|5[2689]|7[0|6-9]|8[1-9]|9[0-9])[0-9]{7}$",
         ErrorMessage = "Số điện thoại không hợp lệ")]
        public string PhoneNumber { get; set; }  

        [MaxLength(255)]
        public string Address { get; set; } 

        [MaxLength(255)]
        public string ProfilePictureUrl { get; set; }  

        [MaxLength(255)]
        public string WorkingLocation { get; set; }
        [JsonIgnore]
        public string? Status { get; set; } = "Active";  
    }
}
