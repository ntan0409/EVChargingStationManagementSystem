using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class EVDriverConfig : IEntityTypeConfiguration<EVDriverProfile>
    {
        public void Configure(EntityTypeBuilder<EVDriverProfile> builder)
        {
            builder.ToTable("EVDriverProfile");
            builder.HasOne(ev => ev.UserAccount)
                   .WithOne(ua => ua.EVDriverProfile)
                   .HasForeignKey<EVDriverProfile>(ev => ev.AccountId);
        }
    }
}
