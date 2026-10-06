using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Infrastructure.Models;

namespace Infrastructure.Data.Seed
{
    public static class RoleSeed
    {
        public static List<Role> GetRoles()
        {
            return [
                new Role
                {
                    Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    Name = "Admin",
                    Description = "Administrator with full permissions",
                    Status = "Active",
                    NormalizedName = "ADMIN",
                    CreatedAt = new DateTime(2025, 01, 01),
                    UpdatedAt = new DateTime(2025, 01, 01),
                    ConcurrencyStamp = "9fd925f3-34b4-46ce-971e-e3bcf4884150"
                },
                new Role
                {
                    Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    Name = "Staff",
                    Description = "Charging Station Staff who manage the charging station",
                    Status = "Active",
                    NormalizedName = "STAFF",
                    CreatedAt = new DateTime(2025, 01, 01),
                    UpdatedAt = new DateTime(2025, 01, 01),
                    ConcurrencyStamp = "8bd37ac3-05da-4f2a-8ad7-74a4ccfe204c"
                },
                new Role
                {
                    Id = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                    Name = "EVDriver",
                    Description = "EV Driver",
                    Status = "Active",
                    NormalizedName = "EVDRIVER",
                    CreatedAt = new DateTime(2025, 01, 01),
                    UpdatedAt = new DateTime(2025, 01, 01),
                    ConcurrencyStamp = "509373db-719c-4e21-bb25-4f9b4b9af087"
                }
            ];
        }
    }
}
