using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.AuthDto
{
    public class ChangePasswordDto
    {
        [Required(ErrorMessage = "Cần nhập mật khẩu cũ")]
        public string OldPassword { get; set; } = string.Empty;

        [Required(ErrorMessage = "Cần nhập mật khẩu mới")]
        public string NewPassword { get; set; } = string.Empty;

        [Required(ErrorMessage = "Cần nhập lại mật khẩu mới")]
        [Compare("NewPassword", ErrorMessage = "Mật khẩu mới và mật khẩu mới nhập lại không giống nhau")]
        public string ConfirmPassword { get; set; } = string.Empty;
    }

}
