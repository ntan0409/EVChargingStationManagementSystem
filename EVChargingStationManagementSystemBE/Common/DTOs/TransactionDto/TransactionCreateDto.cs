using Common.Enum.Transaction;

namespace Common.DTOs.TransactionDto
{
    public class TransactionCreateDto
    {
        public decimal Amount { get; set; }
        public TransactionTypeEnum TransactionType { get; set; } = TransactionTypeEnum.Unknown;
        public TransactionStatus Status { get; set; } = TransactionStatus.Unknown;
        public string Note { get; set; } = string.Empty;
    }
}
