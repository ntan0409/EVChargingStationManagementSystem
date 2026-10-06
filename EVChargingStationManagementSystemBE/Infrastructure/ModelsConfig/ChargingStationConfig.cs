using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class ChargingStationConfig : IEntityTypeConfiguration<ChargingStation>
    {
        public void Configure(EntityTypeBuilder<ChargingStation> builder)
        {
            builder.ToTable("ChargingStation");

            builder.HasOne(cs => cs.OperatorNavigation)
                   .WithMany(ua => ua.ChargingStations)
                   .HasForeignKey(cs => cs.OperatorId)
                   .OnDelete(DeleteBehavior.Restrict);
            builder.HasIndex(builder => builder.OperatorId).IsUnique(true);
        }
    }
}
