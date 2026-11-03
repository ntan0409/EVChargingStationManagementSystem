using System.Security.Cryptography;
using System.Text;
using Infrastructure.Data;
using Infrastructure.Data.Seed;
using Microsoft.EntityFrameworkCore;

namespace APIs.Configs;

internal static class TeamDemoSetup
{
    public static bool Configure(WebApplicationBuilder builder)
    {
        if (!builder.Environment.IsDevelopment())
            return false;

        var explicitDemo = builder.Configuration.GetValue<bool>("TeamDemo:Run");
        if (!explicitDemo && !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")))
            return false;

        var settingsPath = Path.GetFullPath(Path.Combine(
            builder.Environment.ContentRootPath, "..", "..", "appsettings.Local.json"));
        if (!File.Exists(settingsPath) && !explicitDemo)
            return false;

        if (File.Exists(settingsPath))
            builder.Configuration.AddJsonFile(settingsPath, optional: false, reloadOnChange: false);

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

        var key = Encoding.UTF8.GetBytes(app.Configuration["Jwt:Key"]!);
        var digest = HMACSHA256.HashData(key, "EVCSMS_TeamDemo/accounts"u8);
        var password = "Demo!a1" + Convert.ToBase64String(digest)[..16];
        await TeamDemoSeed.ApplyAsync(db, password);
        Console.WriteLine("Demo accounts: driver1@evcsms-demo.invalid and staff1@evcsms-demo.invalid");
        Console.WriteLine($"Local demo password: {password}");
    }
}
