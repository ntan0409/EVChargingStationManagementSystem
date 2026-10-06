using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    internal class UserVehicleConfig : IEntityTypeConfiguration<UserVehicle>
    {
        public void Configure(EntityTypeBuilder<UserVehicle> builder)
        {
            builder.ToTable("UserVehicle");

            builder.HasOne(uv => uv.EVDriver)
                   .WithMany(ev => ev.UserVehicles)
                   .HasForeignKey(uv => uv.DriverId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(uv => uv.VehicleModel)
                     .WithMany(vm => vm.UserVehicles)
                     .HasForeignKey(uv => uv.VehicleModelId)
                     .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
