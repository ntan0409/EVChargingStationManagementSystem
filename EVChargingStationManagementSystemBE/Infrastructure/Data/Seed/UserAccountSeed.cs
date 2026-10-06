using Microsoft.AspNetCore.Identity;
using Infrastructure.Models;

namespace Infrastructure.Data.Seed
{
    public static class UserAccountSeed
    {
        public static UserAccount[] GetUserAccounts() =>
        [
            new UserAccount
            {
                Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                Name = "Tran Thanh Tung ",
                Email = "admin@gmail.com",
                UserName = "admin@gmail.com",
                NormalizedEmail = "ADMIN@GMAIL.COM",
                NormalizedUserName = "ADMIN@GMAIL.COM",
                EmailConfirmed = true,
                SecurityStamp = "9fd925f3-34b4-46ce-971e-e3bcf4884150",
                ConcurrencyStamp = "457f1c5c-f68e-4364-912e-f0e443f8243d",
                PhoneNumber = "0123456789",
                LockoutEnabled = false,
                Status = "Active",
                RegistrationDate = new DateTime(2025, 1, 1),
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                PasswordHash = "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==",
                Gender = "Male",
                Address = "Headquarters, Hanoi",
                ProfilePictureUrl = "",
                LoginType = "System",
                IsDeleted = false
            },
            new UserAccount
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                Name = "Nguyen Le Phuc Du",
                Email = "staff1@gmail.com",
                UserName = "staff1@gmail.com",
                NormalizedEmail = "STAFF1@GMAIL.COM",
                NormalizedUserName = "STAFF1@GMAIL.COM",
                EmailConfirmed = true,
                SecurityStamp = "b9a67e8b-2351-4d2b-8ef1-1e908f5b63e1",
                ConcurrencyStamp = "c7e31c5c-f68e-4364-912e-f0e443f8243d",
                PhoneNumber = "0999999999",
                LockoutEnabled = false,
                Status = "Assigned",
                RegistrationDate = new DateTime(2025, 1, 1),
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                PasswordHash = "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==",
                Gender = "Male",
                Address = "Hanoi Station",
                ProfilePictureUrl = "",
                LoginType = "System",
                IsDeleted = false
            },
            new UserAccount
            {
                Id = Guid.Parse("44444444-4444-4444-4444-444444444444"),
                Name = "Dao Duy Le",
                Email = "staff2@gmail.com",
                UserName = "staff2@gmail.com",
                NormalizedEmail = "STAFF2@GMAIL.COM",
                NormalizedUserName = "STAFF2@GMAIL.COM",
                EmailConfirmed = true,
                SecurityStamp = "d5e67c7a-32d1-4c9b-b61f-6e701c4b2f72",
                ConcurrencyStamp = "a3f4c5b6-d7e8-4a9b-9123-f45678a9b012",
                PhoneNumber = "0123456788",
                LockoutEnabled = false,
                Status = "Active",
                RegistrationDate = new DateTime(2025, 1, 1),
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                PasswordHash = "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==",
                Gender = "Female",
                Address = "HCM Station",
                ProfilePictureUrl = "",
                LoginType = "System",
                IsDeleted = false
            },
            new UserAccount
            {
                Id = Guid.Parse("77777777-7777-7777-7777-777777777777"),
                Name = "Tran Minh Tu",
                Email = "operator2@gmail.com",
                UserName = "operator2@gmail.com",
                NormalizedEmail = "OPERATOR2@GMAIL.COM",
                NormalizedUserName = "OPERATOR2@GMAIL.COM",
                EmailConfirmed = true,
                SecurityStamp = "a1b2c3d4-e5f6-7890-abcd-1234567890ef",
                ConcurrencyStamp = "f1e2d3c4-b5a6-7890-cdef-0987654321ab",
                PhoneNumber = "0888888888",
                LockoutEnabled = false,
                Status = "Assigned",
                RegistrationDate = new DateTime(2025, 1, 1),
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                PasswordHash = "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==",
                Gender = "Male",
                Address = "Da Nang Station",
                ProfilePictureUrl = "",
                LoginType = "System",
                IsDeleted = false
            },
            new UserAccount
            {
                Id = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                Name = "Pham Le Xuan Bac",
                Email = "evdriver@gmail.com",
                UserName = "evdriver@gmail.com",
                NormalizedEmail = "EVDRIVER@GMAIL.COM",
                NormalizedUserName = "EVDRIVER@GMAIL.COM",
                EmailConfirmed = true,
                SecurityStamp = "ef12cd34-5678-49ab-9012-34ef56ab78cd",
                ConcurrencyStamp = "b4a5c6d7-e8f9-4012-9abc-de34f56a789b",
                PhoneNumber = "0987654321",
                LockoutEnabled = false,
                Status = "Active",
                RegistrationDate = new DateTime(2025, 1, 1),
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                PasswordHash = "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==",
                Gender = "Male",
                Address = "Ho Chi Minh City",
                ProfilePictureUrl = "",
                LoginType = "System",
                IsDeleted = false
            }
        ];
    }
}
