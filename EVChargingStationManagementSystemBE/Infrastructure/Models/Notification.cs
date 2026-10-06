using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Infrastructure.Models
{
    public class Notification
    {
        [Key]
        public Guid Id { get; set; }

        public string NotificationCode { get; set; }

        public string Title { get; set; }

        public string Message { get; set; }

        public string Type { get; set; }

        public DateTime CreatedAt { get; set; }

        public bool IsDeleted { get; set; }

        [ForeignKey("UserAccount")]
        public Guid? CreatedBy { get; set; }
        public UserAccount CreatedByNavigation { get; set; }

        public ICollection<NotificationRecipient> NotificationRecipients { get; set; } = [];
    }
}
