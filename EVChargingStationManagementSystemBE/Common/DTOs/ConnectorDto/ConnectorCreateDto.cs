using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ConnectorDto
{
    public class ConnectorCreateDto
    {
        public string ConnectorName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Trụ không được phép bỏ trống")]
        public Guid ChargingPostId { get; set; }
    }
}
