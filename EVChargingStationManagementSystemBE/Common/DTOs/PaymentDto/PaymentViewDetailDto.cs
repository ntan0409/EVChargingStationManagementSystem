using Common.Enum.Payment;
using System.Text.Json.Serialization;

namespace Common.DTOs.PaymentDto
{
    public class PaymentViewDetailDto
    {
        public Guid Id { get; set; }
        public decimal Amount { get; set; }
        public decimal TaxRate { get; set; }
        public decimal BeforeVatAmount { get; set; }
        public string? PaymentMethod { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public PaymentStatus Status { get; set; } = PaymentStatus.Unknown;

        public string? BankCode { get; set; }
        public string TxnRef { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public Guid ChargingSessionId { get; set; }
    }
}
