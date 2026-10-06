using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ChargingStationDto
{
    public class ChargingStationCreateDto
    {
        [Required(ErrorMessage = "Tên trạm không được để trống")]
        [MaxLength(150, ErrorMessage = "Tên trạm không được quá 150 ký tự")]
        public string StationName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Địa chỉ trạm không được để trống")
            , MaxLength(250, ErrorMessage = "Địa chỉ không được phép quá 250 ký tự")]
        public string Location { get; set; } = string.Empty;

        [Required(ErrorMessage = "Khu vực không được phép để trống"), 
            MaxLength(100, ErrorMessage = "Khu vực không được phép quá 100 ký tự")]
        public string Province { get; set; } = string.Empty; // e.g., "Hồ Chí Minh"
        [Required(ErrorMessage = "Kinh độ không được phép để trống"), 
            MaxLength(30, ErrorMessage = "Kinh độ không được phép quá 30 ký tự")]
        public string Latitude { get; set; } = string.Empty;  // "10°50'10.8\"N" Kinh độ

        [Required(ErrorMessage = "Vĩ độ không được phép để trống"), 
            MaxLength(30, ErrorMessage = "Vĩ độ không được phép quá 30 ký tự")]
        public string Longitude { get; set; } = string.Empty; // "106°50'32.1\"E" Vĩ độ
        public Guid? OperatorId { get; set; } // Nhân viên quản lý
    }
}
