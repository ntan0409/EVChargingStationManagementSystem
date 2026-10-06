using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class ChargingPostConfig : IEntityTypeConfiguration<ChargingPost>
    {
        public void Configure(EntityTypeBuilder<ChargingPost> builder)
        {
            builder.ToTable("ChargingPost");
            builder.Property(cp => cp.CreatedAt)
                   .IsRequired()
                   .HasDefaultValueSql("GETUTCDATE()");
            builder.Property(cp => cp.IsDeleted)
                   .IsRequired()
                   .HasDefaultValue(false);
            builder.HasOne(cp => cp.ChargingStationNavigation)
                   .WithMany(cs => cs.ChargingPosts)
                   .HasForeignKey(cp => cp.StationId);
        }
    }
}
