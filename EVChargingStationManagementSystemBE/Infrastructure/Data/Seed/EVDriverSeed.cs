using Infrastructure.Models;

namespace Infrastructure.Data.Seed
{
    public static class EVDriverSeed
    {
        public static List<EVDriverProfile> GetEVDrivers() =>
        [
            new EVDriverProfile
            {
                Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                AccountId = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                Point = 100,
                Status = "Active",
                IsDeleted = false,
                CreatedAt = new DateTime(2025,1,1),
                UpdatedAt = new DateTime(2025,1,1)                
            }
        ];
    }
}

