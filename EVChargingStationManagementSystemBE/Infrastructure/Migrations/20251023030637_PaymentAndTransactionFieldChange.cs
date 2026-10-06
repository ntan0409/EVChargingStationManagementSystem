using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class PaymentAndTransactionFieldChange : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Transaction_ChargingSession_ChargingSessionId",
                table: "Transaction");

            migrationBuilder.RenameColumn(
                name: "ChargingSessionId",
                table: "Transaction",
                newName: "PaymentId");

            migrationBuilder.RenameIndex(
                name: "IX_Transaction_ChargingSessionId",
                table: "Transaction",
                newName: "IX_Transaction_PaymentId");

            migrationBuilder.AlterColumn<Guid>(
                name: "PaidBy",
                table: "Transaction",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AddColumn<string>(
                name: "ReferenceCode",
                table: "Transaction",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<bool>(
                name: "IsLocked",
                table: "Connector",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsPluggedIn",
                table: "Connector",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "Payment",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    TaxRate = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    BeforeVatAmount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    PaymentMethod = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    BankCode = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    TxnRef = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    ChargingSessionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PaidBy = table.Column<Guid>(type: "uniqueidentifier", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Payment", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Payment_AspNetUsers_PaidBy",
                        column: x => x.PaidBy,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Payment_ChargingSession_ChargingSessionId",
                        column: x => x.ChargingSessionId,
                        principalTable: "ChargingSession",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Payment_ChargingSessionId",
                table: "Payment",
                column: "ChargingSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_Payment_PaidBy",
                table: "Payment",
                column: "PaidBy");

            migrationBuilder.AddForeignKey(
                name: "FK_Transaction_Payment_PaymentId",
                table: "Transaction",
                column: "PaymentId",
                principalTable: "Payment",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Transaction_Payment_PaymentId",
                table: "Transaction");

            migrationBuilder.DropTable(
                name: "Payment");

            migrationBuilder.DropColumn(
                name: "ReferenceCode",
                table: "Transaction");

            migrationBuilder.DropColumn(
                name: "IsLocked",
                table: "Connector");

            migrationBuilder.DropColumn(
                name: "IsPluggedIn",
                table: "Connector");

            migrationBuilder.RenameColumn(
                name: "PaymentId",
                table: "Transaction",
                newName: "ChargingSessionId");

            migrationBuilder.RenameIndex(
                name: "IX_Transaction_PaymentId",
                table: "Transaction",
                newName: "IX_Transaction_ChargingSessionId");

            migrationBuilder.AlterColumn<Guid>(
                name: "PaidBy",
                table: "Transaction",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Transaction_ChargingSession_ChargingSessionId",
                table: "Transaction",
                column: "ChargingSessionId",
                principalTable: "ChargingSession",
                principalColumn: "Id");
        }
    }
}
