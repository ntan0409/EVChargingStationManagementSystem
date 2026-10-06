using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.ChargingSessionDto
{
    public class ChargingSessionStartDto : IValidatableObject
    {
        public Guid? BookingId { get; set; } // Nullable if not booked

        [Required(ErrorMessage = "Cần nhập dung lượng pin")]
        public int BatteryCapacityKWh { get; set; } // Battery capacity of the vehicle in kWh

        [Required(ErrorMessage = "Cần nhập mức pin đang có hiện tại"), 
            Range(0, 100, ErrorMessage = "Mức pin đang có hiện tại phải từ 0 đến 100")]
        public int InitialBatteryLevelPercent { get; set; } // Initial battery level in percentage

        [Required(ErrorMessage ="Cần nhập mức pin mong muốn sạc tới"),
            Range(0, 100, ErrorMessage = "Mức pin mong muốn sạc tới phải từ 0 đến 100")]
        public int ExpectedEnergiesKWh { get; set; } // Expected energy to be charged in kWh

        [RegularExpression(@"^(?:\+84|0)(?:3[2-9]|5[2689]|7[0|6-9]|8[1-9]|9[0-9])[0-9]{7}$",
        ErrorMessage = "Số điện thoại không hợp lệ")]
        public string Phone { get; set; } = string.Empty;

        [Required(ErrorMessage = "Cần cắm cổng sạc")]
        public Guid ConnectorId { get; set; }
        public Guid? VehicleModelId { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (InitialBatteryLevelPercent == 100)
            {
                yield return new ValidationResult(
                    "Pin xe của bạn đã đầy",
                    [nameof(InitialBatteryLevelPercent)]);
            }
            if (ExpectedEnergiesKWh <= 0)
            {
                yield return new ValidationResult(
                    "Mức sạc dự kiến phải lớn hơn 0",
                    [nameof(ExpectedEnergiesKWh)]);
            }
            if (BatteryCapacityKWh <= 0)
            {
                yield return new ValidationResult(
                    "Dung lượng pin phải lớn hơn 0",
                    [nameof(BatteryCapacityKWh)]);
            }
            if (InitialBatteryLevelPercent >= ExpectedEnergiesKWh)
            {
                yield return new ValidationResult(
                    "Mức pin mong muốn sạc tới phải lớn hơn mức pin đang có",
                    [nameof(ExpectedEnergiesKWh)]);
            }
        }
    }
}
