using Microsoft.EntityFrameworkCore;
using KanbanApp.Models;
using KanbanApp.Models.Enums;

namespace KanbanApp.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Board> Boards => Set<Board>();
    public DbSet<Column> Columns => Set<Column>();
    public DbSet<TaskItem> TaskItems => Set<TaskItem>();
    public DbSet<Tag> Tags => Set<Tag>();
    public DbSet<ChecklistItem> ChecklistItems => Set<ChecklistItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Board
        modelBuilder.Entity<Board>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(e => e.Description)
                .HasMaxLength(1000);

            entity.Property(e => e.CreatedAt)
                .IsRequired();
        });

        // Column
        modelBuilder.Entity<Column>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(e => e.Color)
                .HasMaxLength(50);

            entity.Property(e => e.Order)
                .IsRequired();

            entity.HasOne(e => e.Board)
                .WithMany(b => b.Columns)
                .HasForeignKey(e => e.BoardId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(e => e.BoardId);
            entity.HasIndex(e => e.Order);
        });

        // TaskItem
        modelBuilder.Entity<TaskItem>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.Property(e => e.Title)
                .IsRequired()
                .HasMaxLength(500);

            entity.Property(e => e.Description)
                .HasMaxLength(4000);

            entity.Property(e => e.Priority)
                .IsRequired();

            entity.Property(e => e.Order)
                .IsRequired();

            entity.Property(e => e.CreatedAt)
                .IsRequired();

            entity.HasOne(e => e.Column)
                .WithMany(c => c.Tasks)
                .HasForeignKey(e => e.ColumnId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(e => e.ColumnId);
            entity.HasIndex(e => e.Order);
        });

        // Tag
        modelBuilder.Entity<Tag>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(e => e.Color)
                .HasMaxLength(50);

            entity.HasMany(e => e.Tasks)
                .WithMany(t => t.Tags)
                .UsingEntity(j =>
                {
                    j.ToTable("TaskItemTag");
                    j.HasData(
                        new { TasksId = 1, TagsId = 5 },  // CI/CD ← devops
                        new { TasksId = 1, TagsId = 6 },  // CI/CD ← setup
                        new { TasksId = 3, TagsId = 2 },  // Login ← frontend
                        new { TasksId = 3, TagsId = 4 }   // Login ← design
                    );
                });
        });

        // ChecklistItem
        modelBuilder.Entity<ChecklistItem>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.Property(e => e.Text)
                .IsRequired()
                .HasMaxLength(500);

            entity.Property(e => e.IsDone)
                .IsRequired()
                .HasDefaultValue(false);

            entity.HasOne(e => e.TaskItem)
                .WithMany(t => t.ChecklistItems)
                .HasForeignKey(e => e.TaskItemId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        SeedData(modelBuilder);
    }

    private static void SeedData(ModelBuilder modelBuilder)
    {
        // Board
        modelBuilder.Entity<Board>().HasData(
            new Board
            {
                Id = 1,
                Name = "Demo Board",
                Description = "Przykładowa tablica do testowania funkcjonalności kanban",
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }
        );

        // Columns
        modelBuilder.Entity<Column>().HasData(
            new { Id = 1, Name = "Do zrobienia", Color = "#6366f1", Order = 0, BoardId = 1 },
            new { Id = 2, Name = "W toku", Color = "#f59e0b", Order = 1, WipLimit = (int?)3, BoardId = 1 },
            new { Id = 3, Name = "Gotowe", Color = "#22c55e", Order = 2, BoardId = 1 }
        );

        // Tags
        modelBuilder.Entity<Tag>().HasData(
            new Tag { Id = 1, Name = "backend",  Color = "#3b82f6" },
            new Tag { Id = 2, Name = "frontend", Color = "#6366f1" },
            new Tag { Id = 3, Name = "db",       Color = "#8b5cf6" },
            new Tag { Id = 4, Name = "design",   Color = "#ec4899" },
            new Tag { Id = 5, Name = "devops",   Color = "#16a34a" },
            new Tag { Id = 6, Name = "setup",    Color = "#d97706" },
            new Tag { Id = 7, Name = "testing",  Color = "#0891b2" }
        );

        // Tasks
        modelBuilder.Entity<TaskItem>().HasData(
            new
            {
                Id = 1,
                Title = "Skonfigurować CI/CD pipeline",
                Description = (string?)"Ustawić GitHub Actions dla automatycznego budowania i testów",
                Priority = Priority.High,
                Order = 0,
                ColumnId = 1,
                CreatedAt = new DateTime(2026, 1, 1, 10, 0, 0, DateTimeKind.Utc)
            },
            new
            {
                Id = 2,
                Title = "Zaprojektować schemat bazy danych",
                Description = (string?)"Utworzyć diagram ERD i zdefiniować relacje między tabelami",
                Priority = Priority.Critical,
                Order = 1,
                ColumnId = 1,
                CreatedAt = new DateTime(2026, 1, 2, 9, 0, 0, DateTimeKind.Utc),
                DueDate = (DateTime?)new DateTime(2026, 2, 15, 0, 0, 0, DateTimeKind.Utc)
            },
            new
            {
                Id = 3,
                Title = "Zaimplementować stronę logowania",
                Description = (string?)"Formularz logowania z walidacją i obsługą błędów",
                Priority = Priority.Medium,
                Order = 0,
                ColumnId = 2,
                CreatedAt = new DateTime(2026, 1, 3, 14, 0, 0, DateTimeKind.Utc)
            },
            new
            {
                Id = 4,
                Title = "Dodać testy jednostkowe dla modeli",
                Description = (string?)null,
                Priority = Priority.Low,
                Order = 0,
                ColumnId = 3,
                CreatedAt = new DateTime(2026, 1, 1, 8, 0, 0, DateTimeKind.Utc),
                CompletedAt = (DateTime?)new DateTime(2026, 1, 5, 16, 0, 0, DateTimeKind.Utc)
            }
        );

        // Checklist items (on Task 2)
        modelBuilder.Entity<ChecklistItem>().HasData(
            new ChecklistItem { Id = 1, Text = "Zidentyfikować encje",  IsDone = true,  TaskItemId = 2 },
            new ChecklistItem { Id = 2, Text = "Narysować diagram ERD", IsDone = true,  TaskItemId = 2 },
            new ChecklistItem { Id = 3, Text = "Zdefiniować indeksy",   IsDone = false, TaskItemId = 2 }
        );

    }
}
