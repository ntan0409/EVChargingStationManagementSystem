using System.Data;
using Infrastructure.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Infrastructure.Data.Seed;

public static class TeamDemoSeed
{
    private static readonly (string District, string Province, string Lat, string Lon)[] Sites =
    [
        ("Thủ Đức", "TP. Hồ Chí Minh", "10.8451", "106.7781"),
        ("Quận 7", "TP. Hồ Chí Minh", "10.7318", "106.7218"),
        ("Tân Bình", "TP. Hồ Chí Minh", "10.8006", "106.6520"),
        ("Biên Hòa", "Đồng Nai", "10.9460", "106.8243"),
        ("Thủ Dầu Một", "Bình Dương", "10.9817", "106.6519"),
        ("Ninh Kiều", "Cần Thơ", "10.0340", "105.7802"),
        ("Hải Châu", "Đà Nẵng", "16.0551", "108.2208"),
        ("Cầu Giấy", "Hà Nội", "21.0368", "105.7880"),
        ("Long Biên", "Hà Nội", "21.0420", "105.9002"),
        ("Lê Chân", "Hải Phòng", "20.8416", "106.6787"),
    ];

    private static readonly (string Name, string Brand, int Battery, int Power)[] Models =
    [
        ("VF 3", "VinFast", 19, 25), ("VF 5 Plus", "VinFast", 37, 50),
        ("VF 6 Eco", "VinFast", 60, 80), ("VF 6 Plus", "VinFast", 60, 90),
        ("VF 7 Eco", "VinFast", 60, 90), ("VF 7 Plus", "VinFast", 75, 120),
        ("VF 8 Eco", "VinFast", 88, 120), ("VF 8 Plus", "VinFast", 88, 150),
        ("VF 9 Eco", "VinFast", 92, 150), ("VF 9 Plus", "VinFast", 123, 150),
        ("Herio Green", "VinFast", 37, 50), ("Ioniq 5", "Hyundai", 72, 120),
    ];

    private static readonly (string Plug, int Power)[] Posts = [("CCS2", 60), ("CCS2", 120), ("Type2", 22)];

    private static Guid Id(int kind, int number) => Guid.Parse($"6de60000-8a51-4319-a{kind:000}-{number:000000000000}");

