using KanbanApp.Components;
using KanbanApp.Data;
using KanbanApp.Services;
using KanbanApp.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using MudBlazor.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddMudServices();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<IBoardService, BoardService>();
builder.Services.AddScoped<IColumnService, ColumnService>();
builder.Services.AddScoped<ITaskService, TaskService>();
builder.Services.AddScoped<BoardFilterState>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IExportService, ExportService>();

var app = builder.Build();

// Auto-apply pending migrations at startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    try
    {
        db.Database.Migrate();
    }
    catch (Microsoft.Data.Sqlite.SqliteException)
    {
        // Database file exists but has no migration history — recreate it
        db.Database.EnsureDeleted();
        db.Database.Migrate();
    }
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
