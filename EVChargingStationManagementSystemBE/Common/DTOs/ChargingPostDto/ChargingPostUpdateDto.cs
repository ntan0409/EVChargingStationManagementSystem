using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ChargingPostDto
{
    public class ChargingPostUpdateDto
    {
        public string? PostName { get; set; }
        public string? ConnectorType { get; set; }
        public int? MaxPowerKw { get; set; }
        public Guid? StationId { get; set; }
    }
}
