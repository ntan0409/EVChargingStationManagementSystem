using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class VehicleModelConfig : IEntityTypeConfiguration<VehicleModel>
    {
        public void Configure(EntityTypeBuilder<VehicleModel> builder)
        {
            builder.ToTable("VehicleModel");

            builder.HasOne(v => v.UserAccountNavigation)
                   .WithMany(ua => ua.VehicleModels)
                   .HasForeignKey(v => v.CreatedBy);
        }
    }
}
