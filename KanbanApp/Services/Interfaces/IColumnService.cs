using KanbanApp.Models;

namespace KanbanApp.Services.Interfaces;

public interface IColumnService
{
    Task<List<Column>> GetColumnsByBoardIdAsync(int boardId);
    Task<Column> CreateColumnAsync(int boardId, string name, string? color, int? wipLimit);
    Task<Column?> UpdateColumnAsync(int id, string name, string? color, int? wipLimit);
    Task<bool> DeleteColumnAsync(int id);
    Task ReorderColumnsAsync(int boardId, List<int> orderedColumnIds);
    Task<int> GetTaskCountAsync(int columnId);
}
