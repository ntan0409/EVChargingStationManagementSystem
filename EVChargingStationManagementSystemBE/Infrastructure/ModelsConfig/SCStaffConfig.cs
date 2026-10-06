using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class SCStaffConfig : IEntityTypeConfiguration<SCStaffProfile>
    {
        public void Configure(EntityTypeBuilder<SCStaffProfile> builder)
        {
            builder.ToTable("SCStaffProfile");
            builder.HasOne(sc => sc.UserAccountNavigation)
                   .WithOne(ua => ua.SCStaffProfile)
                   .HasForeignKey<SCStaffProfile>(sc => sc.AccountId);
        }
    }
}
