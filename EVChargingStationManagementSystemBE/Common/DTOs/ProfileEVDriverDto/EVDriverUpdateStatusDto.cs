using System;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ProfileEVDriverDto
{
    public class EVDriverUpdateStatusDto
    {
        [Required(ErrorMessage = "Trạng thái là bắt buộc")]
        [RegularExpression("Active|Inactive", ErrorMessage = "Chỉ được phép là Active hoặc Inactive")]
        public string Status { get; set; } = "Active";
    }
}
