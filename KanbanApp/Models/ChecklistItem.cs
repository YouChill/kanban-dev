namespace KanbanApp.Models;

public class ChecklistItem
{
    public int Id { get; set; }
    public string Text { get; set; } = string.Empty;
    public bool IsDone { get; set; }

    public int TaskItemId { get; set; }

    public TaskItem TaskItem { get; set; } = null!;
}
