using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.PaymentDto;

public sealed class ConfirmCashPaymentDto
{
    [Required]
    public decimal? ReceivedAmount { get; init; }
}
