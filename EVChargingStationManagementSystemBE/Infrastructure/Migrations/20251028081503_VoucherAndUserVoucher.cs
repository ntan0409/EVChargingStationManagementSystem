using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class VoucherAndUserVoucher : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_EVDriverProfile_Rankings_RankingId",
                table: "EVDriverProfile");

            migrationBuilder.DropTable(
                name: "Rankings");

            migrationBuilder.DropIndex(
                name: "IX_EVDriverProfile_RankingId",
                table: "EVDriverProfile");

            migrationBuilder.DropColumn(
                name: "RankingId",
                table: "EVDriverProfile");

            migrationBuilder.RenameColumn(
                name: "stars",
                table: "Feedbacks",
                newName: "Stars");

            migrationBuilder.RenameColumn(
                name: "Score",
                table: "EVDriverProfile",
                newName: "Point");

            migrationBuilder.AddColumn<bool>(
                name: "IsBookingLocked",
                table: "EVDriverProfile",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "MissedBookingCount",
                table: "EVDriverProfile",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "AspNetUsers",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(255)",
                oldMaxLength: 255);

            migrationBuilder.AddColumn<string>(
                name: "ProviderUserId",
                table: "AspNetUsers",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Vouchers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    RequiredPoints = table.Column<int>(type: "int", nullable: false),
                    Value = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    VoucherType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ValidFrom = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ValidTo = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Vouchers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserVouchers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    EVDriverId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    VoucherId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    StationId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    AssignedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    RedeemDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    UsedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserVouchers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserVouchers_ChargingStation_StationId",
                        column: x => x.StationId,
                        principalTable: "ChargingStation",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_UserVouchers_EVDriverProfile_EVDriverId",
                        column: x => x.EVDriverId,
                        principalTable: "EVDriverProfile",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserVouchers_Vouchers_VoucherId",
                        column: x => x.VoucherId,
                        principalTable: "Vouchers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                columns: new[] { "Address", "Gender", "LockoutEnabled", "Name", "NormalizedUserName", "ProfilePictureUrl", "ProviderUserId", "SecurityStamp" },
                values: new object[] { "Headquarters, Hanoi", "Male", false, "System Admin", "ADMIN@GMAIL.COM", "", null, "9fd925f3-34b4-46ce-971e-e3bcf4884150" });

            migrationBuilder.InsertData(
                table: "AspNetUsers",
                columns: new[] { "Id", "AccessFailedCount", "Address", "ConcurrencyStamp", "CreatedAt", "DateOfBirth", "Email", "EmailConfirmed", "Gender", "IsDeleted", "LastLogin", "LockoutEnabled", "LockoutEnd", "LoginType", "Name", "NormalizedEmail", "NormalizedUserName", "PasswordHash", "PhoneNumber", "PhoneNumberConfirmed", "ProfilePictureUrl", "ProviderUserId", "RegistrationDate", "SecurityStamp", "Status", "TwoFactorEnabled", "UpdatedAt", "UserName" },
                values: new object[,]
                {
                    { new Guid("22222222-2222-2222-2222-222222222222"), 0, "Hanoi Station", "c7e31c5c-f68e-4364-912e-f0e443f8243d", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, "staff1@gmail.com", true, "Male", false, null, false, null, "System", "Station Staff", "STAFF1@GMAIL.COM", "STAFF1@GMAIL.COM", "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==", "0999999999", false, "", null, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "b9a67e8b-2351-4d2b-8ef1-1e908f5b63e1", "Active", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "staff1@gmail.com" },
                    { new Guid("33333333-3333-3333-3333-333333333333"), 0, "Ho Chi Minh City", "b4a5c6d7-e8f9-4012-9abc-de34f56a789b", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, "evdriver@gmail.com", true, "Male", false, null, false, null, "System", "EV Driver", "EVDRIVER@GMAIL.COM", "EVDRIVER@GMAIL.COM", "string", "0987654321", false, "", null, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "ef12cd34-5678-49ab-9012-34ef56ab78cd", "Active", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "evdriver@gmail.com" },
                    { new Guid("44444444-4444-4444-4444-444444444444"), 0, "HCM Station", "a3f4c5b6-d7e8-4a9b-9123-f45678a9b012", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, "staff2@gmail.com", true, "Female", false, null, false, null, "System", "Station Staff", "STAFF2@GMAIL.COM", "STAFF2@GMAIL.COM", "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==", "0123456788", false, "", null, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "d5e67c7a-32d1-4c9b-b61f-6e701c4b2f72", "Active", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "staff2@gmail.com" },
                    { new Guid("77777777-7777-7777-7777-777777777777"), 0, "Da Nang Station", "f1e2d3c4-b5a6-7890-cdef-0987654321ab", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, "operator2@gmail.com", true, "Male", false, null, false, null, "System", "Station Operator 2", "OPERATOR2@GMAIL.COM", "OPERATOR2@GMAIL.COM", "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==", "0888888888", false, "", null, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "a1b2c3d4-e5f6-7890-abcd-1234567890ef", "Active", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "operator2@gmail.com" }
                });

            migrationBuilder.InsertData(
                table: "VehicleModel",
                columns: new[] { "Id", "BatteryCapacityKWh", "Brand", "CreatedAt", "CreatedBy", "ImageUrl", "IsDeleted", "ModelName", "ModelYear", "RecommendedChargingPowerKW", "Status", "UpdatedAt", "VehicleType" },
                values: new object[] { new Guid("11111111-1111-1111-1111-111111111111"), 0, "VinFast", new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), "string", false, "VF8", 0, 0, "Active", new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" });

            migrationBuilder.InsertData(
                table: "AspNetUserRoles",
                columns: new[] { "RoleId", "UserId" },
                values: new object[,]
                {
                    { new Guid("33333333-3333-3333-3333-333333333333"), new Guid("33333333-3333-3333-3333-333333333333") },
                    { new Guid("22222222-2222-2222-2222-222222222222"), new Guid("44444444-4444-4444-4444-444444444444") },
                    { new Guid("22222222-2222-2222-2222-222222222222"), new Guid("77777777-7777-7777-7777-777777777777") }
                });

            migrationBuilder.InsertData(
                table: "ChargingStation",
                columns: new[] { "Id", "AvailableBikeChargingPosts", "AvailableBikeConnectors", "AvailableCarChargingPosts", "AvailableCarConnectors", "CreatedAt", "IsDeleted", "Latitude", "Location", "Longitude", "OperatorId", "Province", "StationName", "Status", "TotalBikeChargingPosts", "TotalBikeConnectors", "TotalCarChargingConnectors", "TotalCarChargingPosts", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("55555555-5555-5555-5555-555555555555"), 5, 10, 3, 6, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "21.0285N", "Hanoi", "105.8542E", new Guid("22222222-2222-2222-2222-222222222222"), "Hanoi", "VinFast Station Hanoi", "Active", 5, 10, 6, 3, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("66666666-6666-6666-6666-666666666666"), 4, 8, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.7769N", "Ho Chi Minh City", "106.7009E", new Guid("77777777-7777-7777-7777-777777777777"), "HCM", "VinFast Station HCM", "Active", 4, 8, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) }
                });

            migrationBuilder.InsertData(
                table: "EVDriverProfile",
                columns: new[] { "Id", "AccountId", "CreatedAt", "IsBookingLocked", "IsDeleted", "MissedBookingCount", "Point", "Status", "UpdatedAt" },
                values: new object[] { new Guid("11111111-1111-1111-1111-111111111111"), new Guid("33333333-3333-3333-3333-333333333333"), new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, 0, 100, "Active", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) });

            migrationBuilder.InsertData(
                table: "SCStaffProfile",
                columns: new[] { "Id", "AccountId", "CreatedAt", "IsDeleted", "Status", "UpdatedAt", "WorkingLocation" },
                values: new object[,]
                {
                    { new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "Active", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Q9 Station" },
                    { new Guid("22222222-2222-2222-2222-222222222222"), new Guid("44444444-4444-4444-4444-444444444444"), new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "Active", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Hanoi Station" },
                    { new Guid("33333333-3333-3333-3333-333333333333"), new Guid("77777777-7777-7777-7777-777777777777"), new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "Active", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "HCM Station" }
                });

            migrationBuilder.InsertData(
                table: "Booking",
                columns: new[] { "Id", "ActualEndTime", "ActualEnergyKWh", "ActualStartTime", "BookedBy", "CreatedAt", "CurrentBattery", "EndTime", "EstimatedEnergyKWh", "IsDeleted", "StartTime", "StationId", "Status", "TargetBattery", "UpdatedAt" },
                values: new object[] { new Guid("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"), null, null, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2025, 10, 25, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2025, 10, 26, 11, 0, 0, 0, DateTimeKind.Unspecified), null, false, new DateTime(2025, 10, 26, 9, 0, 0, 0, DateTimeKind.Unspecified), new Guid("55555555-5555-5555-5555-555555555555"), "Scheduled", null, new DateTime(2025, 10, 25, 12, 0, 0, 0, DateTimeKind.Unspecified) });

            migrationBuilder.InsertData(
                table: "UserVehicle",
                columns: new[] { "DriverId", "VehicleModelId" },
                values: new object[] { new Guid("11111111-1111-1111-1111-111111111111"), new Guid("11111111-1111-1111-1111-111111111111") });

            migrationBuilder.CreateIndex(
                name: "IX_UserVouchers_EVDriverId",
                table: "UserVouchers",
                column: "EVDriverId");

            migrationBuilder.CreateIndex(
                name: "IX_UserVouchers_StationId",
                table: "UserVouchers",
                column: "StationId");

            migrationBuilder.CreateIndex(
                name: "IX_UserVouchers_VoucherId",
                table: "UserVouchers",
                column: "VoucherId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserVouchers");

            migrationBuilder.DropTable(
                name: "Vouchers");

            migrationBuilder.DeleteData(
                table: "AspNetUserRoles",
                keyColumns: new[] { "RoleId", "UserId" },
                keyValues: new object[] { new Guid("33333333-3333-3333-3333-333333333333"), new Guid("33333333-3333-3333-3333-333333333333") });

            migrationBuilder.DeleteData(
                table: "AspNetUserRoles",
                keyColumns: new[] { "RoleId", "UserId" },
                keyValues: new object[] { new Guid("22222222-2222-2222-2222-222222222222"), new Guid("44444444-4444-4444-4444-444444444444") });

            migrationBuilder.DeleteData(
                table: "AspNetUserRoles",
                keyColumns: new[] { "RoleId", "UserId" },
                keyValues: new object[] { new Guid("22222222-2222-2222-2222-222222222222"), new Guid("77777777-7777-7777-7777-777777777777") });

            migrationBuilder.DeleteData(
                table: "Booking",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"));

            migrationBuilder.DeleteData(
                table: "SCStaffProfile",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "SCStaffProfile",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"));

            migrationBuilder.DeleteData(
                table: "SCStaffProfile",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"));

            migrationBuilder.DeleteData(
                table: "UserVehicle",
                keyColumns: new[] { "DriverId", "VehicleModelId" },
                keyValues: new object[] { new Guid("11111111-1111-1111-1111-111111111111"), new Guid("11111111-1111-1111-1111-111111111111") });

            migrationBuilder.DeleteData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"));

            migrationBuilder.DeleteData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("77777777-7777-7777-7777-777777777777"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"));

            migrationBuilder.DeleteData(
                table: "EVDriverProfile",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "VehicleModel",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"));

            migrationBuilder.DeleteData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"));

            migrationBuilder.DropColumn(
                name: "IsBookingLocked",
                table: "EVDriverProfile");

            migrationBuilder.DropColumn(
                name: "MissedBookingCount",
                table: "EVDriverProfile");

            migrationBuilder.DropColumn(
                name: "ProviderUserId",
                table: "AspNetUsers");

            migrationBuilder.RenameColumn(
                name: "Stars",
                table: "Feedbacks",
                newName: "stars");

            migrationBuilder.RenameColumn(
                name: "Point",
                table: "EVDriverProfile",
                newName: "Score");

            migrationBuilder.AddColumn<Guid>(
                name: "RankingId",
                table: "EVDriverProfile",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "AspNetUsers",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(255)",
                oldMaxLength: 255,
                oldNullable: true);

            migrationBuilder.CreateTable(
                name: "Rankings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    DiscountPercentage = table.Column<int>(type: "int", nullable: false),
                    MinPoints = table.Column<int>(type: "int", nullable: false),
                    RankName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Rankings", x => x.Id);
                });

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                columns: new[] { "Address", "Gender", "LockoutEnabled", "Name", "NormalizedUserName", "ProfilePictureUrl", "SecurityStamp" },
                values: new object[] { null, null, true, "Admin", null, null, "b0a67e8b-2351-4d2b-8ef1-1e908f5b63e1" });

            migrationBuilder.CreateIndex(
                name: "IX_EVDriverProfile_RankingId",
                table: "EVDriverProfile",
                column: "RankingId");

            migrationBuilder.AddForeignKey(
                name: "FK_EVDriverProfile_Rankings_RankingId",
                table: "EVDriverProfile",
                column: "RankingId",
                principalTable: "Rankings",
                principalColumn: "Id");
        }
    }
}
