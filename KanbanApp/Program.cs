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

// Database provider selection via DB_PROVIDER environment variable
var dbProvider = builder.Configuration["DB_PROVIDER"] ?? "sqlite";
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

if (dbProvider == "postgres")
    builder.Services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));
else
    builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlite(connectionString));

builder.Services.AddScoped<IBoardService, BoardService>();
builder.Services.AddScoped<IColumnService, ColumnService>();
builder.Services.AddScoped<ITaskService, TaskService>();
builder.Services.AddScoped<BoardFilterState>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IExportService, ExportService>();

builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>();

var app = builder.Build();

// Auto-apply pending migrations at startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    if (dbProvider == "postgres")
    {
        db.Database.Migrate();
    }
    else
    {
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
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseStaticFiles();
app.UseAntiforgery();

app.MapHealthChecks("/healthz");

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
