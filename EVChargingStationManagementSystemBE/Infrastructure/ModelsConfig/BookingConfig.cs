using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.ModelsConfig
{
    public class BookingConfig : IEntityTypeConfiguration<Booking>
    {
        public void Configure(EntityTypeBuilder<Booking> builder)
        {
            builder.ToTable("Booking");

            builder.HasOne(b => b.ChargingStationNavigation)
                   .WithMany(cs => cs.Bookings)
                   .HasForeignKey(b => b.StationId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(b => b.BookedByNavigation)
                     .WithMany(ua => ua.Bookings)
                     .HasForeignKey(b => b.BookedBy)
                     .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
