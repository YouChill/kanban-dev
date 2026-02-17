namespace KanbanApp.Models;

public class Column
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Color { get; set; }
    public int Order { get; set; }
    public int? WipLimit { get; set; }

    public int BoardId { get; set; }

    public Board Board { get; set; } = null!;
    public List<TaskItem> Tasks { get; set; } = [];
}
