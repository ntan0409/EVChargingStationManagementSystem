using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class SystemConfigurationConfig : IEntityTypeConfiguration<SystemConfiguration>
    {
        public void Configure(EntityTypeBuilder<SystemConfiguration> builder)
        {
            builder.ToTable("SystemConfiguration");

            builder.HasOne(sc => sc.SystemConfigurationCreatedByNavigation)
                   .WithMany(ua => ua.SystemConfigurationsCreator)
                   .HasForeignKey(sc => sc.CreatedBy)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(sc => sc.SystemConfigurationUpdatedByNavigation)
                     .WithMany(ua => ua.SystemConfigurationsUpdater)
                     .HasForeignKey(sc => sc.UpdatedBy)
                     .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
