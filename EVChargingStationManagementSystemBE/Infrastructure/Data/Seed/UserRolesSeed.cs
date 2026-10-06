using Microsoft.AspNetCore.Identity;

namespace Infrastructure.Data.Seed
{
    public static class UserRolesSeed
    {
        public static List<IdentityUserRole<Guid>> GetUserRoles()
        {
            return [
                new IdentityUserRole<Guid>
                {
                    UserId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    RoleId = Guid.Parse("11111111-1111-1111-1111-111111111111")
                },
                new IdentityUserRole<Guid>
                {
                    UserId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222")
                },
                new IdentityUserRole<Guid>
                {
                    UserId = Guid.Parse("44444444-4444-4444-4444-444444444444"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222")
                },
                new IdentityUserRole<Guid>
                {
                    UserId = Guid.Parse("77777777-7777-7777-7777-777777777777"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222")
                },
                new IdentityUserRole<Guid>
                {
                    UserId = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                    RoleId = Guid.Parse("33333333-3333-3333-3333-333333333333")
                },
            ];
        }
    }
}
