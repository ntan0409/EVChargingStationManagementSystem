using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class Feedback
    {
        [Key]
        public Guid Id { get; set; }
        public Guid AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public UserAccount UserAccount { get; set; }

        [StringLength(200)]
        public string Subject { get; set; }  // Chủ đề góp ý

        public double Stars { get; set; } 

        [StringLength(1000)]
        public string Message { get; set; }  // Nội dung góp ý

        public DateTime CreatedAt { get; set; }

        public bool IsResolved { get; set; } = false;
    }
}
