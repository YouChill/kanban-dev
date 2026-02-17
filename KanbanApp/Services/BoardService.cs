using KanbanApp.Data;
using KanbanApp.Models;
using KanbanApp.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace KanbanApp.Services;

public class BoardService : IBoardService
{
    private readonly AppDbContext _db;
    private readonly ILogger<BoardService> _logger;

    public BoardService(AppDbContext db, ILogger<BoardService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<List<Board>> GetAllBoardsAsync()
    {
        try
        {
            return await _db.Boards
                .OrderBy(b => b.CreatedAt)
                .ToListAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving all boards");
            throw;
        }
    }

    public async Task<Board?> GetBoardByIdAsync(int id)
    {
        try
        {
            return await _db.Boards
                .Include(b => b.Columns.OrderBy(c => c.Order))
                    .ThenInclude(c => c.Tasks.OrderBy(t => t.Order))
                        .ThenInclude(t => t.Tags)
                .Include(b => b.Columns)
                    .ThenInclude(c => c.Tasks)
                        .ThenInclude(t => t.ChecklistItems)
                .FirstOrDefaultAsync(b => b.Id == id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving board {BoardId}", id);
            throw;
        }
    }

    public async Task<Board> CreateBoardAsync(string name, string? description)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        try
        {
            var board = new Board
            {
                Name = name,
                Description = description,
                CreatedAt = DateTime.UtcNow
            };

            _db.Boards.Add(board);
            await _db.SaveChangesAsync();

            return board;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating board '{BoardName}'", name);
            throw;
        }
    }

    public async Task<Board?> UpdateBoardAsync(int id, string name, string? description)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        try
        {
            var board = await _db.Boards.FindAsync(id);
            if (board is null)
                return null;

            board.Name = name;
            board.Description = description;

            await _db.SaveChangesAsync();

            return board;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating board {BoardId}", id);
            throw;
        }
    }

    public async Task<bool> DeleteBoardAsync(int id)
    {
        try
        {
            var board = await _db.Boards.FindAsync(id);
            if (board is null)
                return false;

            _db.Boards.Remove(board);
            await _db.SaveChangesAsync();

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting board {BoardId}", id);
            throw;
        }
    }
}
