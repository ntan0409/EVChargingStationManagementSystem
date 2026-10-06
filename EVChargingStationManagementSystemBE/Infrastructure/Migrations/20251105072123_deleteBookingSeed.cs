using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class deleteBookingSeed : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Booking",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"));

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Booking",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<string>(
                name: "CheckInCode",
                table: "Booking",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "ConnectorId",
                table: "Booking",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "PasswordHash",
                value: "AQAAAAEAACcQAAAAEM1Xyeldl4HuIOaMf7BQdVAlsJeZsckJRwqii7Lw/+qJ1qNg0Q7BS61ODpuUt+/RVQ==");

            migrationBuilder.InsertData(
                table: "ChargingPost",
                columns: new[] { "Id", "AvailableConnectors", "ConnectorType", "CreatedAt", "MaxPowerKw", "PostName", "StationId", "Status", "TotalConnectors", "UpdatedAt", "VehicleTypeSupported" },
                values: new object[] { new Guid("99999999-9999-9999-9999-999999999999"), 2, "Type2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 50, "Post A1", new Guid("55555555-5555-5555-5555-555555555555"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" });

            migrationBuilder.InsertData(
                table: "Connector",
                columns: new[] { "Id", "ChargingPostId", "ConnectorName", "CreatedAt", "IsDeleted", "IsLocked", "IsPluggedIn", "Status", "UpdatedAt" },
                values: new object[] { new Guid("cccccccc-cccc-cccc-cccc-cccccccccccc"), new Guid("99999999-9999-9999-9999-999999999999"), "Connector A1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) });

            migrationBuilder.CreateIndex(
                name: "IX_Booking_ConnectorId",
                table: "Booking",
                column: "ConnectorId");

            migrationBuilder.AddForeignKey(
                name: "FK_Booking_Connector_ConnectorId",
                table: "Booking",
                column: "ConnectorId",
                principalTable: "Connector",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Booking_Connector_ConnectorId",
                table: "Booking");

            migrationBuilder.DropIndex(
                name: "IX_Booking_ConnectorId",
                table: "Booking");

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-cccc-cccc-cccc-cccccccccccc"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("99999999-9999-9999-9999-999999999999"));

            migrationBuilder.DropColumn(
                name: "CheckInCode",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "ConnectorId",
                table: "Booking");

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Booking",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "PasswordHash",
                value: "string");

            migrationBuilder.InsertData(
                table: "Booking",
                columns: new[] { "Id", "ActualEndTime", "ActualEnergyKWh", "ActualStartTime", "BookedBy", "CreatedAt", "CurrentBattery", "EndTime", "EstimatedEnergyKWh", "IsDeleted", "StartTime", "StationId", "Status", "TargetBattery", "UpdatedAt" },
                values: new object[] { new Guid("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"), null, null, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2025, 10, 25, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2025, 10, 26, 11, 0, 0, 0, DateTimeKind.Unspecified), null, false, new DateTime(2025, 10, 26, 9, 0, 0, 0, DateTimeKind.Unspecified), new Guid("55555555-5555-5555-5555-555555555555"), "Scheduled", null, new DateTime(2025, 10, 25, 12, 0, 0, 0, DateTimeKind.Unspecified) });
        }
    }
}
