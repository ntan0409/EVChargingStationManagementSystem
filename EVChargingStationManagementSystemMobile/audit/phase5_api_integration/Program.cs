using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Common.Helper;
using Common.DTOs.VehicleModelDto;
using Common.Enum.VehicleModel;
using Infrastructure.Data;
using Infrastructure.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Phase5Integration;

// Real controllers, authorization, EF and SQL Server. No gateway or physical charger.
// All writes are restricted to a fresh temporary DB migrated from the existing schema.
internal static class Runner
{
    private static int passed;
    private static void Check(bool condition, string name)
    {
        if (!condition) throw new InvalidOperationException("FAIL: " + name);
        Console.WriteLine("PASS: " + name); passed++;
    }
    private static async Task<JsonElement> Data(HttpResponseMessage response, HttpStatusCode expected, string name)
    {
        Check(response.StatusCode == expected, name + " HTTP " + (int)expected + " (actual " + (int)response.StatusCode + ")");
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return json.TryGetProperty("data", out var data) ? data : json;
    }
    private static async Task<HttpClient> Login(ApiFactory factory, string email, string password)
    {
        var client = factory.CreateClient(new WebApplicationFactoryClientOptions { BaseAddress = new Uri("https://localhost"), AllowAutoRedirect = false });
        var json = await Data(await client.PostAsJsonAsync("/api/Auth/login", new { email, password }), HttpStatusCode.OK, "Backend issues JWT for fixture identity");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", json.GetProperty("token").GetString());
        return client;
    }
    private static async Task<UserAccount> NewDriver(UserManager<UserAccount> users, EVCSMSContext db, string password)
    {
        var id = Guid.NewGuid(); var email = id.ToString("N") + "@phase4.invalid";
        var user = new UserAccount { Id = id, Email = email, UserName = email, Name = "Phase4 test identity",
            EmailConfirmed = true, Status = "Active", CreatedAt = DateTime.Now, UpdatedAt = DateTime.Now, RegistrationDate = DateTime.Now };
        if (!(await users.CreateAsync(user, password)).Succeeded || !(await users.AddToRoleAsync(user, "EVDriver")).Succeeded)
            throw new InvalidOperationException("Unable to create fixture identity");
        db.EVDrivers.Add(new EVDriverProfile { Id = Guid.NewGuid(), AccountId = id, Status = "Active", Point = 0,
            CreatedAt = DateTime.Now, UpdatedAt = DateTime.Now });
        await db.SaveChangesAsync(); return user;
    }
    private static async Task<UserAccount> FixturePassword(UserManager<UserAccount> users, Guid id, string password)
    {
        var user = await users.FindByIdAsync(id.ToString()) ?? throw new InvalidOperationException("Missing seeded fixture role");
        var reset = await users.GeneratePasswordResetTokenAsync(user);
        if (!(await users.ResetPasswordAsync(user, reset, password)).Succeeded) throw new InvalidOperationException("Fixture password failed");
        return user;
    }
    public static async Task<int> Main(string[] args)
    {
        var sandboxOrigin = args.Length == 0 ? null : new Uri(args.Single());
        if (sandboxOrigin != null && (sandboxOrigin.Scheme != "https" ||
            !sandboxOrigin.Host.EndsWith(".trycloudflare.com", StringComparison.OrdinalIgnoreCase) ||
            sandboxOrigin.PathAndQuery != "/" || !sandboxOrigin.IsDefaultPort ||
            sandboxOrigin.UserInfo.Length != 0 || sandboxOrigin.Fragment.Length != 0))
            throw new ArgumentException("Supply the HTTPS origin of a Cloudflare Quick Tunnel.");
        var previousMode = Environment.GetEnvironmentVariable("VnPay__Mode");
        var previousIpnUrl = Environment.GetEnvironmentVariable("VnPay__IpnUrl");
        var previousReturnUrl = Environment.GetEnvironmentVariable("VnPay__ReturnUrl");
        var databaseName = "EVCSMS_Phase5_" + Guid.NewGuid().ToString("N");
        var connection = "Server=(localdb)\\MSSQLLocalDB;Database=" + databaseName + ";Integrated Security=True;TrustServerCertificate=True;MultipleActiveResultSets=True";
        var options = new DbContextOptionsBuilder<EVCSMSContext>().UseSqlServer(connection).Options;
        await using var cleanup = new EVCSMSContext(options);
        var previousConnection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");
        var previousJwt = Environment.GetEnvironmentVariable("Jwt__Key");
        var previousVnpay = Environment.GetEnvironmentVariable("VnPay__Enabled");
        var previousRoot = Environment.GetEnvironmentVariable("ASPNETCORE_TEST_CONTENTROOT_APIS");
        var created = false;
        try
        {
            // This generated DB name is never EVCSMS. The user's database is untouched.
            if (!databaseName.StartsWith("EVCSMS_Phase5_", StringComparison.Ordinal) || databaseName.Length != 46)
                throw new InvalidOperationException("Unsafe test database name");
            await cleanup.Database.MigrateAsync(); created = true;
            Environment.SetEnvironmentVariable("ConnectionStrings__DefaultConnection", connection);
            Environment.SetEnvironmentVariable("Jwt__Key", Convert.ToHexString(RandomNumberGenerator.GetBytes(48)));
            Environment.SetEnvironmentVariable("VnPay__Enabled", sandboxOrigin == null ? "false" : "true");
            if (sandboxOrigin != null)
            {
                Environment.SetEnvironmentVariable("VnPay__Mode", "Sandbox");
                Environment.SetEnvironmentVariable("VnPay__IpnUrl", new Uri(sandboxOrigin, SandboxCallback.IpnPath).AbsoluteUri);
                Environment.SetEnvironmentVariable("VnPay__ReturnUrl", new Uri(sandboxOrigin, SandboxCallback.ReturnPath).AbsoluteUri);
            }
            Environment.SetEnvironmentVariable("ASPNETCORE_TEST_CONTENTROOT_APIS", Path.GetFullPath("APIs"));
            await using var factory = new ApiFactory();
            await using var scope = factory.Services.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<EVCSMSContext>();
            Check(db.Database.GetDbConnection().Database == databaseName, "Host uses isolated SQL database");
            var users = scope.ServiceProvider.GetRequiredService<UserManager<UserAccount>>();
            var password = "Fixture!9a" + Guid.NewGuid().ToString("N");
            var driverA = await NewDriver(users, db, password);
            var driverB = await NewDriver(users, db, password);
            var connector = await db.Set<Connector>().AsNoTracking().Include(c => c.ChargingPost)
                .ThenInclude(p => p.ChargingStationNavigation).FirstAsync(c => !c.IsDeleted && c.Status == "Available");
            var operatorId = connector.ChargingPost.ChargingStationNavigation.OperatorId ?? throw new InvalidOperationException("No seeded operator");
            var staff = await FixturePassword(users, operatorId, password);
            // Historic migrations do not assign every current seed role. Define this test identity
            // through Identity in the temporary DB; production roles/data are not changed.
            if (!await users.IsInRoleAsync(staff, "Staff"))
                Check((await users.AddToRoleAsync(staff, "Staff")).Succeeded, "Assign fixture operator role via Identity");
            Check((await users.GetRolesAsync(staff)).Contains("Staff"), "Seeded station operator has Staff role");
            var adminId = (await db.UserRoles.FirstAsync(r => r.RoleId == Guid.Parse("11111111-1111-1111-1111-111111111111"))).UserId;
            var admin = await FixturePassword(users, adminId, password);
            using var a = await Login(factory, driverA.Email!, password);
            using var b = await Login(factory, driverB.Email!, password);
            using var staffClient = await Login(factory, staff.Email!, password);
            using var adminClient = await Login(factory, admin.Email!, password);
            using var anonymous = factory.CreateClient(new WebApplicationFactoryClientOptions { BaseAddress = new Uri("https://localhost"), AllowAutoRedirect = false });

            Check((await anonymous.GetAsync("/api/Notification")).StatusCode == HttpStatusCode.Unauthorized, "Anonymous notifications require JWT");
            Check((await anonymous.PatchAsJsonAsync("/api/Booking/checkin", new { checkInCode = "fixture" })).StatusCode == HttpStatusCode.Unauthorized, "Anonymous booking check-in denied");
            var originalOutput = Console.Out;
            await db.Entry(driverA).ReloadAsync();
            using var capturedOutput = new StringWriter();
            try
            {
                Console.SetOut(capturedOutput);
                driverA.Name = "SENSITIVE-FIXTURE-DO-NOT-LOG";
                await scope.ServiceProvider.GetRequiredService<Infrastructure.IUnitOfWork.IUnitOfWork>().SaveChangesAsync();
            }
            finally { Console.SetOut(originalOutput); }
            Check(!capturedOutput.ToString().Contains("SENSITIVE-FIXTURE-DO-NOT-LOG"), "UnitOfWork does not log property values");

            // The original VF8 seed has capacity zero. Supply explicit fixture metadata through the Admin API,
            // not a made-up capacity in the production Flutter model or the user's EVCSMS database.
            var fixtureVehicle = await Data(await adminClient.PostAsJsonAsync("/api/VehicleModel", new VehicleModelCreateDto {
                ModelName = "Phase4 fixture car", ModelYear = 2026, VehicleType = VehicleTypeEnum.Car,
                BatteryCapacityKWh = 80, RecommendedChargingPowerKW = 50, ImageUrl = ""
            }), HttpStatusCode.Created, "Create valid vehicle metadata in temporary test DB");
            var fixtureVehicleId = fixtureVehicle.GetProperty("id").GetGuid();
            await Data(await adminClient.PatchAsync("/api/VehicleModel/status?vehicleModelId=" + fixtureVehicleId + "&status=Active", null),
                HttpStatusCode.OK, "Activate fixture vehicle via Admin API");
            var vehicle = await db.VehicleModels.AsNoTracking().FirstAsync(v => v.Id == fixtureVehicleId);

            Check((await anonymous.GetAsync("/api/ChargingSession/current")).StatusCode == HttpStatusCode.Unauthorized, "Anonymous session read denied");
            Check((await anonymous.PostAsJsonAsync("/api/Payment", new { })).StatusCode == HttpStatusCode.Unauthorized, "Anonymous payment creation denied");
            var profile = await Data(await a.GetAsync("/api/EVDriver/profile"), HttpStatusCode.OK, "Verified profile");
            var incomplete = await Data(await a.GetAsync("/api/EVDriver/eligibility"), HttpStatusCode.OK, "Server evaluates incomplete profile after login");
            Check(!incomplete.GetProperty("profileCompleted").GetBoolean() && !incomplete.GetProperty("canBook").GetBoolean(), "Incomplete profile cannot book");
            Check((await a.PostAsJsonAsync("/api/Booking", new { stationId = connector.ChargingPost.StationId, vehicleId = vehicle.Id, startTime = DateTime.Now.AddHours(1) })).StatusCode == HttpStatusCode.Conflict, "Direct booking without completed profile denied");
            await Data(await a.PutAsJsonAsync("/api/EVDriver/update", new { driverId = profile.GetProperty("id").GetGuid(), name = "Fixture driver", phoneNumber = "0900000001" }), HttpStatusCode.OK, "Save required profile fields without inventing address requirement");
            var withoutVehicle = await Data(await a.GetAsync("/api/EVDriver/eligibility"), HttpStatusCode.OK, "Server checks missing selected vehicle");
            Check(!withoutVehicle.GetProperty("profileCompleted").GetBoolean(), "Profile without saved vehicle is incomplete");
            await Data(await a.PutAsJsonAsync("/api/EVDriver/update", new { driverId = profile.GetProperty("id").GetGuid(), vehicleModelIds = new[] { vehicle.Id } }), HttpStatusCode.OK, "Persist real garage FK via API");
            var completed = await Data(await a.GetAsync("/api/EVDriver/eligibility"), HttpStatusCode.OK, "Server confirms profile completion after catalog selection");
            Check(completed.GetProperty("profileCompleted").GetBoolean() && completed.GetProperty("canBook").GetBoolean(), "Completed valid profile can book");
            var otherProfile = await Data(await b.GetAsync("/api/EVDriver/profile"), HttpStatusCode.OK, "Other driver profile");
            Check((await anonymous.GetAsync("/api/EVDriver/account/" + driverA.Id)).StatusCode == HttpStatusCode.Unauthorized, "Anonymous driver-profile lookup denied");
            Check((await b.GetAsync("/api/EVDriver/account/" + driverA.Id)).StatusCode == HttpStatusCode.Forbidden, "Foreign account profile lookup denied");
            Check((await b.GetAsync("/api/EVDriver/" + profile.GetProperty("id").GetGuid())).StatusCode == HttpStatusCode.Forbidden, "Foreign driver profile lookup denied");
            Check((await b.PutAsJsonAsync("/api/EVDriver/update", new { driverId = profile.GetProperty("id").GetGuid(), name = "Must not write" })).StatusCode == HttpStatusCode.Forbidden, "Cannot change another driver's garage");
            await Data(await b.PutAsJsonAsync("/api/EVDriver/update", new { driverId = otherProfile.GetProperty("id").GetGuid(), name = "Other fixture", phoneNumber = "0900000002", vehicleModelIds = new[] { vehicle.Id } }), HttpStatusCode.OK, "Other driver's independent garage");
            var secondVehicle = await Data(await adminClient.PostAsJsonAsync("/api/VehicleModel", new VehicleModelCreateDto {
                ModelName = "Second explicit test car", ModelYear = 2026, VehicleType = VehicleTypeEnum.Car,
                BatteryCapacityKWh = 60, RecommendedChargingPowerKW = 50, ImageUrl = ""
            }), HttpStatusCode.Created, "Admin creates another supported fixture model");
            var secondVehicleId = secondVehicle.GetProperty("id").GetGuid();
            await Data(await adminClient.PatchAsync("/api/VehicleModel/status?vehicleModelId=" + secondVehicleId + "&status=Active", null), HttpStatusCode.OK, "Admin activates second fixture model");
            Check((await a.PostAsJsonAsync("/api/VehicleModel", new VehicleModelCreateDto { ModelName = "Forbidden customer model" })).StatusCode == HttpStatusCode.Forbidden, "Customer cannot create arbitrary catalog models");
            await Data(await a.PutAsJsonAsync("/api/EVDriver/update", new { driverId = profile.GetProperty("id").GetGuid(), vehicleModelIds = new[] { secondVehicleId } }), HttpStatusCode.OK, "Owner links second valid catalog model before booking");
            await Data(await adminClient.PatchAsync("/api/VehicleModel/status?vehicleModelId=" + vehicle.Id + "&status=Inactive", null), HttpStatusCode.OK, "Admin disables fixture model");
            Check((await b.PostAsJsonAsync("/api/Booking", new { stationId = connector.ChargingPost.StationId, vehicleId = vehicle.Id, startTime = DateTime.Now.AddHours(1) })).StatusCode == HttpStatusCode.Conflict, "Disabled owned vehicle cannot book");
            await Data(await adminClient.PatchAsync("/api/VehicleModel/status?vehicleModelId=" + vehicle.Id + "&status=Active", null), HttpStatusCode.OK, "Admin restores fixture active state");
            await Data(await adminClient.PutAsJsonAsync("/api/VehicleModel?vehicleModelId=" + vehicle.Id, new VehicleModelUpdateDto { ModelName = "Phase4 fixture car", ModelYear = 2026, VehicleType = VehicleTypeEnum.Car, BatteryCapacityKWh = 0, RecommendedChargingPowerKW = 50 }), HttpStatusCode.OK, "Admin fixture invalid-capacity contract test");
            Check((await b.PostAsJsonAsync("/api/Booking", new { stationId = connector.ChargingPost.StationId, vehicleId = vehicle.Id, startTime = DateTime.Now.AddHours(1) })).StatusCode == HttpStatusCode.Conflict, "Zero battery specification cannot book");
            await Data(await adminClient.PutAsJsonAsync("/api/VehicleModel?vehicleModelId=" + vehicle.Id, new VehicleModelUpdateDto { ModelName = "Phase4 fixture car", ModelYear = 2026, VehicleType = VehicleTypeEnum.Car, BatteryCapacityKWh = 80, RecommendedChargingPowerKW = 50 }), HttpStatusCode.OK, "Restore explicit test vehicle metadata only in isolated DB");
            var booking = await Data(await b.PostAsJsonAsync("/api/Booking", new { stationId = connector.ChargingPost.StationId,
                vehicleId = vehicle.Id, startTime = DateTime.Now.AddHours(1) }), HttpStatusCode.Created, "Create real booking via backend in isolated DB");
            var bookingId = booking.GetProperty("id").GetGuid();
            Check(booking.GetProperty("vehicleModelId").GetGuid() == vehicle.Id, "Booking persists selected vehicle FK");
            Check((await b.DeleteAsync("/api/EVDriver/vehicle/" + vehicle.Id)).StatusCode == HttpStatusCode.Conflict, "Active booking prevents removal of its vehicle");
            Check((await b.PutAsJsonAsync("/api/EVDriver/update", new { driverId = otherProfile.GetProperty("id").GetGuid(), vehicleModelIds = new[] { secondVehicleId } })).StatusCode == HttpStatusCode.Conflict, "Vehicle change while active booking is rejected");
            Check((await db.Bookings.AsNoTracking().FirstAsync(row => row.Id == bookingId)).VehicleModelId == vehicle.Id, "Rejected vehicle change preserves booking selection");
            await Data(await b.GetAsync("/api/Booking/" + bookingId), HttpStatusCode.OK, "Owner reads booking");
            Check((await a.GetAsync("/api/Booking/" + bookingId)).StatusCode == HttpStatusCode.NotFound, "Foreign booking detail denied");
            Check((await a.PatchAsJsonAsync("/api/Booking/checkin", new { checkInCode = booking.GetProperty("checkInCode").GetString() })).StatusCode == HttpStatusCode.NotFound, "Foreign check-in code cannot mutate another booking");
            Check((await a.PatchAsync("/api/Booking/" + bookingId + "/complete", null)).StatusCode == HttpStatusCode.NotFound, "Foreign booking completion denied");
            Check((await b.PatchAsync("/api/Booking/" + bookingId + "/cancel", null)).StatusCode == HttpStatusCode.NoContent, "Owner cancellation confirmed by API");
            await Data(await a.GetAsync("/api/Notification?page=1&pageSize=10"), HttpStatusCode.OK, "Driver notifications empty server page");
            Check((await a.GetAsync("/api/Notification?page=0&pageSize=0")).StatusCode == HttpStatusCode.BadRequest, "Invalid pagination rejected");
            var stations = await Data(await a.GetAsync("/api/ChargingStation"), HttpStatusCode.OK, "Station catalog from SQL");
            Check(stations.GetArrayLength() > 0, "No fabricated station fallback needed");
            await Data(await a.GetAsync("/api/ChargingStation/" + connector.ChargingPost.StationId), HttpStatusCode.OK, "Station detail contract");
            await Data(await a.GetAsync("/api/ChargingPost/" + connector.ChargingPostId), HttpStatusCode.OK, "Post/connectors contract");
            Check((await a.PatchAsync($"/api/Connector/connector-toggle?connectorId={connector.Id}&toggle=false", null)).StatusCode == HttpStatusCode.Forbidden,
                "Driver cannot forge hardware plug events");
            var ownBooking = await Data(await a.PostAsJsonAsync("/api/Booking", new { stationId = connector.ChargingPost.StationId,
                vehicleId = vehicle.Id, startTime = DateTime.Now.AddMinutes(6) }), HttpStatusCode.Created, "Create own mandatory booking using validated vehicle");
            var ownBookingId = ownBooking.GetProperty("id").GetGuid();
            await Data(await adminClient.PostAsync("/api/Booking/auto-reserve-before-start", null), HttpStatusCode.OK, "Reserve the booked connector via backend");
            var reservedBooking = await db.Bookings.AsNoTracking().FirstAsync(row => row.Id == ownBookingId);
            var reservedConnector = await db.Set<Connector>().AsNoTracking().FirstAsync(row => row.Id == connector.Id);
            Check(reservedBooking.ConnectorId == connector.Id && reservedBooking.VehicleModelId == vehicle.Id &&
                reservedConnector.Status == "Reserved" && reservedConnector.IsLocked, "Reservation locks assigned connector and preserves booked vehicle");
            Check((await a.PostAsJsonAsync("/api/ChargingSession/Start", new { connectorId = connector.Id, vehicleModelId = vehicle.Id,
                batteryCapacityKWh = vehicle.BatteryCapacityKWh, initialBatteryLevelPercent = 20, expectedEnergiesKWh = 80 })).StatusCode == HttpStatusCode.Conflict, "Direct Start without booking denied");
            Check((await a.PostAsJsonAsync("/api/ChargingSession/Start", new { bookingId = ownBookingId, connectorId = connector.Id, vehicleModelId = vehicle.Id,
                batteryCapacityKWh = vehicle.BatteryCapacityKWh, initialBatteryLevelPercent = 20, expectedEnergiesKWh = 80 })).StatusCode == HttpStatusCode.Conflict, "Booking must be checked in before Start");
            await Data(await a.PatchAsJsonAsync("/api/Booking/checkin", new { checkInCode = ownBooking.GetProperty("checkInCode").GetString() }), HttpStatusCode.OK, "Check-in own booking in supported time window");
            Check((await a.PostAsJsonAsync("/api/ChargingSession/Start", new { bookingId = ownBookingId, connectorId = connector.Id, vehicleModelId = secondVehicleId,
                batteryCapacityKWh = 60, initialBatteryLevelPercent = 20, expectedEnergiesKWh = 80 })).StatusCode == HttpStatusCode.Conflict, "Start cannot substitute another owned vehicle for booked vehicle");
            // Explicit API test input simulating a staff/hardware event, NOT physical charging evidence.
            await Data(await staffClient.PatchAsync($"/api/Connector/connector-toggle?connectorId={connector.Id}&toggle=false", null), HttpStatusCode.OK, "Backend accepts fixture plug event");
            var start = new { bookingId = ownBookingId, connectorId = connector.Id, vehicleModelId = vehicle.Id, batteryCapacityKWh = vehicle.BatteryCapacityKWh,
                initialBatteryLevelPercent = 20, expectedEnergiesKWh = 80 };
            var session = await Data(await a.PostAsJsonAsync("/api/ChargingSession/Start", start), HttpStatusCode.Created, "Backend creates session (API fixture, no hardware)");
            var sessionId = session.GetProperty("id").GetGuid();
            Check(sessionId != Guid.Empty && session.GetProperty("status").GetString() == "Charging", "Session ID/status originate in backend");
            using (var restored = await Login(factory, driverA.Email!, password))
            {
                var restoredProfile = await Data(await restored.GetAsync("/api/EVDriver/profile"), HttpStatusCode.OK, "Restored login re-reads server profile");
                Check(restoredProfile.GetProperty("profileCompleted").GetBoolean(), "Profile completion persists as server-derived state, not local flag");
                var restoredSession = await Data(await restored.GetAsync("/api/ChargingSession/current"), HttpStatusCode.OK, "Fresh authenticated client restores actual current session");
                Check(restoredSession.GetProperty("id").GetGuid() == sessionId, "Restored session ID matches SQL record");
            }
            Check((await a.PostAsJsonAsync("/api/ChargingSession/Start", start)).StatusCode == HttpStatusCode.Conflict, "Duplicate Start cannot create second session");
            Check((await b.GetAsync("/api/ChargingSession/" + sessionId)).StatusCode == HttpStatusCode.NotFound, "Foreign session read denied");
            Check((await b.PatchAsJsonAsync("/api/ChargingSession/Stop?sessionId=" + sessionId, new { energyDeliveredKWh = 5 })).StatusCode == HttpStatusCode.NotFound, "Foreign Stop denied");
            Check((await a.PatchAsJsonAsync("/api/ChargingSession/Stop?sessionId=" + sessionId, new { })).StatusCode == HttpStatusCode.BadRequest, "Missing energy is not silently zero");
            Check((await a.PatchAsJsonAsync("/api/ChargingSession/Stop?sessionId=" + sessionId, new { energyDeliveredKWh = -1 })).StatusCode == HttpStatusCode.BadRequest, "Negative meter reading rejected");
            const double fixtureEnergy = 5; // API contract input; never represented as real meter telemetry.
            var stopped = await Data(await a.PatchAsJsonAsync("/api/ChargingSession/Stop?sessionId=" + sessionId, new { energyDeliveredKWh = fixtureEnergy }), HttpStatusCode.OK, "Backend confirms Stop");
            Check(stopped.GetProperty("status").GetString() == "Completed" && stopped.GetProperty("totalEnergyConsumedKWh").GetDouble() == fixtureEnergy,
                "Stop response contains persisted energy and Completed");
            var price = await db.SystemConfigurations.AsNoTracking().FirstAsync(c => c.Name == "PRICE_PER_kWH" && !c.IsDeleted);
            var initialCost = stopped.GetProperty("cost").GetDecimal();
            Check(initialCost == (decimal)fixtureEnergy * price.MinValue, "Backend computes cost using configured price");
            await Data(await a.PatchAsJsonAsync("/api/ChargingSession/Stop?sessionId=" + sessionId, new { energyDeliveredKWh = fixtureEnergy }), HttpStatusCode.OK, "Repeated same Stop reconciles without charging twice");

            async Task<Guid> CreateVoucher(bool expired = false) => (await Data(await adminClient.PostAsJsonAsync("/api/Voucher", new {
                name = "Phase4 API fixture", description = "Temporary test DB only", requiredPoints = 0, value = 10,
                voucherType = "Discount", validFrom = DateTime.Now.AddDays(-2), validTo = DateTime.Now.AddDays(expired ? -1 : 2)
            }), HttpStatusCode.OK, expired ? "Create expired eligibility fixture" : "Create voucher fixture via API")).GetProperty("id").GetGuid();
            var voucherId = await CreateVoucher();
            var expiredId = await CreateVoucher(true);
            Check((await a.PostAsync("/api/Voucher/redeem/" + expiredId, null)).StatusCode == HttpStatusCode.Conflict, "Expired voucher cannot be redeemed");
            var redeemed = await Data(await a.PostAsync("/api/Voucher/redeem/" + voucherId, null), HttpStatusCode.OK, "Redeem persists UserVoucher");
            var ownedId = redeemed.GetProperty("id").GetGuid();
            Check((await a.PostAsync("/api/Voucher/redeem/" + voucherId, null)).StatusCode == HttpStatusCode.Conflict, "Duplicate redemption rejected with correct driver ID");
            var mine = await Data(await a.GetAsync("/api/Voucher/my"), HttpStatusCode.OK, "Read own vouchers using account-to-driver mapping");
            Check(mine.EnumerateArray().Any(v => v.GetProperty("id").GetGuid() == ownedId), "Redeemed voucher is visible in my list");
            Check((await b.PostAsync($"/api/Voucher/use/{ownedId}/{sessionId}", null)).StatusCode == HttpStatusCode.NotFound, "Foreign voucher/session application denied");
            await Data(await a.PostAsync($"/api/Voucher/use/{ownedId}/{sessionId}", null), HttpStatusCode.OK, "Voucher applied on backend");
            var afterVoucher = await Data(await a.GetAsync("/api/ChargingSession/" + sessionId), HttpStatusCode.OK, "Read discounted session");
            Check(afterVoucher.GetProperty("cost").GetDecimal() == initialCost * 0.9m, "Discount is persisted in backend, not local state");
            await Data(await a.PostAsync($"/api/Voucher/use/{ownedId}/{sessionId}", null), HttpStatusCode.OK, "Repeated voucher application is idempotent");
            var repeat = await Data(await a.GetAsync("/api/ChargingSession/" + sessionId), HttpStatusCode.OK, "Re-read after voucher retry");
            Check(repeat.GetProperty("cost").GetDecimal() == initialCost * 0.9m, "Discount cannot compound on retry");

            if (sandboxOrigin != null)
            {
                var checkout = await Data(await a.PostAsync("/api/Payment?sessionId=" + sessionId, null),
                    HttpStatusCode.OK, "Backend creates Sandbox checkout on isolated SQL");
                var url = new Uri(checkout.GetString()!);
                Check(url.GetLeftPart(UriPartial.Path) == "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html",
                    "Checkout targets the VNPAY Sandbox endpoint");
                return await SandboxCallback.Run(anonymous, a, sandboxOrigin, sessionId, url, db);
            }

            var methods = await Data(await a.GetAsync("/api/Payment/methods"), HttpStatusCode.OK, "Server payment methods");
            Check(methods.EnumerateArray().Any(m => m.GetProperty("id").GetString() == "SePayTest" && !m.GetProperty("available").GetBoolean()), "Gateway disabled without verified merchant");
            Check((await a.PostAsync("/api/Payment?sessionId=" + sessionId, null)).StatusCode == HttpStatusCode.Conflict, "No fake signed gateway URL when disabled");
            var quote = await Data(await a.GetAsync("/api/Payment/session/" + sessionId), HttpStatusCode.OK, "Server quote before request");
            var expectedAmount = decimal.Round(initialCost * 0.9m * 1.10m, 0, MidpointRounding.AwayFromZero);
            Check(quote.GetProperty("amount").GetDecimal() == expectedAmount, "Server quote is discounted cost plus VAT");
            Check((await b.GetAsync("/api/Payment/session/" + sessionId)).StatusCode == HttpStatusCode.NotFound, "Foreign invoice read denied");
            var offline = await Data(await a.PostAsync("/api/Payment/offline?sessionId=" + sessionId, null), HttpStatusCode.OK, "Backend creates offline pending request");
            var paymentId = offline.GetProperty("id").GetGuid();
            Check(offline.GetProperty("status").GetString() == "Initiated" && offline.GetProperty("amount").GetDecimal() == expectedAmount,
                "Offline request is pending with server amount");
            Check((await a.PostAsync("/api/Payment/offline?sessionId=" + sessionId, null)).StatusCode == HttpStatusCode.Conflict, "Duplicate payment creation rejected");
            var pending = await Data(await a.GetAsync("/api/Payment/session/" + sessionId), HttpStatusCode.OK, "Pending status lookup");
            Check(pending.GetProperty("sessionStatus").GetString() == "Completed" && pending.GetProperty("payment").GetProperty("status").GetString() == "Initiated",
                "Creating a request never marks the session Paid");
            var secondVoucher = await CreateVoucher();
            var secondOwned = (await Data(await a.PostAsync("/api/Voucher/redeem/" + secondVoucher, null), HttpStatusCode.OK, "Redeem another voucher fixture")).GetProperty("id").GetGuid();
            Check((await a.PostAsync($"/api/Voucher/use/{secondOwned}/{sessionId}", null)).StatusCode == HttpStatusCode.Conflict, "Cannot change amount after payment request exists");
            Check((await a.PatchAsync("/api/Payment/offline-status?paymentId=" + paymentId, null)).StatusCode == HttpStatusCode.Forbidden,
                "Driver cannot self-confirm cash received");
            var ipnResponse = await anonymous.GetAsync("/api/Payment/vnpay/ipn?vnp_ResponseCode=00");
            var ipn = await Data(ipnResponse, HttpStatusCode.OK, "IPN returns JSON, never redirect");
            Check(ipn.GetProperty("RspCode").GetString() == "97", "Unsigned callback cannot confirm payment");
            Check((await anonymous.GetAsync("/api/Payment/vnpay/return?vnp_ResponseCode=00")).StatusCode == HttpStatusCode.OK, "Return route exists and is read-only");
            var history = await a.GetAsync("/api/Transaction/evdriver");
            Check(history.StatusCode == HttpStatusCode.NotFound || (await history.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("data").GetArrayLength() == 0,
                "Pending payment is not a completed ledger transaction");
            db.ChangeTracker.Clear();
            Check(await db.Set<Payment>().AnyAsync(p => p.Id == paymentId && p.Status == "Initiated"), "SQL confirms pending payment record");
            Check(!await db.Transactions.AnyAsync(t => t.PaymentId == paymentId), "No fabricated cash/online transaction inserted");
            Check(await db.Set<Connector>().AnyAsync(c => c.Id == connector.Id && c.IsLocked), "Connector stays locked until real settlement");

            // Cryptographic helper unit checks, NOT gateway settlement evidence.
            var signatureFields = new Dictionary<string, string> { ["vnp_OrderInfo"] = "Phi sac & xe", ["vnp_Amount"] = "12300" };
            Check(PaymentHelper.CreateDataString(signatureFields) == "vnp_Amount=12300&vnp_OrderInfo=Phi+sac+%26+xe", "Unit: canonical URL encoding before HMAC");
            const string unitSecret = "Unit-test-only-secret-not-a-merchant-key";
            signatureFields["vnp_SecureHash"] = Convert.ToHexString(HMACSHA512.HashData(Encoding.UTF8.GetBytes(unitSecret), Encoding.UTF8.GetBytes("vnp_Amount=12300&vnp_OrderInfo=Phi+sac+%26+xe")));
            Check(PaymentHelper.VerifySignature(signatureFields, unitSecret), "Unit: correct HMAC accepted");
            signatureFields["vnp_Amount"] = "1";
            Check(!PaymentHelper.VerifySignature(signatureFields, unitSecret), "Unit: tampered amount invalidates signature");
            var staffPage = await Data(await staffClient.GetAsync("/api/Notification?page=1&pageSize=100"), HttpStatusCode.OK, "Offline request creates actual staff notification page");
            Check(staffPage.GetArrayLength() > 0, "Staff receives pending payment notification from backend");
            var notificationId = staffPage[0].GetProperty("id").GetGuid();
            Check(await db.NotificationRecipients.AsNoTracking().AnyAsync(r => r.RecipientId == staff.Id && r.NotificationId == notificationId), "Notification DTO ID is NotificationId, not RecipientId");
            Check((await b.GetAsync("/api/Notification/" + notificationId)).StatusCode == HttpStatusCode.NotFound, "Foreign notification read denied");
            Check((await b.PatchAsync("/api/Notification/" + notificationId + "/read", null)).StatusCode == HttpStatusCode.NotFound, "Foreign notification mutation denied");
            Check((await staffClient.PatchAsync("/api/Notification/" + notificationId + "/read", null)).StatusCode == HttpStatusCode.OK, "Owner mark-read confirmed by backend");
            var refreshedPage = await Data(await staffClient.GetAsync("/api/Notification?page=1&pageSize=100"), HttpStatusCode.OK, "Refresh notifications after mark-read");
            Check(refreshedPage.EnumerateArray().First(n => n.GetProperty("id").GetGuid() == notificationId).GetProperty("isRead").GetBoolean(), "Notification read state survives server reload");

            var outsider = await NewDriver(users, db, password);
            Check((await users.RemoveFromRoleAsync(outsider, "EVDriver")).Succeeded &&
                (await users.AddToRoleAsync(outsider, "Staff")).Succeeded, "Create non-operator Staff fixture");
            using var outsiderClient = await Login(factory, outsider.Email!, password);
            var detailUrl = $"/api/Payment/{paymentId}";
            var confirmUrl = $"/api/Payment/offline-status?paymentId={paymentId}";
            var receipt = new { receivedAmount = expectedAmount };
            Task<HttpResponseMessage> Confirm(HttpClient client) => client.PatchAsJsonAsync(confirmUrl, receipt);
            Check((await staffClient.GetAsync(detailUrl)).StatusCode == HttpStatusCode.OK, "Operator can read payment detail");
            Check((await outsiderClient.GetAsync(detailUrl)).StatusCode == HttpStatusCode.NotFound, "Foreign staff payment IDOR denied");
            Check((await adminClient.GetAsync(detailUrl)).StatusCode == HttpStatusCode.OK, "Admin can audit payment detail");
            var pendingUrl = "/api/Payment?pendingOnly=true";
            var operatorQueue = await Data(await staffClient.GetAsync(pendingUrl), HttpStatusCode.OK, "Operator pending cash queue");
            Check(operatorQueue.EnumerateArray().Any(p => p.GetProperty("id").GetGuid() == paymentId), "Own pending cash appears in operator queue");
            var outsiderQueue = await Data(await outsiderClient.GetAsync(pendingUrl), HttpStatusCode.OK, "Foreign operator queue");
            Check(outsiderQueue.GetArrayLength() == 0, "Foreign payment excluded from queue");
            Check((await Confirm(outsiderClient)).StatusCode == HttpStatusCode.NotFound, "Staff outside station cannot confirm");
            Check((await Confirm(adminClient)).StatusCode == HttpStatusCode.Forbidden, "Admin role alone cannot confirm cash");
            Check((await staffClient.PatchAsJsonAsync(confirmUrl, new { })).StatusCode == HttpStatusCode.BadRequest, "Missing cash amount rejected");
            Check((await staffClient.PatchAsJsonAsync(confirmUrl, new { receivedAmount = expectedAmount + 1 })).StatusCode == HttpStatusCode.Conflict, "Wrong cash amount rejected");

            var currentStaff = await users.FindByIdAsync(staff.Id.ToString()) ?? throw new InvalidOperationException("Missing fixture operator");
            Check((await users.RemoveFromRoleAsync(currentStaff, "Staff")).Succeeded, "Revoke operator Staff role in SQL");
            Check((await Confirm(staffClient)).StatusCode == HttpStatusCode.NotFound, "Previously issued Staff JWT cannot settle after role revocation");
            Check((await users.AddToRoleAsync(currentStaff, "Staff")).Succeeded, "Restore fixture Staff role");
            var cashRow = db.Set<Payment>().Where(p => p.Id == paymentId);
            await cashRow.ExecuteUpdateAsync(p => p.SetProperty(v => v.PaidBy, (Guid?)driverB.Id));
            Check((await Confirm(staffClient)).StatusCode == HttpStatusCode.Conflict, "Mismatched payment and session owner rejected");
            await cashRow.ExecuteUpdateAsync(p => p.SetProperty(v => v.PaidBy, (Guid?)driverA.Id));
            await cashRow.ExecuteUpdateAsync(p => p.SetProperty(v => v.Status, "Cancelled"));
            Check((await Confirm(staffClient)).StatusCode == HttpStatusCode.Conflict, "Terminal payment rejected");
            await cashRow.ExecuteUpdateAsync(p => p.SetProperty(v => v.Status, "Initiated"));

            await db.Database.ExecuteSqlRawAsync("CREATE TRIGGER dbo.Phase6bRejectLedger ON dbo.[Transaction] AFTER INSERT AS THROW 51000, 'Phase6b fixture rejects ledger insert', 1;");
            try
            {
                try
                {
                    var failed = await Confirm(staffClient);
                    Check(failed.StatusCode == HttpStatusCode.InternalServerError, "Ledger insert fault returns HTTP 500");
                }
                catch (Exception ex) when (ex.ToString().Contains("Phase6b fixture rejects ledger insert", StringComparison.Ordinal))
                {
                    Check(true, "Ledger insert fault reaches the test host");
                }
                Check(await cashRow.AnyAsync(p => p.Status == "Initiated") &&
                    await db.ChargingSessions.AnyAsync(s => s.Id == sessionId && s.Status == "Completed") &&
                    await db.Set<Connector>().AnyAsync(c => c.Id == connector.Id && c.IsLocked) &&
                    !await db.Transactions.AnyAsync(t => t.PaymentId == paymentId),
                    "Ledger insert fault rolls back payment, session, connector and ledger");
            }
            finally
            {
                await db.Database.ExecuteSqlRawAsync("DROP TRIGGER dbo.Phase6bRejectLedger;");
            }

            var concurrent = await Task.WhenAll(Confirm(staffClient), Confirm(staffClient));
            Check(concurrent.Count(r => r.StatusCode == HttpStatusCode.OK) == 1 &&
                concurrent.Count(r => r.StatusCode == HttpStatusCode.Conflict) == 1,
                "Concurrent confirmation has one success and one conflict (actual " +
                    string.Join(", ", concurrent.Select(r => (int)r.StatusCode)) + ")");
            Check((await Confirm(staffClient)).StatusCode == HttpStatusCode.Conflict, "Sequential replay rejected");
            var ledger = await db.Transactions.AsNoTracking().SingleAsync(t => t.PaymentId == paymentId);
            Check(ledger.RecordedBy == staff.Id && ledger.PaidBy == driverA.Id && ledger.Amount == expectedAmount &&
                ledger.TransactionType == "OfflinePayment" && ledger.Status == "Completed" && ledger.CompletedAt != null,
                "Exactly one completed ledger has the snapshot amount, customer and recording operator");
            Check(await cashRow.AnyAsync(p => p.Status == "Successed" && p.Amount == expectedAmount) &&
                await db.ChargingSessions.AnyAsync(s => s.Id == sessionId && s.Status == "Paid") &&
                await db.Set<Connector>().AnyAsync(c => c.Id == connector.Id && !c.IsLocked),
                "Settlement commits payment, session and unlocks connector");
            var paid = await Data(await a.GetAsync("/api/Payment/session/" + sessionId), HttpStatusCode.OK, "Customer can verify cash settlement");
            Check(paid.GetProperty("sessionStatus").GetString() == "Paid", "Customer sees server-confirmed Paid");
            var settledQueue = await Data(await staffClient.GetAsync(pendingUrl), HttpStatusCode.OK, "Queue after confirmation");
            Check(!settledQueue.EnumerateArray().Any(p => p.GetProperty("id").GetGuid() == paymentId), "Settled payment removed from pending queue");
            var ledgerUrl = $"/api/Transaction/{ledger.Id}";
            Check((await a.GetAsync(ledgerUrl)).StatusCode == HttpStatusCode.OK, "Customer can read own ledger detail");
            Check((await b.GetAsync(ledgerUrl)).StatusCode == HttpStatusCode.NotFound, "Foreign customer ledger detail denied");
            Check((await staffClient.GetAsync(ledgerUrl)).StatusCode == HttpStatusCode.OK, "Station operator can read ledger detail");
            Check((await outsiderClient.GetAsync(ledgerUrl)).StatusCode == HttpStatusCode.NotFound, "Foreign staff ledger detail denied");
            Check((await adminClient.GetAsync(ledgerUrl)).StatusCode == HttpStatusCode.OK, "Admin can audit ledger detail");
            var customerLedger = await Data(await a.GetAsync("/api/Transaction/evdriver"), HttpStatusCode.OK, "Customer settled history");
            var settledItem = customerLedger.EnumerateArray().Single(t => t.GetProperty("id").GetGuid() == ledger.Id);
            Check(settledItem.GetProperty("chargingSessionId").GetGuid() == sessionId &&
                settledItem.GetProperty("paymentMethod").GetString() == "OFFLINE" &&
                settledItem.GetProperty("paymentStatus").GetString() == "Successed" &&
                settledItem.GetProperty("paymentReference").GetString() == offline.GetProperty("txnRef").GetString(),
                "Customer history includes session, payment method, status and reference");
            Check((await b.GetAsync("/api/Transaction/evdriver")).StatusCode == HttpStatusCode.NotFound, "Foreign customer history excludes ledger");
            var staffLedger = await Data(await staffClient.GetAsync("/api/Transaction"), HttpStatusCode.OK, "Station operator settled history");
            Check(staffLedger.EnumerateArray().Any(t => t.GetProperty("id").GetGuid() == ledger.Id), "Station operator history includes own station");
            Check((await outsiderClient.GetAsync("/api/Transaction")).StatusCode == HttpStatusCode.NotFound, "Foreign staff history excludes ledger");

            Console.WriteLine($"RESULT: {passed} PASS, 0 FAIL. API+SQL fixture environment; 3 checks are HMAC unit checks. No real gateway or physical charging tested.");
            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine("RESULT: " + passed + " PASS, 1 FAIL: " + ex.GetType().Name + ": " + ex.Message);
            return 1;
        }
        finally
        {
            Environment.SetEnvironmentVariable("ConnectionStrings__DefaultConnection", previousConnection);
            Environment.SetEnvironmentVariable("Jwt__Key", previousJwt);
            Environment.SetEnvironmentVariable("VnPay__Enabled", previousVnpay);
            Environment.SetEnvironmentVariable("VnPay__Mode", previousMode);
            Environment.SetEnvironmentVariable("VnPay__IpnUrl", previousIpnUrl);
            Environment.SetEnvironmentVariable("VnPay__ReturnUrl", previousReturnUrl);
            Environment.SetEnvironmentVariable("ASPNETCORE_TEST_CONTENTROOT_APIS", previousRoot);
            if (created && cleanup.Database.GetDbConnection().Database == databaseName && databaseName.StartsWith("EVCSMS_Phase5_", StringComparison.Ordinal))
            {
                await cleanup.Database.EnsureDeletedAsync();
                Console.WriteLine("Temporary test database removed; EVCSMS untouched.");
            }
        }
    }
}

internal sealed class ApiFactory : WebApplicationFactory<global::Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development").UseContentRoot(Path.GetFullPath("APIs"));
        builder.ConfigureLogging(log => log.ClearProviders());
        builder.ConfigureServices(services =>
        {
            // Deterministic fixture tests do not execute scheduled jobs or send mail.
            foreach (var descriptor in services.Where(s => s.ServiceType == typeof(IHostedService) &&
                s.ImplementationType?.Namespace == "BusinessLogic.Jobs").ToList()) services.Remove(descriptor);
        });
    }
}
