using KanbanApp.Models.Enums;

namespace KanbanApp.Models;

public class TaskItem
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Priority Priority { get; set; }
    public DateTime? DueDate { get; set; }
    public int Order { get; set; }

    public int ColumnId { get; set; }

    public Column Column { get; set; } = null!;
    public List<Tag> Tags { get; set; } = [];
    public List<ChecklistItem> ChecklistItems { get; set; } = [];

    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}
