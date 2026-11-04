using Common.Enum.ChargingSession;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ChargingSessionDto
{
    public class ChargingSessionStopDto : IValidatableObject
    {
        public bool DemoReading { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (DemoReading == EnergyDeliveredKWh.HasValue)
                yield return new ValidationResult("Cần số đo thực hoặc yêu cầu số đo demo.", [nameof(EnergyDeliveredKWh)]);
        }

        [Range(0, double.MaxValue)]
        public double? EnergyDeliveredKWh { get; set; }
    }
}
