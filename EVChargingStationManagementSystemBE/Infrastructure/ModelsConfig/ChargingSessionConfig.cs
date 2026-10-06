using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class ChargingSessionConfig : IEntityTypeConfiguration<ChargingSession>
    {
        public void Configure(EntityTypeBuilder<ChargingSession> builder)
        {
            builder.ToTable("ChargingSession");

            builder.HasOne(cs => cs.ChargingPost)
                   .WithMany(cp => cp.ChargingSessions)
                   .HasForeignKey(cs => cs.ChargingPostId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(cs => cs.UserVehicle)
                    .WithMany(uv => uv.ChargingSessions)
                    .HasForeignKey(cs => new { cs.DriverId, cs.VehicleModelId })
                    .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(cs => cs.User)
                    .WithMany(ev => ev.ChargingSessions)
                    .HasForeignKey(cs => cs.UserId);
        }
    }
}
