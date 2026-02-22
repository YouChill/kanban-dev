using System.Globalization;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using KanbanApp.Services.Interfaces;

namespace KanbanApp.Services;

public class ExportService : IExportService
{
    private readonly IBoardService _boardService;
    private readonly ILogger<ExportService> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        Converters = { new JsonStringEnumConverter() },
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public ExportService(IBoardService boardService, ILogger<ExportService> logger)
    {
        _boardService = boardService;
        _logger = logger;
    }

    public async Task<string> ExportBoardToJsonAsync(int boardId)
    {
        try
        {
            var board = await _boardService.GetBoardByIdAsync(boardId);
            if (board is null)
                throw new InvalidOperationException($"Board with id {boardId} not found.");

            var exportData = new
            {
                board.Id,
                board.Name,
                board.Description,
                board.CreatedAt,
                Columns = board.Columns.Select(c => new
                {
                    c.Id,
                    c.Name,
                    c.Color,
                    c.Order,
                    c.WipLimit,
                    Tasks = c.Tasks.Select(t => new
                    {
                        t.Id,
                        t.Title,
                        t.Description,
                        Priority = t.Priority.ToString(),
                        t.DueDate,
                        t.Order,
                        t.CreatedAt,
                        t.CompletedAt,
                        Tags = t.Tags.Select(tag => new
                        {
                            tag.Id,
                            tag.Name,
                            tag.Color
                        }),
                        ChecklistItems = t.ChecklistItems.Select(ci => new
                        {
                            ci.Id,
                            ci.Text,
                            ci.IsDone
                        })
                    })
                })
            };

            return JsonSerializer.Serialize(exportData, JsonOptions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting board {BoardId} to JSON", boardId);
            throw;
        }
    }

    public async Task<string> ExportTasksToCsvAsync(int boardId)
    {
        try
        {
            var board = await _boardService.GetBoardByIdAsync(boardId);
            if (board is null)
                throw new InvalidOperationException($"Board with id {boardId} not found.");

            var sb = new StringBuilder();

            // UTF-8 BOM for Excel compatibility
            sb.Append('\uFEFF');

            // Header
            sb.AppendLine("Id;Tytuł;Kolumna;Priorytet;Termin;Tagi;Checklist;Status");

            foreach (var column in board.Columns.OrderBy(c => c.Order))
            {
                foreach (var task in column.Tasks.OrderBy(t => t.Order))
                {
                    var tags = string.Join(", ", task.Tags.Select(t => t.Name));

                    var checklistDone = task.ChecklistItems.Count(ci => ci.IsDone);
                    var checklistTotal = task.ChecklistItems.Count;
                    var checklist = checklistTotal > 0
                        ? $"{checklistDone}/{checklistTotal}"
                        : string.Empty;

                    var status = task.CompletedAt.HasValue ? "Ukończone" : "Aktywne";

                    var dueDate = task.DueDate?.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) ?? string.Empty;

                    sb.Append(task.Id);
                    sb.Append(';');
                    sb.Append(CsvEscape(task.Title));
                    sb.Append(';');
                    sb.Append(CsvEscape(column.Name));
                    sb.Append(';');
                    sb.Append(task.Priority.ToString());
                    sb.Append(';');
                    sb.Append(dueDate);
                    sb.Append(';');
                    sb.Append(CsvEscape(tags));
                    sb.Append(';');
                    sb.Append(checklist);
                    sb.Append(';');
                    sb.Append(status);
                    sb.AppendLine();
                }
            }

            return sb.ToString();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting board {BoardId} tasks to CSV", boardId);
            throw;
        }
    }

    private static string CsvEscape(string value)
    {
        if (string.IsNullOrEmpty(value))
            return string.Empty;

        if (value.Contains(';') || value.Contains('"') || value.Contains('\n'))
            return $"\"{value.Replace("\"", "\"\"")}\"";

        return value;
    }
}
