using Common.Enum.ChargingSession;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ChargingSessionDto
{
    public class ChargingSessionStopDto
    {
        [Required(ErrorMessage = "Cần nhập năng lượng đã tiêu thụ")]
        public double EnergyDeliveredKWh { get; set; }
    }
}
