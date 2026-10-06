using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FixReportRelationship : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reports_ChargingPost_ChargingPostNavigationId",
                table: "Reports");

            migrationBuilder.DropIndex(
                name: "IX_Reports_ChargingPostNavigationId",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "ChargingPostNavigationId",
                table: "Reports");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_PostId",
                table: "Reports",
                column: "PostId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_ChargingPost_PostId",
                table: "Reports",
                column: "PostId",
                principalTable: "ChargingPost",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reports_ChargingPost_PostId",
                table: "Reports");

            migrationBuilder.DropIndex(
                name: "IX_Reports_PostId",
                table: "Reports");

            migrationBuilder.AddColumn<Guid>(
                name: "ChargingPostNavigationId",
                table: "Reports",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_Reports_ChargingPostNavigationId",
                table: "Reports",
                column: "ChargingPostNavigationId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_ChargingPost_ChargingPostNavigationId",
                table: "Reports",
                column: "ChargingPostNavigationId",
                principalTable: "ChargingPost",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
