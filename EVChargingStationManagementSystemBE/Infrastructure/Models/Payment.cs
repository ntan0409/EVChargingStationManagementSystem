using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class Payment
    {
        [Key]
        public Guid Id { get; set; }
        [Precision(18, 2)]
        public decimal Amount { get; set; }

        [Precision(18, 2)]
        public decimal TaxRate { get; set; }

        [Precision(18, 2)]
        public decimal BeforeVatAmount { get; set; }
        public string? PaymentMethod { get; set; } // e.g., Credit Card, PayPal, etc.
        public string Status { get; set; } = "Initiated"; // initiated, success, failed, refunded…
        public string? BankCode { get; set; } // e.g., "VCB", "TCB"
        public string TxnRef { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;

        [ForeignKey("ChargingSession")]
        public Guid ChargingSessionId { get; set; }
        public ChargingSession ChargingSessionNavigation { get; set; }

        [ForeignKey("UserAccount")]
        public Guid? PaidBy { get; set; }
        public UserAccount PaidByNavigation { get; set; }

        //[ForeignKey("Transaction")]
        //public Guid TransactionId { get; set; }
        //public Transaction TransactionNavigation { get; set; }
    }
}