    public static async Task ApplyAsync(EVCSMSContext db, string password)
    {
        if (db.Database.GetDbConnection().Database != "EVCSMS_TeamDemo")
            throw new InvalidOperationException("Demo seed requires EVCSMS_TeamDemo.");

        await db.Database.CreateExecutionStrategy().ExecuteAsync(async () =>
        {
            db.ChangeTracker.Clear();
            await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
            var roles = await db.Roles.ToDictionaryAsync(role => role.NormalizedName!);
            var adminId = await (from user in db.Users
                                 join membership in db.UserRoles on user.Id equals membership.UserId
                                 where !user.IsDeleted && membership.RoleId == roles["ADMIN"].Id
                                 orderby user.Id
                                 select user.Id).FirstAsync();
            var now = DateTime.Now;
            var hasher = new PasswordHasher<UserAccount>();

            for (var i = 0; i < Models.Length; i++)
            {
                var model = Models[i];
                await AddMissing(db, new VehicleModel
                {
                    Id = Id(5, i + 1), ModelName = model.Name, Brand = model.Brand,
                    ModelYear = 2025, VehicleType = "Car", BatteryCapacityKWh = model.Battery,
                    RecommendedChargingPowerKW = model.Power, ImageUrl = "", CreatedBy = adminId,
                    CreatedAt = now, UpdatedAt = now,
                }, Id(5, i + 1));
            }

            for (var number = 1; number <= Sites.Length; number++)
            {
                var site = Sites[number - 1];
                var staffId = Id(1, number);
                var driverId = Id(2, number);
                var stationId = Id(6, number);
                var stationName = $"Trạm demo {site.District}";
                var available = number != Sites.Length;

                await EnsureAccount(db, staffId, $"staff{number}", $"Nhân viên demo {site.District}",
                    "Assigned", roles["STAFF"].Id, now, hasher, password);
                await EnsureAccount(db, driverId, $"driver{number}", $"Tài xế demo {site.District}",
                    "Active", roles["EVDRIVER"].Id, now, hasher, password);

                if (!await db.SCStaffs.AnyAsync(profile => profile.AccountId == staffId))
                    db.SCStaffs.Add(new SCStaffProfile
                    {
                        Id = Id(3, number), AccountId = staffId, WorkingLocation = stationName,
                        CreatedAt = now, UpdatedAt = now,
                    });

                var driverProfileId = await db.EVDrivers.Where(profile => profile.AccountId == driverId)
                    .Select(profile => (Guid?)profile.Id).FirstOrDefaultAsync();
                if (driverProfileId == null)
                {
                    driverProfileId = Id(4, number);
                    db.EVDrivers.Add(new EVDriverProfile
                    {
                        Id = driverProfileId.Value, AccountId = driverId, CreatedAt = now, UpdatedAt = now,
                    });
                }

                await AddMissing(db, new UserVehicle
                {
                    DriverId = driverProfileId.Value, VehicleModelId = Id(5, number),
                }, driverProfileId.Value, Id(5, number));

                await AddMissing(db, new ChargingStation
                {
                    Id = stationId, StationName = stationName, Location = $"Khu vực {site.District}",
                    Province = site.Province, Latitude = site.Lat, Longitude = site.Lon, OperatorId = staffId,
                    Status = available ? "Active" : "Maintenance", TotalCarChargingPosts = 3,
                    AvailableCarChargingPosts = available ? 3 : 0, TotalCarChargingConnectors = 6,
                    AvailableCarConnectors = available ? 6 : 0, CreatedAt = now, UpdatedAt = now,
                }, stationId);

                for (var slot = 1; slot <= Posts.Length; slot++)
                {
                    var post = Posts[slot - 1];
                    var postNumber = (number - 1) * Posts.Length + slot;
                    var postId = Id(7, postNumber);
                    var existingPost = await db.ChargingPosts.FindAsync(postId);
                    if (existingPost == null)
                        db.ChargingPosts.Add(new ChargingPost
                        {
                            Id = postId, StationId = stationId, PostName = $"Trụ {slot} - {post.Plug} {post.Power} kW",
                            ConnectorType = post.Plug, VehicleTypeSupported = "Car", MaxPowerKw = post.Power,
                            Status = available ? "Available" : "Maintained", TotalConnectors = 2,
                            AvailableConnectors = available ? 2 : 0, CreatedAt = now, UpdatedAt = now,
                        });

                    for (var port = 1; port <= 2; port++)
                    {
                        var connectorId = Id(8, (postNumber - 1) * 2 + port);
                        var postAvailable = existingPost == null ? available : existingPost.Status == "Available";
                        await AddMissing(db, new Connector
                        {
                            Id = connectorId, ChargingPostId = postId, ConnectorName = $"Cổng {port}",
                            Status = postAvailable ? "Available" : "OutOfService", CreatedAt = now, UpdatedAt = now,
                        }, connectorId);
                    }
                }

                await AddMissing(db, new Feedback
                {
                    Id = Id(9, number), AccountId = driverId, Subject = "Góp ý demo về điểm sạc", Stars = 4,
                    Message = $"Dữ liệu mẫu: bổ sung biển chỉ dẫn ở {site.District}.", CreatedAt = now,
                }, Id(9, number));

                if (number % 2 == 0)
                    await AddMissing(db, new Report
                    {
                        Id = Id(10, number), Title = "Kiểm tra định kỳ trụ sạc demo",
                        ReportType = "Maintenance", Severity = "Low",
                        Description = "Phiếu mẫu dùng để trình diễn danh sách báo cáo.",
                        ReportedById = staffId, StationId = stationId, PostId = Id(7, (number - 1) * Posts.Length + 1),
                        CreatedAt = now, UpdatedAt = now,
                    }, Id(10, number));
            }

            await AnonymizeLegacyAccounts(db);
            await db.SaveChangesAsync();
            await transaction.CommitAsync();
        });
    }

    private static async Task AddMissing<TEntity>(EVCSMSContext db, TEntity entity, params object[] key)
        where TEntity : class
    {
        var set = db.Set<TEntity>();
        if (await set.FindAsync(key) == null)
            set.Add(entity);
    }

    private static async Task EnsureAccount(EVCSMSContext db, Guid id, string alias, string name,
        string status, Guid roleId, DateTime now, PasswordHasher<UserAccount> hasher, string password)
    {
        var account = await db.Users.FindAsync(id);
        if (account == null)
        {
            var email = $"{alias}@evcsms-demo.invalid";
            account = new UserAccount
            {
                Id = id, Name = name, Email = email, UserName = email, EmailConfirmed = true,
                NormalizedEmail = email.ToUpperInvariant(), NormalizedUserName = email.ToUpperInvariant(),
                Status = status, RegistrationDate = now, CreatedAt = now, UpdatedAt = now,
                LockoutEnabled = true, SecurityStamp = Guid.NewGuid().ToString(),
            };
            db.Users.Add(account);
        }
        if (account.PasswordHash == null && account.Email == $"{alias}@evcsms-demo.invalid")
            account.PasswordHash = hasher.HashPassword(account, password);

        await AddMissing(db, new IdentityUserRole<Guid> { UserId = id, RoleId = roleId }, id, roleId);
    }

    private static async Task AnonymizeLegacyAccounts(EVCSMSContext db)
    {
        foreach (var digit in "12347")
        {
            var hex = new string(digit, 32);
            var account = await db.Users.FindAsync(Guid.ParseExact(hex, "N"));
            if (account == null || account.Email?.EndsWith("@evcsms-demo.invalid", StringComparison.OrdinalIgnoreCase) == true)
                continue;

            var email = $"legacy{digit}@evcsms-demo.invalid";
            account.Name = $"Legacy demo {digit}";
            account.Email = account.UserName = email;
            account.NormalizedEmail = account.NormalizedUserName = email.ToUpperInvariant();
            account.PhoneNumber = account.Address = account.ProfilePictureUrl = account.ProviderUserId = null!;
            account.DateOfBirth = null;
            account.PasswordHash = null;
        }
    }
}
