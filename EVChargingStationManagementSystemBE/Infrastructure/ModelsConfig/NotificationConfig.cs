using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class NotificationConfig : IEntityTypeConfiguration<Notification>
    {
        public void Configure(EntityTypeBuilder<Notification> builder)
        {
            builder.ToTable("Notification");
            builder.Property(n => n.CreatedAt)
                   .IsRequired()
                   .HasDefaultValueSql("GETUTCDATE()");
            builder.Property(n => n.IsDeleted)
                   .IsRequired()
                   .HasDefaultValue(false);
            builder.HasOne(n => n.CreatedByNavigation)
                   .WithMany( n => n.Notifications)
                   .HasForeignKey(n => n.CreatedBy);
        }
    }
}
