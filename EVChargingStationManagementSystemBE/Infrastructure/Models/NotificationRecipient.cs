using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class NotificationRecipient
    {
        public Guid Id { get; set; }              

        public bool? IsRead { get; set; }

        public DateTime? ReadAt { get; set; }

        public bool IsDeleted { get; set; }

        [ForeignKey("NotificationId")]
        public Guid NotificationId { get; set; }
        public Notification Notification { get; set; }

        [ForeignKey("UserAccount")]
        public Guid RecipientId { get; set; }
        public UserAccount Recipient { get; set; }
    }
}
