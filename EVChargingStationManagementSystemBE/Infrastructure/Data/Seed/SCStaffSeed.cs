using Infrastructure.Models;

namespace Infrastructure.Data.Seed
{
    public static class SCStaffSeed
    {
        public static List<SCStaffProfile> GetSCStaffs() =>
        [
            new SCStaffProfile
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                AccountId = Guid.Parse("44444444-4444-4444-4444-444444444444"), // staff@gmail.com
                WorkingLocation = "Hanoi Station",
                Status = "Active",
                CreatedAt = new DateTime(2025,1,1),
                UpdatedAt = new DateTime(2025,1,1),
                IsDeleted = false
            },
            new SCStaffProfile
            {
                Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                AccountId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                WorkingLocation = "Q9 Station",
                Status = "Active",
                CreatedAt = new DateTime(2025,1,1),
                UpdatedAt = new DateTime(2025,1,1),
                IsDeleted = false
            },
            new SCStaffProfile
            {
                Id = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                AccountId = Guid.Parse("77777777-7777-7777-7777-777777777777"),
                WorkingLocation = "HCM Station",
                Status = "Active",
                CreatedAt = new DateTime(2025,1,1),
                UpdatedAt = new DateTime(2025,1,1),
                IsDeleted = false
            },
        ];
    }
}
