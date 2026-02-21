using KanbanApp.Data;
using KanbanApp.Models;
using KanbanApp.Models.Enums;
using KanbanApp.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace KanbanApp.Services;

public class TaskService : ITaskService
{
    private readonly AppDbContext _db;
    private readonly ILogger<TaskService> _logger;

    public TaskService(AppDbContext db, ILogger<TaskService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<TaskItem?> GetTaskByIdAsync(int id)
    {
        try
        {
            return await _db.TaskItems
                .Include(t => t.Tags)
                .Include(t => t.ChecklistItems)
                .FirstOrDefaultAsync(t => t.Id == id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving task {TaskId}", id);
            throw;
        }
    }

    public async Task<TaskItem> CreateTaskAsync(int columnId, string title, Priority priority)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(title);

        try
        {
            var maxOrder = await _db.TaskItems
                .Where(t => t.ColumnId == columnId)
                .MaxAsync(t => (int?)t.Order) ?? -1;

            var task = new TaskItem
            {
                ColumnId = columnId,
                Title = title,
                Priority = priority,
                Order = maxOrder + 1,
                CreatedAt = DateTime.UtcNow
            };

            _db.TaskItems.Add(task);
            await _db.SaveChangesAsync();

            return task;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating task '{TaskTitle}' in column {ColumnId}", title, columnId);
            throw;
        }
    }

    public async Task<TaskItem?> UpdateTaskAsync(TaskItem task)
    {
        try
        {
            var existing = await _db.TaskItems.FindAsync(task.Id);
            if (existing is null)
                return null;

            existing.Title = task.Title;
            existing.Description = task.Description;
            existing.Priority = task.Priority;
            existing.DueDate = task.DueDate;

            await _db.SaveChangesAsync();

            return existing;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating task {TaskId}", task.Id);
            throw;
        }
    }

    public async Task<bool> DeleteTaskAsync(int id)
    {
        try
        {
            var task = await _db.TaskItems
                .Include(t => t.ChecklistItems)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (task is null)
                return false;

            _db.TaskItems.Remove(task);
            await _db.SaveChangesAsync();

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting task {TaskId}", id);
            throw;
        }
    }

    public async Task<bool> MoveTaskAsync(int taskId, int targetColumnId, int? newOrder)
    {
        try
        {
            var task = await _db.TaskItems.FindAsync(taskId);
            if (task is null)
                return false;

            if (!await CanMoveToColumnAsync(targetColumnId, task.ColumnId == targetColumnId ? taskId : null))
                return false;

            await using var transaction = await _db.Database.BeginTransactionAsync();

            var sourceColumnId = task.ColumnId;

            // Remove from source: close the gap in ordering
            if (sourceColumnId != targetColumnId)
            {
                var sourceTasks = await _db.TaskItems
                    .Where(t => t.ColumnId == sourceColumnId && t.Order > task.Order)
                    .ToListAsync();

                foreach (var t in sourceTasks)
                    t.Order--;
            }

            // Determine target order
            if (newOrder.HasValue)
            {
                // Shift tasks at and after the target position
                var targetTasks = await _db.TaskItems
                    .Where(t => t.ColumnId == targetColumnId && t.Id != taskId && t.Order >= newOrder.Value)
                    .ToListAsync();

                foreach (var t in targetTasks)
                    t.Order++;

                task.Order = newOrder.Value;
            }
            else
            {
                // Place at the end
                var maxOrder = await _db.TaskItems
                    .Where(t => t.ColumnId == targetColumnId && t.Id != taskId)
                    .MaxAsync(t => (int?)t.Order) ?? -1;

                task.Order = maxOrder + 1;
            }

            task.ColumnId = targetColumnId;

            await _db.SaveChangesAsync();
            await transaction.CommitAsync();

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error moving task {TaskId} to column {ColumnId}", taskId, targetColumnId);
            throw;
        }
    }

    public async Task<bool> CanMoveToColumnAsync(int columnId)
    {
        return await CanMoveToColumnAsync(columnId, excludeTaskId: null);
    }

    public async Task<ChecklistItem> AddChecklistItemAsync(int taskId, string text)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(text);

        try
        {
            var item = new ChecklistItem
            {
                TaskItemId = taskId,
                Text = text.Trim()
            };

            _db.ChecklistItems.Add(item);
            await _db.SaveChangesAsync();

            return item;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding checklist item to task {TaskId}", taskId);
            throw;
        }
    }

    public async Task<bool> UpdateChecklistItemAsync(ChecklistItem item)
    {
        try
        {
            var existing = await _db.ChecklistItems.FindAsync(item.Id);
            if (existing is null)
                return false;

            existing.Text = item.Text;
            existing.IsDone = item.IsDone;

            await _db.SaveChangesAsync();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating checklist item {ItemId}", item.Id);
            throw;
        }
    }

    public async Task<bool> DeleteChecklistItemAsync(int id)
    {
        try
        {
            var item = await _db.ChecklistItems.FindAsync(id);
            if (item is null)
                return false;

            _db.ChecklistItems.Remove(item);
            await _db.SaveChangesAsync();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting checklist item {ItemId}", id);
            throw;
        }
    }

    private async Task<bool> CanMoveToColumnAsync(int columnId, int? excludeTaskId)
    {
        try
        {
            var column = await _db.Columns.FindAsync(columnId);
            if (column is null)
                return false;

            if (!column.WipLimit.HasValue)
                return true;

            var taskCount = await _db.TaskItems
                .Where(t => t.ColumnId == columnId && (excludeTaskId == null || t.Id != excludeTaskId))
                .CountAsync();

            return taskCount < column.WipLimit.Value;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking WIP limit for column {ColumnId}", columnId);
            throw;
        }
    }
}
