using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class NotificationRecipientConfig : IEntityTypeConfiguration<NotificationRecipient>
    {
        public void Configure(EntityTypeBuilder<NotificationRecipient> builder)
        {
            builder.ToTable("NotificationRecipient");

            builder.HasOne(nr => nr.Notification)
                   .WithMany(n => n.NotificationRecipients)
                   .HasForeignKey(nr => nr.NotificationId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(nr => nr.Recipient)
                     .WithMany(ua => ua.NotificationRecipients)
                     .HasForeignKey(nr => nr.RecipientId)
                     .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
