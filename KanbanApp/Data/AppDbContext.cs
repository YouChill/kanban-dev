using Microsoft.EntityFrameworkCore;
using KanbanApp.Models;

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
                .UsingEntity(j => j.ToTable("TaskItemTag"));
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
    }
}
