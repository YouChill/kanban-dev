namespace KanbanApp.Services.Interfaces;

public interface IExportService
{
    Task<string> ExportBoardToJsonAsync(int boardId);
    Task<string> ExportTasksToCsvAsync(int boardId);
}
