using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSessionIdToUserVoucher : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserVouchers_ChargingStation_StationId",
                table: "UserVouchers");

            migrationBuilder.DropIndex(
                name: "IX_UserVouchers_StationId",
                table: "UserVouchers");

            migrationBuilder.AddColumn<Guid>(
                name: "ChargingStationId",
                table: "UserVouchers",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "SessionId",
                table: "UserVouchers",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserVouchers_ChargingStationId",
                table: "UserVouchers",
                column: "ChargingStationId");

            migrationBuilder.CreateIndex(
                name: "IX_UserVouchers_SessionId",
                table: "UserVouchers",
                column: "SessionId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserVouchers_ChargingSession_SessionId",
                table: "UserVouchers",
                column: "SessionId",
                principalTable: "ChargingSession",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserVouchers_ChargingStation_ChargingStationId",
                table: "UserVouchers",
                column: "ChargingStationId",
                principalTable: "ChargingStation",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserVouchers_ChargingSession_SessionId",
                table: "UserVouchers");

            migrationBuilder.DropForeignKey(
                name: "FK_UserVouchers_ChargingStation_ChargingStationId",
                table: "UserVouchers");

            migrationBuilder.DropIndex(
                name: "IX_UserVouchers_ChargingStationId",
                table: "UserVouchers");

            migrationBuilder.DropIndex(
                name: "IX_UserVouchers_SessionId",
                table: "UserVouchers");

            migrationBuilder.DropColumn(
                name: "ChargingStationId",
                table: "UserVouchers");

            migrationBuilder.DropColumn(
                name: "SessionId",
                table: "UserVouchers");

            migrationBuilder.CreateIndex(
                name: "IX_UserVouchers_StationId",
                table: "UserVouchers",
                column: "StationId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserVouchers_ChargingStation_StationId",
                table: "UserVouchers",
                column: "StationId",
                principalTable: "ChargingStation",
                principalColumn: "Id");
        }
    }
}
