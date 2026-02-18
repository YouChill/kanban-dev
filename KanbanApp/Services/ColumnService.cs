using KanbanApp.Data;
using KanbanApp.Models;
using KanbanApp.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace KanbanApp.Services;

public class ColumnService : IColumnService
{
    private readonly AppDbContext _db;
    private readonly ILogger<ColumnService> _logger;

    public ColumnService(AppDbContext db, ILogger<ColumnService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<List<Column>> GetColumnsByBoardIdAsync(int boardId)
    {
        try
        {
            return await _db.Columns
                .Where(c => c.BoardId == boardId)
                .Include(c => c.Tasks.OrderBy(t => t.Order))
                .OrderBy(c => c.Order)
                .ToListAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving columns for board {BoardId}", boardId);
            throw;
        }
    }

    public async Task<Column> CreateColumnAsync(int boardId, string name, string? color, int? wipLimit)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        try
        {
            var maxOrder = await _db.Columns
                .Where(c => c.BoardId == boardId)
                .MaxAsync(c => (int?)c.Order) ?? -1;

            var column = new Column
            {
                BoardId = boardId,
                Name = name,
                Color = color,
                WipLimit = wipLimit,
                Order = maxOrder + 1
            };

            _db.Columns.Add(column);
            await _db.SaveChangesAsync();

            return column;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating column '{ColumnName}' for board {BoardId}", name, boardId);
            throw;
        }
    }

    public async Task<Column?> UpdateColumnAsync(int id, string name, string? color, int? wipLimit)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        try
        {
            var column = await _db.Columns.FindAsync(id);
            if (column is null)
                return null;

            column.Name = name;
            column.Color = color;
            column.WipLimit = wipLimit;

            await _db.SaveChangesAsync();

            return column;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating column {ColumnId}", id);
            throw;
        }
    }

    public async Task<bool> DeleteColumnAsync(int id)
    {
        try
        {
            var column = await _db.Columns
                .Include(c => c.Tasks)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (column is null)
                return false;

            _db.Columns.Remove(column);
            await _db.SaveChangesAsync();

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting column {ColumnId}", id);
            throw;
        }
    }

    public async Task ReorderColumnsAsync(int boardId, List<int> orderedColumnIds)
    {
        try
        {
            await using var transaction = await _db.Database.BeginTransactionAsync();

            var columns = await _db.Columns
                .Where(c => c.BoardId == boardId)
                .ToListAsync();

            for (var i = 0; i < orderedColumnIds.Count; i++)
            {
                var column = columns.FirstOrDefault(c => c.Id == orderedColumnIds[i]);
                if (column is not null)
                {
                    column.Order = i;
                }
            }

            await _db.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reordering columns for board {BoardId}", boardId);
            throw;
        }
    }

    public async Task<int> GetTaskCountAsync(int columnId)
    {
        try
        {
            return await _db.TaskItems
                .CountAsync(t => t.ColumnId == columnId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error counting tasks for column {ColumnId}", columnId);
            throw;
        }
    }
}
