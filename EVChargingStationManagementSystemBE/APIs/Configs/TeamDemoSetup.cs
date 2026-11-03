using System.Security.Cryptography;
using System.Text;
using Infrastructure.Data;
using Infrastructure.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace APIs.Configs;

internal static class TeamDemoSetup
{
    public static bool Configure(WebApplicationBuilder builder)
    {
        if (!builder.Environment.IsDevelopment() ||
            !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")))
            return false;

        var settingsPath = Path.GetFullPath(Path.Combine(
            builder.Environment.ContentRootPath, "..", "..", "appsettings.Local.json"));
        if (!File.Exists(settingsPath))
            return false;

        var local = new ConfigurationBuilder().AddJsonFile(settingsPath).Build();
        foreach (var name in new[] { "Enabled", "TestToken", "TestBankAccountId" })
            builder.Configuration[$"SePay:{name}"] = local[$"SePay:{name}"];

        builder.Configuration["ConnectionStrings:DefaultConnection"] =
            @"Server=(localdb)\MSSQLLocalDB;Database=EVCSMS_TeamDemo;Integrated Security=True;TrustServerCertificate=True;MultipleActiveResultSets=True";
        builder.Configuration["ChargingDemo:Enabled"] = "true";
        builder.Configuration["VnPay:Enabled"] = "false";

        if (Encoding.UTF8.GetByteCount(builder.Configuration["Jwt:Key"] ?? "") < 32)
        {
            var directory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "EVCSMS", "TeamDemo");
            Directory.CreateDirectory(directory);
            var keyPath = Path.Combine(directory, "jwt.key");
            if (!File.Exists(keyPath))
            {
                var candidate = keyPath + "." + Guid.NewGuid().ToString("N");
                File.WriteAllText(candidate, Convert.ToBase64String(RandomNumberGenerator.GetBytes(48)));
                try { File.Move(candidate, keyPath); }
                catch (IOException) when (File.Exists(keyPath)) { }
                finally { File.Delete(candidate); }
            }
            builder.Configuration["Jwt:Key"] = File.ReadAllText(keyPath).Trim();
        }

        return true;
    }

    public static async Task InitializeAsync(WebApplication app)
    {
        await using var scope = app.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<EVCSMSContext>();
        await db.Database.MigrateAsync();

        using var seed = typeof(TeamDemoSetup).Assembly.GetManifestResourceStream("TeamDemoSeed.sql")
            ?? throw new InvalidOperationException("Team demo SQL resource is missing.");
        using var reader = new StreamReader(seed);
        await db.Database.ExecuteSqlRawAsync(await reader.ReadToEndAsync());

        var key = Encoding.UTF8.GetBytes(app.Configuration["Jwt:Key"]!);
        var digest = HMACSHA256.HashData(key, "EVCSMS_TeamDemo/accounts"u8);
        var password = "Demo!a1" + Convert.ToBase64String(digest)[..16];
        var hash = new PasswordHasher<UserAccount>().HashPassword(new UserAccount(), password);
        await db.Database.ExecuteSqlInterpolatedAsync($"""
            UPDATE dbo.AspNetUsers
            SET Name = CONCAT('Legacy demo ', LEFT(CONVERT(varchar(36), Id), 1)),
                Email = CONCAT('legacy', LEFT(CONVERT(varchar(36), Id), 1), '@evcsms-demo.invalid'),
                UserName = CONCAT('legacy', LEFT(CONVERT(varchar(36), Id), 1), '@evcsms-demo.invalid'),
                NormalizedEmail = UPPER(CONCAT('legacy', LEFT(CONVERT(varchar(36), Id), 1), '@evcsms-demo.invalid')),
                NormalizedUserName = UPPER(CONCAT('legacy', LEFT(CONVERT(varchar(36), Id), 1), '@evcsms-demo.invalid')),
                PhoneNumber = NULL, Address = NULL, DateOfBirth = NULL,
                ProfilePictureUrl = NULL, ProviderUserId = NULL, PasswordHash = NULL
            WHERE CONVERT(varchar(36), Id) IN (
                '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
                '33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444',
                '77777777-7777-7777-7777-777777777777')
              AND ISNULL(Email, '') NOT LIKE '%@evcsms-demo.invalid';

            UPDATE dbo.AspNetUsers SET PasswordHash = {hash}
            WHERE PasswordHash IS NULL AND Email LIKE '%@evcsms-demo.invalid'
              AND CONVERT(varchar(36),Id) LIKE '6de60000-8a51-4319-a00[12]-%';
            """);
        Console.WriteLine("Demo accounts: driver1@evcsms-demo.invalid and staff1@evcsms-demo.invalid");
        Console.WriteLine($"Local demo password: {password}");
    }
}
