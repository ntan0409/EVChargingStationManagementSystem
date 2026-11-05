using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMoreHcmChargingStations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ChargingStation_OperatorId",
                table: "ChargingStation");

            migrationBuilder.UpdateData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("99999999-9999-9999-9999-999999999999"),
                column: "PostName",
                value: "Post A1 (Car 50kW)");

            migrationBuilder.InsertData(
                table: "ChargingPost",
                columns: new[] { "Id", "AvailableConnectors", "ConnectorType", "CreatedAt", "MaxPowerKw", "PostName", "StationId", "Status", "TotalConnectors", "UpdatedAt", "VehicleTypeSupported" },
                values: new object[,]
                {
                    { new Guid("20000000-0000-0000-0000-000000000001"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("66666666-6666-6666-6666-666666666666"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000002"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 120, "Trụ Ô tô 2 (120kW SuperCharge)", new Guid("66666666-6666-6666-6666-666666666666"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" }
                });

            migrationBuilder.UpdateData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                columns: new[] { "AvailableBikeChargingPosts", "AvailableBikeConnectors", "AvailableCarChargingPosts", "AvailableCarConnectors", "Location", "TotalBikeChargingPosts", "TotalBikeConnectors", "TotalCarChargingConnectors", "TotalCarChargingPosts" },
                values: new object[] { 0, 0, 1, 2, "Hanoi Center", 0, 0, 2, 1 });

            migrationBuilder.UpdateData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                columns: new[] { "AvailableCarChargingPosts", "AvailableCarConnectors", "Latitude", "Location", "Longitude", "Province", "StationName", "TotalCarChargingConnectors", "TotalCarChargingPosts" },
                values: new object[] { 2, 4, "10.7781N", "72 Lê Thánh Tôn, Bến Nghé, Quận 1, TP. Hồ Chí Minh", "106.7018E", "TP. Hồ Chí Minh", "Trạm Sạc Vincom Đồng Khởi - Quận 1", 4, 2 });

            migrationBuilder.InsertData(
                table: "ChargingStation",
                columns: new[] { "Id", "AvailableBikeChargingPosts", "AvailableBikeConnectors", "AvailableCarChargingPosts", "AvailableCarConnectors", "CreatedAt", "IsDeleted", "Latitude", "Location", "Longitude", "OperatorId", "Province", "StationName", "Status", "TotalBikeChargingPosts", "TotalBikeConnectors", "TotalCarChargingConnectors", "TotalCarChargingPosts", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("10000000-0000-0000-0000-000000000001"), 1, 2, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.7950N", "720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP. Hồ Chí Minh", "106.7218E", new Guid("44444444-4444-4444-4444-444444444444"), "TP. Hồ Chí Minh", "Trạm Sạc Landmark 81 - Bình Thạnh", "Active", 1, 2, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("10000000-0000-0000-0000-000000000002"), 1, 2, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.7293N", "101 Tôn Dật Tiên, Tân Phú, Quận 7, TP. Hồ Chí Minh", "106.7196E", new Guid("77777777-7777-7777-7777-777777777777"), "TP. Hồ Chí Minh", "Trạm Sạc Crescent Mall Phú Mỹ Hưng - Quận 7", "Active", 1, 2, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("10000000-0000-0000-0000-000000000003"), 0, 0, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.8142N", "60A Trường Sơn, Phường 2, Tân Bình, TP. Hồ Chí Minh", "106.6625E", new Guid("22222222-2222-2222-2222-222222222222"), "TP. Hồ Chí Minh", "Trạm Sạc Menas Mall Sân Bay - Tân Bình", "Active", 0, 0, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("10000000-0000-0000-0000-000000000004"), 1, 2, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.8034N", "161 Xa Lộ Hà Nội, Thảo Điền, TP. Thủ Đức, TP. Hồ Chí Minh", "106.7389E", new Guid("44444444-4444-4444-4444-444444444444"), "TP. Hồ Chí Minh", "Trạm Sạc Vincom Mega Mall Thảo Điền - TP. Thủ Đức", "Active", 1, 2, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("10000000-0000-0000-0000-000000000005"), 1, 2, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.8415N", "Đường D1, Khu Công Nghệ Cao, Long Thạnh Mỹ, TP. Thủ Đức, TP. Hồ Chí Minh", "106.8098E", new Guid("77777777-7777-7777-7777-777777777777"), "TP. Hồ Chí Minh", "Trạm Sạc Khu Công Nghệ Cao FPT - TP. Thủ Đức", "Active", 1, 2, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("10000000-0000-0000-0000-000000000006"), 0, 0, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.7712N", "11 Sư Vạn Hạnh, Phường 12, Quận 10, TP. Hồ Chí Minh", "106.6698E", new Guid("22222222-2222-2222-2222-222222222222"), "TP. Hồ Chí Minh", "Trạm Sạc Vạn Hạnh Mall - Quận 10", "Active", 0, 0, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("10000000-0000-0000-0000-000000000007"), 1, 2, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.7435N", "Số 1 Đường Số 17A, Bình Trị Đông B, Bình Tân, TP. Hồ Chí Minh", "106.6125E", new Guid("44444444-4444-4444-4444-444444444444"), "TP. Hồ Chí Minh", "Trạm Sạc Aeon Mall Bình Tân", "Active", 1, 2, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("10000000-0000-0000-0000-000000000008"), 0, 0, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.8285N", "240-242 Phạm Văn Đồng, Hiệp Bình Chánh, TP. Thủ Đức, TP. Hồ Chí Minh", "106.7235E", new Guid("77777777-7777-7777-7777-777777777777"), "TP. Hồ Chí Minh", "Trạm Sạc Giga Mall Phạm Văn Đồng - TP. Thủ Đức", "Active", 0, 0, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("10000000-0000-0000-0000-000000000009"), 0, 0, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.8289N", "12 Phan Văn Trị, Phường 7, Gò Vấp, TP. Hồ Chí Minh", "106.6892E", new Guid("22222222-2222-2222-2222-222222222222"), "TP. Hồ Chí Minh", "Trạm Sạc Vincom Plaza Phan Văn Trị - Gò Vấp", "Active", 0, 0, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("10000000-0000-0000-0000-000000000010"), 0, 0, 2, 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, "10.7685N", "3 Hòa Bình, Phường 3, Quận 11, TP. Hồ Chí Minh", "106.6375E", new Guid("44444444-4444-4444-4444-444444444444"), "TP. Hồ Chí Minh", "Trạm Sạc Đầm Sen Park - Quận 11", "Active", 0, 0, 4, 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) }
                });

            migrationBuilder.UpdateData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-cccc-cccc-cccc-cccccccccccc"),
                column: "ConnectorName",
                value: "Cổng sạc A1");

            migrationBuilder.InsertData(
                table: "Connector",
                columns: new[] { "Id", "ChargingPostId", "ConnectorName", "CreatedAt", "IsDeleted", "IsLocked", "IsPluggedIn", "Status", "UpdatedAt" },
                values: new object[] { new Guid("cccccccc-cccc-cccc-cccc-cccccccccccd"), new Guid("99999999-9999-9999-9999-999999999999"), "Cổng sạc A2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) });

            migrationBuilder.InsertData(
                table: "ChargingPost",
                columns: new[] { "Id", "AvailableConnectors", "ConnectorType", "CreatedAt", "MaxPowerKw", "PostName", "StationId", "Status", "TotalConnectors", "UpdatedAt", "VehicleTypeSupported" },
                values: new object[,]
                {
                    { new Guid("20000000-0000-0000-0000-000000000003"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000001"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000004"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 150, "Trụ Ô tô 2 (150kW UltraFast)", new Guid("10000000-0000-0000-0000-000000000001"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000005"), 2, "Type2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 7, "Trụ Xe Máy 1 (7kW)", new Guid("10000000-0000-0000-0000-000000000001"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bike" },
                    { new Guid("20000000-0000-0000-0000-000000000006"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000002"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000007"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 120, "Trụ Ô tô 2 (120kW SuperCharge)", new Guid("10000000-0000-0000-0000-000000000002"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000008"), 2, "Type2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 7, "Trụ Xe Máy 1 (7kW)", new Guid("10000000-0000-0000-0000-000000000002"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bike" },
                    { new Guid("20000000-0000-0000-0000-000000000009"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000003"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-00000000000a"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 120, "Trụ Ô tô 2 (120kW SuperCharge)", new Guid("10000000-0000-0000-0000-000000000003"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-00000000000b"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000004"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-00000000000c"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 150, "Trụ Ô tô 2 (150kW UltraFast)", new Guid("10000000-0000-0000-0000-000000000004"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-00000000000d"), 2, "Type2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 7, "Trụ Xe Máy 1 (7kW)", new Guid("10000000-0000-0000-0000-000000000004"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bike" },
                    { new Guid("20000000-0000-0000-0000-00000000000e"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000005"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-00000000000f"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 120, "Trụ Ô tô 2 (120kW SuperCharge)", new Guid("10000000-0000-0000-0000-000000000005"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000010"), 2, "Type2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 7, "Trụ Xe Máy 1 (7kW)", new Guid("10000000-0000-0000-0000-000000000005"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bike" },
                    { new Guid("20000000-0000-0000-0000-000000000011"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000006"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000012"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 120, "Trụ Ô tô 2 (120kW SuperCharge)", new Guid("10000000-0000-0000-0000-000000000006"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000013"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000007"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000014"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 120, "Trụ Ô tô 2 (120kW SuperCharge)", new Guid("10000000-0000-0000-0000-000000000007"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000015"), 2, "Type2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 7, "Trụ Xe Máy 1 (7kW)", new Guid("10000000-0000-0000-0000-000000000007"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bike" },
                    { new Guid("20000000-0000-0000-0000-000000000016"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000008"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000017"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 150, "Trụ Ô tô 2 (150kW UltraFast)", new Guid("10000000-0000-0000-0000-000000000008"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000018"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000009"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-000000000019"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 120, "Trụ Ô tô 2 (120kW SuperCharge)", new Guid("10000000-0000-0000-0000-000000000009"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-00000000001a"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 60, "Trụ Ô tô 1 (60kW)", new Guid("10000000-0000-0000-0000-000000000010"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" },
                    { new Guid("20000000-0000-0000-0000-00000000001b"), 2, "CCS2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 120, "Trụ Ô tô 2 (120kW SuperCharge)", new Guid("10000000-0000-0000-0000-000000000010"), "Available", 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "Car" }
                });

            migrationBuilder.InsertData(
                table: "Connector",
                columns: new[] { "Id", "ChargingPostId", "ConnectorName", "CreatedAt", "IsDeleted", "IsLocked", "IsPluggedIn", "Status", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("30000000-0000-0000-0000-000000000001"), new Guid("20000000-0000-0000-0000-000000000001"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000002"), new Guid("20000000-0000-0000-0000-000000000001"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000003"), new Guid("20000000-0000-0000-0000-000000000002"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000004"), new Guid("20000000-0000-0000-0000-000000000002"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000005"), new Guid("20000000-0000-0000-0000-000000000003"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000006"), new Guid("20000000-0000-0000-0000-000000000003"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000007"), new Guid("20000000-0000-0000-0000-000000000004"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000008"), new Guid("20000000-0000-0000-0000-000000000004"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000009"), new Guid("20000000-0000-0000-0000-000000000005"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000000a"), new Guid("20000000-0000-0000-0000-000000000005"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000000b"), new Guid("20000000-0000-0000-0000-000000000006"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000000c"), new Guid("20000000-0000-0000-0000-000000000006"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000000d"), new Guid("20000000-0000-0000-0000-000000000007"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000000e"), new Guid("20000000-0000-0000-0000-000000000007"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000000f"), new Guid("20000000-0000-0000-0000-000000000008"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000010"), new Guid("20000000-0000-0000-0000-000000000008"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000011"), new Guid("20000000-0000-0000-0000-000000000009"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000012"), new Guid("20000000-0000-0000-0000-000000000009"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000013"), new Guid("20000000-0000-0000-0000-00000000000a"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000014"), new Guid("20000000-0000-0000-0000-00000000000a"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000015"), new Guid("20000000-0000-0000-0000-00000000000b"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000016"), new Guid("20000000-0000-0000-0000-00000000000b"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000017"), new Guid("20000000-0000-0000-0000-00000000000c"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000018"), new Guid("20000000-0000-0000-0000-00000000000c"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000019"), new Guid("20000000-0000-0000-0000-00000000000d"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000001a"), new Guid("20000000-0000-0000-0000-00000000000d"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000001b"), new Guid("20000000-0000-0000-0000-00000000000e"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000001c"), new Guid("20000000-0000-0000-0000-00000000000e"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000001d"), new Guid("20000000-0000-0000-0000-00000000000f"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000001e"), new Guid("20000000-0000-0000-0000-00000000000f"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000001f"), new Guid("20000000-0000-0000-0000-000000000010"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000020"), new Guid("20000000-0000-0000-0000-000000000010"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000021"), new Guid("20000000-0000-0000-0000-000000000011"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000022"), new Guid("20000000-0000-0000-0000-000000000011"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000023"), new Guid("20000000-0000-0000-0000-000000000012"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000024"), new Guid("20000000-0000-0000-0000-000000000012"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000025"), new Guid("20000000-0000-0000-0000-000000000013"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000026"), new Guid("20000000-0000-0000-0000-000000000013"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000027"), new Guid("20000000-0000-0000-0000-000000000014"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000028"), new Guid("20000000-0000-0000-0000-000000000014"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000029"), new Guid("20000000-0000-0000-0000-000000000015"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000002a"), new Guid("20000000-0000-0000-0000-000000000015"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000002b"), new Guid("20000000-0000-0000-0000-000000000016"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000002c"), new Guid("20000000-0000-0000-0000-000000000016"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000002d"), new Guid("20000000-0000-0000-0000-000000000017"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000002e"), new Guid("20000000-0000-0000-0000-000000000017"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-00000000002f"), new Guid("20000000-0000-0000-0000-000000000018"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000030"), new Guid("20000000-0000-0000-0000-000000000018"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000031"), new Guid("20000000-0000-0000-0000-000000000019"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000032"), new Guid("20000000-0000-0000-0000-000000000019"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000033"), new Guid("20000000-0000-0000-0000-00000000001a"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000034"), new Guid("20000000-0000-0000-0000-00000000001a"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000035"), new Guid("20000000-0000-0000-0000-00000000001b"), "Cổng sạc 1", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) },
                    { new Guid("30000000-0000-0000-0000-000000000036"), new Guid("20000000-0000-0000-0000-00000000001b"), "Cổng sạc 2", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), false, false, false, "Available", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified) }
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChargingStation_OperatorId",
                table: "ChargingStation",
                column: "OperatorId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ChargingStation_OperatorId",
                table: "ChargingStation");

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000001"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000002"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000003"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000004"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000005"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000006"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000007"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000008"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000009"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000000a"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000000b"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000000c"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000000d"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000000e"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000000f"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000010"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000011"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000012"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000013"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000014"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000015"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000016"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000017"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000018"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000019"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000001a"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000001b"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000001c"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000001d"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000001e"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000001f"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000020"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000021"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000022"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000023"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000024"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000025"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000026"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000027"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000028"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000029"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000002a"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000002b"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000002c"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000002d"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000002e"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-00000000002f"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000030"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000031"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000032"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000033"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000034"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000035"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000036"));

            migrationBuilder.DeleteData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-cccc-cccc-cccc-cccccccccccd"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000001"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000002"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000003"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000004"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000005"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000006"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000007"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000008"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000009"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-00000000000a"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-00000000000b"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-00000000000c"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-00000000000d"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-00000000000e"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-00000000000f"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000010"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000011"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000012"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000013"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000014"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000015"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000016"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000017"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000018"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000019"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-00000000001a"));

            migrationBuilder.DeleteData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-00000000001b"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000001"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000002"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000003"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000004"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000005"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000006"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000007"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000008"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000009"));

            migrationBuilder.DeleteData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000010"));

            migrationBuilder.UpdateData(
                table: "ChargingPost",
                keyColumn: "Id",
                keyValue: new Guid("99999999-9999-9999-9999-999999999999"),
                column: "PostName",
                value: "Post A1");

            migrationBuilder.UpdateData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                columns: new[] { "AvailableBikeChargingPosts", "AvailableBikeConnectors", "AvailableCarChargingPosts", "AvailableCarConnectors", "Location", "TotalBikeChargingPosts", "TotalBikeConnectors", "TotalCarChargingConnectors", "TotalCarChargingPosts" },
                values: new object[] { 5, 10, 3, 6, "Hanoi", 5, 10, 6, 3 });

            migrationBuilder.UpdateData(
                table: "ChargingStation",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                columns: new[] { "AvailableCarChargingPosts", "AvailableCarConnectors", "Latitude", "Location", "Longitude", "Province", "StationName", "TotalCarChargingConnectors", "TotalCarChargingPosts" },
                values: new object[] { 0, 0, "10.7769N", "Ho Chi Minh City", "106.7009E", "HCM", "VinFast Station HCM", 0, 0 });

            migrationBuilder.UpdateData(
                table: "Connector",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-cccc-cccc-cccc-cccccccccccc"),
                column: "ConnectorName",
                value: "Connector A1");

            migrationBuilder.CreateIndex(
                name: "IX_ChargingStation_OperatorId",
                table: "ChargingStation",
                column: "OperatorId",
                unique: true,
                filter: "[OperatorId] IS NOT NULL");
        }
    }
}
