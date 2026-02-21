using KanbanApp.Models;
using KanbanApp.Models.Enums;

namespace KanbanApp.Services.Interfaces;

public interface ITaskService
{
    Task<TaskItem?> GetTaskByIdAsync(int id);
    Task<TaskItem> CreateTaskAsync(int columnId, string title, Priority priority);
    Task<TaskItem?> UpdateTaskAsync(TaskItem task);
    Task<bool> DeleteTaskAsync(int id);
    Task<bool> MoveTaskAsync(int taskId, int targetColumnId, int? newOrder);
    Task<bool> CanMoveToColumnAsync(int columnId);

    Task<ChecklistItem> AddChecklistItemAsync(int taskId, string text);
    Task<bool> UpdateChecklistItemAsync(ChecklistItem item);
    Task<bool> DeleteChecklistItemAsync(int id);
}
