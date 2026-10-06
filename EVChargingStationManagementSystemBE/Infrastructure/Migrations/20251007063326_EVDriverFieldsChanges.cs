using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class EVDriverFieldsChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_EVDriver_Rankings_RankingId",
                table: "EVDriver");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "EVDriver");

            migrationBuilder.AlterColumn<Guid>(
                name: "RankingId",
                table: "EVDriver",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "EVDriver",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddForeignKey(
                name: "FK_EVDriver_Rankings_RankingId",
                table: "EVDriver",
                column: "RankingId",
                principalTable: "Rankings",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_EVDriver_Rankings_RankingId",
                table: "EVDriver");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "EVDriver");

            migrationBuilder.AlterColumn<Guid>(
                name: "RankingId",
                table: "EVDriver",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "EVDriver",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddForeignKey(
                name: "FK_EVDriver_Rankings_RankingId",
                table: "EVDriver",
                column: "RankingId",
                principalTable: "Rankings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
