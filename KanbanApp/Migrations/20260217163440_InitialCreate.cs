using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace KanbanApp.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Boards",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Boards", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Tags",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    Color = table.Column<string>(type: "TEXT", maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Tags", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Columns",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Color = table.Column<string>(type: "TEXT", maxLength: 50, nullable: true),
                    Order = table.Column<int>(type: "INTEGER", nullable: false),
                    WipLimit = table.Column<int>(type: "INTEGER", nullable: true),
                    BoardId = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Columns", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Columns_Boards_BoardId",
                        column: x => x.BoardId,
                        principalTable: "Boards",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TaskItems",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn)
                        .Annotation("Sqlite:Autoincrement", true),
                    Title = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 4000, nullable: true),
                    Priority = table.Column<int>(type: "INTEGER", nullable: false),
                    DueDate = table.Column<DateTime>(type: "TEXT", nullable: true),
                    Order = table.Column<int>(type: "INTEGER", nullable: false),
                    ColumnId = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TaskItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TaskItems_Columns_ColumnId",
                        column: x => x.ColumnId,
                        principalTable: "Columns",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ChecklistItems",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn)
                        .Annotation("Sqlite:Autoincrement", true),
                    Text = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    IsDone = table.Column<bool>(type: "INTEGER", nullable: false, defaultValue: false),
                    TaskItemId = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChecklistItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChecklistItems_TaskItems_TaskItemId",
                        column: x => x.TaskItemId,
                        principalTable: "TaskItems",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TaskItemTag",
                columns: table => new
                {
                    TagsId = table.Column<int>(type: "INTEGER", nullable: false),
                    TasksId = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TaskItemTag", x => new { x.TagsId, x.TasksId });
                    table.ForeignKey(
                        name: "FK_TaskItemTag_Tags_TagsId",
                        column: x => x.TagsId,
                        principalTable: "Tags",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TaskItemTag_TaskItems_TasksId",
                        column: x => x.TasksId,
                        principalTable: "TaskItems",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Boards",
                columns: new[] { "Id", "CreatedAt", "Description", "Name" },
                values: new object[] { 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Przykładowa tablica do testowania funkcjonalności kanban", "Demo Board" });

            migrationBuilder.InsertData(
                table: "Tags",
                columns: new[] { "Id", "Color", "Name" },
                values: new object[,]
                {
                    { 1, "#3b82f6", "backend" },
                    { 2, "#6366f1", "frontend" },
                    { 3, "#8b5cf6", "db" },
                    { 4, "#ec4899", "design" },
                    { 5, "#16a34a", "devops" },
                    { 6, "#d97706", "setup" },
                    { 7, "#0891b2", "testing" }
                });

            migrationBuilder.InsertData(
                table: "Columns",
                columns: new[] { "Id", "BoardId", "Color", "Name", "Order", "WipLimit" },
                values: new object[,]
                {
                    { 1, 1, "#6366f1", "Do zrobienia", 0, null },
                    { 2, 1, "#f59e0b", "W toku", 1, 3 },
                    { 3, 1, "#22c55e", "Gotowe", 2, null }
                });

            migrationBuilder.InsertData(
                table: "TaskItems",
                columns: new[] { "Id", "ColumnId", "CompletedAt", "CreatedAt", "Description", "DueDate", "Order", "Priority", "Title" },
                values: new object[,]
                {
                    { 1, 1, null, new DateTime(2026, 1, 1, 10, 0, 0, 0, DateTimeKind.Utc), "Ustawić GitHub Actions dla automatycznego budowania i testów", null, 0, 2, "Skonfigurować CI/CD pipeline" },
                    { 2, 1, null, new DateTime(2026, 1, 2, 9, 0, 0, 0, DateTimeKind.Utc), "Utworzyć diagram ERD i zdefiniować relacje między tabelami", new DateTime(2026, 2, 15, 0, 0, 0, 0, DateTimeKind.Utc), 1, 3, "Zaprojektować schemat bazy danych" },
                    { 3, 2, null, new DateTime(2026, 1, 3, 14, 0, 0, 0, DateTimeKind.Utc), "Formularz logowania z walidacją i obsługą błędów", null, 0, 1, "Zaimplementować stronę logowania" },
                    { 4, 3, new DateTime(2026, 1, 5, 16, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 1, 8, 0, 0, 0, DateTimeKind.Utc), null, null, 0, 0, "Dodać testy jednostkowe dla modeli" }
                });

            migrationBuilder.InsertData(
                table: "ChecklistItems",
                columns: new[] { "Id", "IsDone", "TaskItemId", "Text" },
                values: new object[,]
                {
                    { 1, true, 2, "Zidentyfikować encje" },
                    { 2, true, 2, "Narysować diagram ERD" }
                });

            migrationBuilder.InsertData(
                table: "ChecklistItems",
                columns: new[] { "Id", "TaskItemId", "Text" },
                values: new object[] { 3, 2, "Zdefiniować indeksy" });

            migrationBuilder.InsertData(
                table: "TaskItemTag",
                columns: new[] { "TagsId", "TasksId" },
                values: new object[,]
                {
                    { 2, 3 },
                    { 4, 3 },
                    { 5, 1 },
                    { 6, 1 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChecklistItems_TaskItemId",
                table: "ChecklistItems",
                column: "TaskItemId");

            migrationBuilder.CreateIndex(
                name: "IX_Columns_BoardId",
                table: "Columns",
                column: "BoardId");

            migrationBuilder.CreateIndex(
                name: "IX_Columns_Order",
                table: "Columns",
                column: "Order");

            migrationBuilder.CreateIndex(
                name: "IX_TaskItems_ColumnId",
                table: "TaskItems",
                column: "ColumnId");

            migrationBuilder.CreateIndex(
                name: "IX_TaskItems_Order",
                table: "TaskItems",
                column: "Order");

            migrationBuilder.CreateIndex(
                name: "IX_TaskItemTag_TasksId",
                table: "TaskItemTag",
                column: "TasksId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ChecklistItems");

            migrationBuilder.DropTable(
                name: "TaskItemTag");

            migrationBuilder.DropTable(
                name: "Tags");

            migrationBuilder.DropTable(
                name: "TaskItems");

            migrationBuilder.DropTable(
                name: "Columns");

            migrationBuilder.DropTable(
                name: "Boards");
        }
    }
}
