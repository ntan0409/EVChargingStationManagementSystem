namespace Common.DTOs.PaymentDto;

// Read-only server quote and the latest persisted payment, scoped to its owner.
public class SessionPaymentDto
{
    public Guid SessionId { get; set; }
    public string SessionStatus { get; set; } = "Unknown";
    public decimal BeforeVatAmount { get; set; }
    public decimal TaxRate { get; set; }
    public decimal Amount { get; set; }
    public PaymentViewDetailDto? Payment { get; set; }
}
