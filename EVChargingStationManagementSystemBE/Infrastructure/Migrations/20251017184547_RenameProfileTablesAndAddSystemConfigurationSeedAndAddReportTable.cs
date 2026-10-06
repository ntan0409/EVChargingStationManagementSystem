using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RenameProfileTablesAndAddSystemConfigurationSeedAndAddReportTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserVehicle_EVDriver_DriverId",
                table: "UserVehicle");

            migrationBuilder.DropTable(
                name: "EVDriver");

            migrationBuilder.DropTable(
                name: "PowerOutputKWPerPosts");

            migrationBuilder.DropTable(
                name: "SCStaff");

            migrationBuilder.DropTable(
                name: "PowerOutputsKW");

            migrationBuilder.DeleteData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"));

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "SystemConfiguration");

            migrationBuilder.DropColumn(
                name: "Operator",
                table: "SystemConfiguration");

            migrationBuilder.DropColumn(
                name: "RuleGroup",
                table: "SystemConfiguration");

            migrationBuilder.DropColumn(
                name: "ScopeType",
                table: "SystemConfiguration");

            migrationBuilder.DropColumn(
                name: "Severity",
                table: "SystemConfiguration");

            migrationBuilder.DropColumn(
                name: "TargetEntity",
                table: "SystemConfiguration");

            migrationBuilder.DropColumn(
                name: "TargetField",
                table: "SystemConfiguration");

            migrationBuilder.RenameColumn(
                name: "TotalChargingPost",
                table: "ChargingStation",
                newName: "TotalCarChargingPosts");

            migrationBuilder.RenameColumn(
                name: "AvailableChargers",
                table: "ChargingStation",
                newName: "TotalCarChargingConnectors");

            migrationBuilder.RenameColumn(
                name: "ChargerType",
                table: "ChargingPost",
                newName: "VehicleTypeSupported");

            migrationBuilder.AddColumn<int>(
                name: "AvailableBikeChargingPosts",
                table: "ChargingStation",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "AvailableBikeConnectors",
                table: "ChargingStation",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "AvailableCarChargingPosts",
                table: "ChargingStation",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "AvailableCarConnectors",
                table: "ChargingStation",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TotalBikeChargingPosts",
                table: "ChargingStation",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TotalBikeConnectors",
                table: "ChargingStation",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<Guid>(
                name: "ConnectorId",
                table: "ChargingSession",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<int>(
                name: "AvailableConnectors",
                table: "ChargingPost",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "ConnectorType",
                table: "ChargingPost",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "MaxPowerKw",
                table: "ChargingPost",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TotalConnectors",
                table: "ChargingPost",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "ActualEndTime",
                table: "Booking",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "ActualEnergyKWh",
                table: "Booking",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ActualStartTime",
                table: "Booking",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "CurrentBattery",
                table: "Booking",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "EstimatedEnergyKWh",
                table: "Booking",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "TargetBattery",
                table: "Booking",
                type: "float",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "PhoneNumber",
                table: "AspNetUsers",
                type: "nvarchar(450)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.CreateTable(
                name: "Connector",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ConnectorName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    ChargingPostId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Connector", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Connector_ChargingPost_ChargingPostId",
                        column: x => x.ChargingPostId,
                        principalTable: "ChargingPost",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "EVDriverProfile",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Score = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    AccountId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RankingId = table.Column<Guid>(type: "uniqueidentifier", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EVDriverProfile", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EVDriverProfile_AspNetUsers_AccountId",
                        column: x => x.AccountId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EVDriverProfile_Rankings_RankingId",
                        column: x => x.RankingId,
                        principalTable: "Rankings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "SCStaffProfile",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    WorkingLocation = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    AccountId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SCStaffProfile", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SCStaffProfile_AspNetUsers_AccountId",
                        column: x => x.AccountId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "PhoneNumber",
                value: "0123456789");

            migrationBuilder.InsertData(
                table: "SystemConfiguration",
                columns: new[] { "Id", "CreatedAt", "CreatedBy", "Description", "EffectedDateFrom", "EffectedDateTo", "IsDeleted", "MaxValue", "MinValue", "Name", "Unit", "UpdatedAt", "UpdatedBy", "VersionNo" },
                values: new object[,]
                {
                    { 1, new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), "Mức giá vnd trên 1 KWH điện, giá trị chỉ hiệu lực khi lưu ở trường MinValue", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, false, null, 5000m, "PRICE_PER_kWH", "VND", new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), 1 },
                    { 2, new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), "Tích điểm trên 1 KWH điện, giá trị chỉ hiệu lực khi lưu ở trường MinValue", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, false, null, 1m, "POINT_PER_KWH", "point", new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), 1 },
                    { 3, new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), "Mức thuế, giá trị chỉ hiệu lực khi lưu ở trường MinValue", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, false, null, 10m, "VAT", "%", new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), 1 },
                    { 4, new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), "Thời gian token login hiệu lực, giá trị chỉ hiệu lực khi lưu ở trường MinValue", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, false, null, 720m, "LOGIN_TOKEN_TIMEOUT", "Hours", new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), 1 },
                    { 5, new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), "Thời gian cancel booking nếu đến trễ hơn thời gian đặt ra, giá trị chỉ hiệu lực khi lưu ở trường MinValue", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, false, null, 15m, "BOOKING_TIME_CANCEL_TRIGGER", "Minutes", new DateTime(2024, 6, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), 1 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChargingSession_ConnectorId",
                table: "ChargingSession",
                column: "ConnectorId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUsers_PhoneNumber",
                table: "AspNetUsers",
                column: "PhoneNumber",
                unique: true,
                filter: "[PhoneNumber] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Connector_ChargingPostId",
                table: "Connector",
                column: "ChargingPostId");

            migrationBuilder.CreateIndex(
                name: "IX_EVDriverProfile_AccountId",
                table: "EVDriverProfile",
                column: "AccountId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_EVDriverProfile_RankingId",
                table: "EVDriverProfile",
                column: "RankingId");

            migrationBuilder.CreateIndex(
                name: "IX_SCStaffProfile_AccountId",
                table: "SCStaffProfile",
                column: "AccountId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_ChargingSession_Connector_ConnectorId",
                table: "ChargingSession",
                column: "ConnectorId",
                principalTable: "Connector",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_UserVehicle_EVDriverProfile_DriverId",
                table: "UserVehicle",
                column: "DriverId",
                principalTable: "EVDriverProfile",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ChargingSession_Connector_ConnectorId",
                table: "ChargingSession");

            migrationBuilder.DropForeignKey(
                name: "FK_UserVehicle_EVDriverProfile_DriverId",
                table: "UserVehicle");

            migrationBuilder.DropTable(
                name: "Connector");

            migrationBuilder.DropTable(
                name: "EVDriverProfile");

            migrationBuilder.DropTable(
                name: "SCStaffProfile");

            migrationBuilder.DropIndex(
                name: "IX_ChargingSession_ConnectorId",
                table: "ChargingSession");

            migrationBuilder.DropIndex(
                name: "IX_AspNetUsers_PhoneNumber",
                table: "AspNetUsers");

            migrationBuilder.DeleteData(
                table: "SystemConfiguration",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "SystemConfiguration",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "SystemConfiguration",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "SystemConfiguration",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "SystemConfiguration",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DropColumn(
                name: "AvailableBikeChargingPosts",
                table: "ChargingStation");

            migrationBuilder.DropColumn(
                name: "AvailableBikeConnectors",
                table: "ChargingStation");

            migrationBuilder.DropColumn(
                name: "AvailableCarChargingPosts",
                table: "ChargingStation");

            migrationBuilder.DropColumn(
                name: "AvailableCarConnectors",
                table: "ChargingStation");

            migrationBuilder.DropColumn(
                name: "TotalBikeChargingPosts",
                table: "ChargingStation");

            migrationBuilder.DropColumn(
                name: "TotalBikeConnectors",
                table: "ChargingStation");

            migrationBuilder.DropColumn(
                name: "ConnectorId",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "AvailableConnectors",
                table: "ChargingPost");

            migrationBuilder.DropColumn(
                name: "ConnectorType",
                table: "ChargingPost");

            migrationBuilder.DropColumn(
                name: "MaxPowerKw",
                table: "ChargingPost");

            migrationBuilder.DropColumn(
                name: "TotalConnectors",
                table: "ChargingPost");

            migrationBuilder.DropColumn(
                name: "ActualEndTime",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "ActualEnergyKWh",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "ActualStartTime",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "CurrentBattery",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "EstimatedEnergyKWh",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "TargetBattery",
                table: "Booking");

            migrationBuilder.RenameColumn(
                name: "TotalCarChargingPosts",
                table: "ChargingStation",
                newName: "TotalChargingPost");

            migrationBuilder.RenameColumn(
                name: "TotalCarChargingConnectors",
                table: "ChargingStation",
                newName: "AvailableChargers");

            migrationBuilder.RenameColumn(
                name: "VehicleTypeSupported",
                table: "ChargingPost",
                newName: "ChargerType");

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "SystemConfiguration",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Operator",
                table: "SystemConfiguration",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "RuleGroup",
                table: "SystemConfiguration",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ScopeType",
                table: "SystemConfiguration",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Severity",
                table: "SystemConfiguration",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "TargetEntity",
                table: "SystemConfiguration",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "TargetField",
                table: "SystemConfiguration",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AlterColumn<string>(
                name: "PhoneNumber",
                table: "AspNetUsers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)",
                oldNullable: true);

            migrationBuilder.CreateTable(
                name: "EVDriver",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AccountId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RankingId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    Score = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EVDriver", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EVDriver_AspNetUsers_AccountId",
                        column: x => x.AccountId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EVDriver_Rankings_RankingId",
                        column: x => x.RankingId,
                        principalTable: "Rankings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "PowerOutputsKW",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    Value = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PowerOutputsKW", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SCStaff",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AccountId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    WorkingLocation = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SCStaff", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SCStaff_AspNetUsers_AccountId",
                        column: x => x.AccountId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PowerOutputKWPerPosts",
                columns: table => new
                {
                    ChargingPostId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PowerOutputKWId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PowerOutputKWPerPosts", x => new { x.ChargingPostId, x.PowerOutputKWId });
                    table.ForeignKey(
                        name: "FK_PowerOutputKWPerPosts_ChargingPost_ChargingPostId",
                        column: x => x.ChargingPostId,
                        principalTable: "ChargingPost",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PowerOutputKWPerPosts_PowerOutputsKW_PowerOutputKWId",
                        column: x => x.PowerOutputKWId,
                        principalTable: "PowerOutputsKW",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "PhoneNumber",
                value: null);

            migrationBuilder.InsertData(
                table: "AspNetUsers",
                columns: new[] { "Id", "AccessFailedCount", "Address", "ConcurrencyStamp", "CreatedAt", "DateOfBirth", "Email", "EmailConfirmed", "Gender", "IsDeleted", "LastLogin", "LockoutEnabled", "LockoutEnd", "LoginType", "Name", "NormalizedEmail", "NormalizedUserName", "PasswordHash", "PhoneNumber", "PhoneNumberConfirmed", "ProfilePictureUrl", "RegistrationDate", "SecurityStamp", "Status", "TwoFactorEnabled", "UpdatedAt", "UserName" },
                values: new object[] { new Guid("22222222-2222-2222-2222-222222222222"), 0, null, "26aff629-ed41-424c-986c-bec9fb174ae6", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, "staff@gmail.com", true, null, false, null, true, null, "System", "Staff", "STAFF@GMAIL.COM", null, "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==", null, false, null, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "142fa5de-d603-4453-81f9-5c9347280452", "Active", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "staff@gmail.com" });

            migrationBuilder.CreateIndex(
                name: "IX_EVDriver_AccountId",
                table: "EVDriver",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_EVDriver_RankingId",
                table: "EVDriver",
                column: "RankingId");

            migrationBuilder.CreateIndex(
                name: "IX_PowerOutputKWPerPosts_PowerOutputKWId",
                table: "PowerOutputKWPerPosts",
                column: "PowerOutputKWId");

            migrationBuilder.CreateIndex(
                name: "IX_SCStaff_AccountId",
                table: "SCStaff",
                column: "AccountId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserVehicle_EVDriver_DriverId",
                table: "UserVehicle",
                column: "DriverId",
                principalTable: "EVDriver",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
