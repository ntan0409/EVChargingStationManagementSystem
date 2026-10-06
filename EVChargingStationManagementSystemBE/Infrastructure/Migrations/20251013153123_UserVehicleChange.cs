using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UserVehicleChange : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ChargingSession_AspNetUsers_StartedBy",
                table: "ChargingSession");

            migrationBuilder.DropForeignKey(
                name: "FK_ChargingSession_UserVehicle_UserVehicleId",
                table: "ChargingSession");

            migrationBuilder.DropForeignKey(
                name: "FK_UserVehicle_AspNetUsers_UserAccountId",
                table: "UserVehicle");

            migrationBuilder.DropForeignKey(
                name: "FK_UserVehicle_EVDriver_DriverId",
                table: "UserVehicle");

            migrationBuilder.DropPrimaryKey(
                name: "PK_UserVehicle",
                table: "UserVehicle");

            migrationBuilder.DropIndex(
                name: "IX_UserVehicle_DriverId",
                table: "UserVehicle");

            migrationBuilder.DropIndex(
                name: "IX_UserVehicle_UserAccountId",
                table: "UserVehicle");

            migrationBuilder.DropIndex(
                name: "IX_ChargingStation_OperatorId",
                table: "ChargingStation");

            migrationBuilder.DropIndex(
                name: "IX_ChargingSession_StartedBy",
                table: "ChargingSession");

            migrationBuilder.DropIndex(
                name: "IX_ChargingSession_UserVehicleId",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "Id",
                table: "UserVehicle");

            migrationBuilder.DropColumn(
                name: "UserAccountId",
                table: "UserVehicle");

            migrationBuilder.DropColumn(
                name: "StartedBy",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "UserVehicleId",
                table: "ChargingSession");

            migrationBuilder.AlterColumn<DateTime>(
                name: "StartTime",
                table: "ChargingSession",
                type: "datetime2",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AddColumn<int>(
                name: "BatteryCapacityKWh",
                table: "ChargingSession",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<Guid>(
                name: "DriverId",
                table: "ChargingSession",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ExpectedEnergiesKWh",
                table: "ChargingSession",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "InitialBatteryLevelPercent",
                table: "ChargingSession",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "PowerRateKW",
                table: "ChargingSession",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "ChargingSession",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "VehicleModelId",
                table: "ChargingSession",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_UserVehicle",
                table: "UserVehicle",
                columns: new[] { "DriverId", "VehicleModelId" });

            migrationBuilder.CreateIndex(
                name: "IX_ChargingStation_OperatorId",
                table: "ChargingStation",
                column: "OperatorId",
                unique: true,
                filter: "[OperatorId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_ChargingSession_DriverId_VehicleModelId",
                table: "ChargingSession",
                columns: new[] { "DriverId", "VehicleModelId" });

            migrationBuilder.CreateIndex(
                name: "IX_ChargingSession_UserId",
                table: "ChargingSession",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_ChargingSession_AspNetUsers_UserId",
                table: "ChargingSession",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ChargingSession_UserVehicle_DriverId_VehicleModelId",
                table: "ChargingSession",
                columns: new[] { "DriverId", "VehicleModelId" },
                principalTable: "UserVehicle",
                principalColumns: new[] { "DriverId", "VehicleModelId" },
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserVehicle_EVDriver_DriverId",
                table: "UserVehicle",
                column: "DriverId",
                principalTable: "EVDriver",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ChargingSession_AspNetUsers_UserId",
                table: "ChargingSession");

            migrationBuilder.DropForeignKey(
                name: "FK_ChargingSession_UserVehicle_DriverId_VehicleModelId",
                table: "ChargingSession");

            migrationBuilder.DropForeignKey(
                name: "FK_UserVehicle_EVDriver_DriverId",
                table: "UserVehicle");

            migrationBuilder.DropPrimaryKey(
                name: "PK_UserVehicle",
                table: "UserVehicle");

            migrationBuilder.DropIndex(
                name: "IX_ChargingStation_OperatorId",
                table: "ChargingStation");

            migrationBuilder.DropIndex(
                name: "IX_ChargingSession_DriverId_VehicleModelId",
                table: "ChargingSession");

            migrationBuilder.DropIndex(
                name: "IX_ChargingSession_UserId",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "BatteryCapacityKWh",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "DriverId",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "ExpectedEnergiesKWh",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "InitialBatteryLevelPercent",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "PowerRateKW",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "ChargingSession");

            migrationBuilder.DropColumn(
                name: "VehicleModelId",
                table: "ChargingSession");

            migrationBuilder.AddColumn<Guid>(
                name: "Id",
                table: "UserVehicle",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "UserAccountId",
                table: "UserVehicle",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "StartTime",
                table: "ChargingSession",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "StartedBy",
                table: "ChargingSession",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "UserVehicleId",
                table: "ChargingSession",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddPrimaryKey(
                name: "PK_UserVehicle",
                table: "UserVehicle",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_UserVehicle_DriverId",
                table: "UserVehicle",
                column: "DriverId");

            migrationBuilder.CreateIndex(
                name: "IX_UserVehicle_UserAccountId",
                table: "UserVehicle",
                column: "UserAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_ChargingStation_OperatorId",
                table: "ChargingStation",
                column: "OperatorId");

            migrationBuilder.CreateIndex(
                name: "IX_ChargingSession_StartedBy",
                table: "ChargingSession",
                column: "StartedBy");

            migrationBuilder.CreateIndex(
                name: "IX_ChargingSession_UserVehicleId",
                table: "ChargingSession",
                column: "UserVehicleId");

            migrationBuilder.AddForeignKey(
                name: "FK_ChargingSession_AspNetUsers_StartedBy",
                table: "ChargingSession",
                column: "StartedBy",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ChargingSession_UserVehicle_UserVehicleId",
                table: "ChargingSession",
                column: "UserVehicleId",
                principalTable: "UserVehicle",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserVehicle_AspNetUsers_UserAccountId",
                table: "UserVehicle",
                column: "UserAccountId",
                principalTable: "AspNetUsers",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserVehicle_EVDriver_DriverId",
                table: "UserVehicle",
                column: "DriverId",
                principalTable: "EVDriver",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
