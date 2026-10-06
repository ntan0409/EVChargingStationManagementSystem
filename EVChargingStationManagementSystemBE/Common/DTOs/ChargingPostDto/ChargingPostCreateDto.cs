using Common.Enum.VehicleModel;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ChargingPostDto
{
    public class ChargingPostCreateDto
    {
        [Required(ErrorMessage = "Tên trụ sạc không được để trống")]
        public string PostName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Loại cổng sạc không được để trống")]
        public string ConnectorType { get; set; } = string.Empty;

        [Required(ErrorMessage = "Công suất sạc tối đa không được để trống")]
        public int MaxPowerKw { get; set; }

        [Required(ErrorMessage = "Loại xe hỗ trợ không được để trống")]
        public VehicleTypeEnum VehicleTypeSupported { get; set; } = VehicleTypeEnum.Unknown;

        [Required(ErrorMessage = "Số lượng cổng sạc không được để trống")]
        [Range(1, int.MaxValue, ErrorMessage = "Số lượng cổng sạc phải có ít nhất 1")]
        public int TotalConnectors { get; set; }

        [Required(ErrorMessage = "Thuộc trạm nào không được để trống")]
        public Guid StationId { get; set; }
    }
}
