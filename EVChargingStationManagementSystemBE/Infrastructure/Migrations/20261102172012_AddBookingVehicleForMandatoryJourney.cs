using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddBookingVehicleForMandatoryJourney : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "VehicleModelId",
                table: "Booking",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Booking_VehicleModelId",
                table: "Booking",
                column: "VehicleModelId");

            migrationBuilder.AddForeignKey(
                name: "FK_Booking_VehicleModel_VehicleModelId",
                table: "Booking",
                column: "VehicleModelId",
                principalTable: "VehicleModel",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Booking_VehicleModel_VehicleModelId",
                table: "Booking");

            migrationBuilder.DropIndex(
                name: "IX_Booking_VehicleModelId",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "VehicleModelId",
                table: "Booking");
        }
    }
}
