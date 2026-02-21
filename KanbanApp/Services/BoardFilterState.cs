using KanbanApp.Models;
using KanbanApp.Models.Enums;

namespace KanbanApp.Services;

public class BoardFilterState
{
    public string SearchText { get; private set; } = string.Empty;
    public HashSet<Priority> SelectedPriorities { get; private set; } = [];
    public HashSet<int> SelectedTagIds { get; private set; } = [];

    public event Action? OnFilterChanged;

    public int ActiveFilterCount
    {
        get
        {
            var count = 0;
            if (!string.IsNullOrWhiteSpace(SearchText)) count++;
            if (SelectedPriorities.Count > 0) count++;
            if (SelectedTagIds.Count > 0) count++;
            return count;
        }
    }

    public void SetSearch(string text)
    {
        SearchText = text ?? string.Empty;
        NotifyChanged();
    }

    public void SetPriorities(IEnumerable<Priority> priorities)
    {
        SelectedPriorities = new HashSet<Priority>(priorities);
        NotifyChanged();
    }

    public void SetTags(IEnumerable<int> tagIds)
    {
        SelectedTagIds = new HashSet<int>(tagIds);
        NotifyChanged();
    }

    public void ClearAll()
    {
        SearchText = string.Empty;
        SelectedPriorities = [];
        SelectedTagIds = [];
        NotifyChanged();
    }

    public bool Matches(TaskItem task)
    {
        if (!string.IsNullOrWhiteSpace(SearchText))
        {
            var search = SearchText.Trim();
            var matchesTitle = task.Title.Contains(search, StringComparison.OrdinalIgnoreCase);
            var matchesDescription = task.Description?.Contains(search, StringComparison.OrdinalIgnoreCase) == true;
            if (!matchesTitle && !matchesDescription) return false;
        }

        if (SelectedPriorities.Count > 0 && !SelectedPriorities.Contains(task.Priority))
        {
            return false;
        }

        if (SelectedTagIds.Count > 0 && !task.Tags.Any(t => SelectedTagIds.Contains(t.Id)))
        {
            return false;
        }

        return true;
    }

    private void NotifyChanged()
    {
        OnFilterChanged?.Invoke();
    }
}
