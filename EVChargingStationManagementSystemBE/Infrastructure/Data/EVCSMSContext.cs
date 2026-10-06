#nullable disable
using Infrastructure.Data.Seed;
using Infrastructure.Models;
using Infrastructure.ModelsConfig;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Infrastructure.Data
{
    public class EVCSMSContext : IdentityDbContext<UserAccount, Role, Guid>
    {
        public EVCSMSContext() { }
        public EVCSMSContext(DbContextOptions<EVCSMSContext> options) : base(options) { }

        public DbSet<UserAccount> UserAccounts { get; set; }
        public DbSet<EVDriverProfile> EVDrivers { get; set; }
        //public DbSet<Ranking> Rankings { get; set; }
        public DbSet<UserVehicle> UserVehicles { get; set; }
        public DbSet<VehicleModel> VehicleModels { get; set; }
        public DbSet<ChargingStation> ChargingStations { get; set; }
        public DbSet<SCStaffProfile> SCStaffs { get; set; }
        public DbSet<Booking> Bookings { get; set; }
        public DbSet<ChargingPost> ChargingPosts { get; set; }
        public DbSet<ChargingSession> ChargingSessions { get; set; }
        public DbSet<Transaction> Transactions { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<NotificationRecipient> NotificationRecipients { get; set; }
        public DbSet<SystemConfiguration> SystemConfigurations { get; set; }
        public DbSet<Report> Reports { get; set; }
        public DbSet<Feedback> Feedbacks { get; set; }
        public DbSet<Voucher> Vouchers { get; set; }
        public DbSet<UserVoucher> UserVouchers { get; set; }        

        public static string GetConnectionString(string connectionStringName)
        {
            var config = new ConfigurationBuilder()
                .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
                .AddJsonFile("appsettings.json")
                .Build();

            string connectionString = config.GetConnectionString(connectionStringName);

            return connectionString;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
            => optionsBuilder.UseSqlServer(GetConnectionString("DefaultConnection"));

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            builder.ApplyConfiguration(new SystemConfigurationConfig());
            builder.ApplyConfiguration(new BookingConfig());
            builder.ApplyConfiguration(new ChargingStationConfig());
            builder.ApplyConfiguration(new ChargingPostConfig());
            builder.ApplyConfiguration(new NotificationConfig());
            builder.ApplyConfiguration(new NotificationRecipientConfig());
            builder.ApplyConfiguration(new UserVehicleConfig());
            builder.ApplyConfiguration(new VehicleModelConfig());
            builder.ApplyConfiguration(new ChargingSessionConfig());
            builder.ApplyConfiguration(new TransactionConfig());
            builder.ApplyConfiguration(new SCStaffConfig());
            builder.ApplyConfiguration(new EVDriverConfig());
            builder.ApplyConfiguration(new UserAccountConfig());
            builder.ApplyConfiguration(new PaymentConfig());

            // Seed data
            //builder.ApplyConfiguration(new RoleSeed());
            //builder.ApplyConfiguration(new UserAccountSeed());
            //builder.ApplyConfiguration(new UserRolesSeed());

            builder.Entity<Role>().HasData(RoleSeed.GetRoles());
            builder.Entity<VehicleModel>().HasData(VehicleModelSeed.GetVehicleModels());
            builder.Entity<UserAccount>().HasData(UserAccountSeed.GetUserAccounts());
            builder.Entity<SystemConfiguration>().HasData(SystemConfigurationSeed.GetSystemConfigurations());
            builder.Entity<IdentityUserRole<Guid>>().HasData(UserRolesSeed.GetUserRoles());
            builder.Entity<UserVehicle>().HasData(UserVehicleSeed.GetUserVehicles());
            builder.Entity<EVDriverProfile>().HasData(EVDriverSeed.GetEVDrivers());
            builder.Entity<ChargingStation>().HasData(ChargingStationSeed.GetChargingStations());
            builder.Entity<SCStaffProfile>().HasData(SCStaffSeed.GetSCStaffs());
            builder.Entity<ChargingPost>().HasData(ChargingPostSeed.GetChargingPosts());
            builder.Entity<Connector>().HasData(ConnectorSeed.GetConnectors());
            //builder.Entity<Booking>().HasData(BookingSeed.GetBookings());
        }
    }
}
