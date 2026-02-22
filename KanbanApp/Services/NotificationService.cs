using KanbanApp.Services.Interfaces;
using MudBlazor;

namespace KanbanApp.Services;

public class NotificationService : INotificationService
{
    private readonly ISnackbar _snackbar;

    public NotificationService(ISnackbar snackbar)
    {
        _snackbar = snackbar;
    }

    public void ShowSuccess(string message)
    {
        _snackbar.Add(message, Severity.Success, ConfigureDefaults);
    }

    public void ShowError(string message)
    {
        _snackbar.Add(message, Severity.Error, config =>
        {
            config.ShowTransitionDuration = 200;
            config.HideTransitionDuration = 200;
            config.VisibleStateDuration = 5000;
        });
    }

    public void ShowWarning(string message)
    {
        _snackbar.Add(message, Severity.Warning, config =>
        {
            config.ShowTransitionDuration = 200;
            config.HideTransitionDuration = 200;
            config.VisibleStateDuration = 3000;
        });
    }

    public void ShowInfo(string message)
    {
        _snackbar.Add(message, Severity.Info, ConfigureDefaults);
    }

    private static void ConfigureDefaults(SnackbarOptions config)
    {
        config.ShowTransitionDuration = 200;
        config.HideTransitionDuration = 200;
        config.VisibleStateDuration = 1500;
    }
}
