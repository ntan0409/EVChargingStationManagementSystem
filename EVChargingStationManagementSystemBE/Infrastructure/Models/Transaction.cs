using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class Transaction
    {
        [Key]
        public Guid Id { get; set; }
        public string ReferenceCode { get; set; }

        [Precision(18, 2)]
        public decimal Amount { get; set; }
        public string TransactionType { get; set; } // e.g., Deposit, Withdrawal, Payment
        public string Status { get; set; } = "Pending"; // e.g., Pending, Completed, Failed
        public string Note { get; set; }
        public DateTime InitiatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;

        [ForeignKey("UserAccount")]
        public Guid? PaidBy { get; set; }
        [InverseProperty("TransactionsPaid")]
        public UserAccount PaidByNavigation { get; set; }

        //[ForeignKey("ChargingSession")]
        //public Guid? ChargingSessionId { get; set; } // Nullable if not linked to a charging session
        //public ChargingSession ChargingSessionNavigation { get; set; }

        [ForeignKey("UserAccount")]
        [InverseProperty("TransactionsRecorded")]
        public Guid? RecordedBy { get; set; } // Ghi nhận từ nhân viên
        public UserAccount RecordedByNavigation { get; set; }

        [ForeignKey("Payment")]
        public Guid? PaymentId { get; set; }
        public Payment Payment { get; set; }

    }
}
