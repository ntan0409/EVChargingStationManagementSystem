using Infrastructure.Models;

namespace Infrastructure.Data.Seed
{
    public static class BookingSeed
    {
        public static Booking[] GetBookings() =>
[
    new Booking
    {
        Id = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
        StationId = Guid.Parse("55555555-5555-5555-5555-555555555555"),
        ConnectorId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc"),
        BookedBy = Guid.Parse("11111111-1111-1111-1111-111111111111"),
        CheckInCode = "1234",
        StartTime = new DateTime(2025, 10, 26, 9, 0, 0),
        EndTime = new DateTime(2025, 10, 26, 11, 0, 0),
        Status = "Scheduled",
        CreatedAt = new DateTime(2025, 10, 25, 12, 0, 0),
        UpdatedAt = new DateTime(2025, 10, 25, 12, 0, 0)
    }
];
    }
}