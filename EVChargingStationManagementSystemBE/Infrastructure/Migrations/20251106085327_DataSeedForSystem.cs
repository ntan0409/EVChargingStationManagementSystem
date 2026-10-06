using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DataSeedForSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "Name",
                value: "Tran Thanh Tung ");

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                columns: new[] { "Name", "Status" },
                values: new object[] { "Nguyen Le Phuc Du", "Assigned" });

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "Name",
                value: "Pham Le Xuan Bac");

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "Name",
                value: "Dao Duy Le");

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("77777777-7777-7777-7777-777777777777"),
                columns: new[] { "Name", "Status" },
                values: new object[] { "Tran Minh Tu", "Assigned" });

            migrationBuilder.UpdateData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                columns: new[] { "AvailableBikeChargingPosts", "AvailableBikeConnectors", "AvailableCarChargingPosts", "AvailableCarConnectors", "TotalBikeChargingPosts", "TotalBikeConnectors", "TotalCarChargingConnectors", "TotalCarChargingPosts" },
                values: new object[] { 0, 0, 0, 0, 0, 0, 0, 0 });

            migrationBuilder.InsertData(
                table: "SystemConfiguration",
                columns: new[] { "Id", "CreatedAt", "CreatedBy", "Description", "EffectedDateFrom", "EffectedDateTo", "IsDeleted", "MaxValue", "MinValue", "Name", "Unit", "UpdatedAt", "UpdatedBy", "VersionNo" },
                values: new object[] { 6, new DateTime(2024, 11, 6, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), "Giới hạn tổng lượng cổng trên 1  trụ ", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), null, false, null, 2m, "CONNECTOR_LIMIT", "port", new DateTime(2024, 11, 6, 0, 0, 0, 0, DateTimeKind.Unspecified), new Guid("11111111-1111-1111-1111-111111111111"), 1 });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "SystemConfiguration",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "Name",
                value: "System Admin");

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                columns: new[] { "Name", "Status" },
                values: new object[] { "Station Staff", "Active" });

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "Name",
                value: "EV Driver");

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "Name",
                value: "Station Staff");

            migrationBuilder.UpdateData(
                table: "AspNetUsers",
                keyColumn: "Id",
                keyValue: new Guid("77777777-7777-7777-7777-777777777777"),
                columns: new[] { "Name", "Status" },
                values: new object[] { "Station Operator 2", "Active" });

            migrationBuilder.UpdateData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                columns: new[] { "AvailableBikeChargingPosts", "AvailableBikeConnectors", "AvailableCarChargingPosts", "AvailableCarConnectors", "TotalBikeChargingPosts", "TotalBikeConnectors", "TotalCarChargingConnectors", "TotalCarChargingPosts" },
                values: new object[] { 4, 8, 2, 4, 4, 8, 4, 2 });
        }
    }
}
