using Common.Enum.Transaction;
using System.Text.Json.Serialization;

namespace Common.DTOs.TransactionDto
{
    public class TransactionViewListDto
    {
        public Guid Id { get; set; }
        public string ReferenceCode { get; set; } = string.Empty;
        public decimal Amount { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public TransactionTypeEnum TransactionType { get; set; } = TransactionTypeEnum.Unknown;

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public TransactionStatus Status { get; set; } = TransactionStatus.Unknown;
    }
}
