using KanbanApp.Models;

namespace KanbanApp.Services.Interfaces;

public interface IBoardService
{
    Task<List<Board>> GetAllBoardsAsync();
    Task<Board?> GetBoardByIdAsync(int id);
    Task<Board> CreateBoardAsync(string name, string? description);
    Task<Board?> UpdateBoardAsync(int id, string name, string? description);
    Task<bool> DeleteBoardAsync(int id);
}
