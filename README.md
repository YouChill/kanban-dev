# KanbanApp

Blazor Server application for managing kanban boards, built with .NET 8 and MudBlazor.

## Development

```bash
cd KanbanApp
dotnet run
```

By default, the app uses SQLite (`kanban-dev.db` in Development, `kanban.db` otherwise).

## Deployment

### Docker Compose (recommended)

1. Copy the environment file and set a secure password:

```bash
cp .env.example .env
# Edit .env and set POSTGRES_PASSWORD
```

2. Start the application:

```bash
docker-compose up -d
```

The app will be available at `http://localhost:8080`.

PostgreSQL data is persisted in the `pgdata` Docker volume.

### Environment variables

| Variable | Description | Default |
|---|---|---|
| `DB_PROVIDER` | Database provider: `sqlite` or `postgres` | `sqlite` |
| `ConnectionStrings__DefaultConnection` | Database connection string | `Data Source=kanban.db` |
| `ASPNETCORE_ENVIRONMENT` | Runtime environment | `Production` |
| `POSTGRES_PASSWORD` | PostgreSQL password (docker-compose) | — |

### Database providers

The app supports two database providers, selectable via `DB_PROVIDER`:

- **sqlite** (default) — zero-config, file-based. Good for development and single-server deployments.
- **postgres** — PostgreSQL 16+. Recommended for production.

Example PostgreSQL connection string:
```
Host=localhost;Database=kanban;Username=kanban;Password=secret
```

### Migrations

Migrations are applied automatically at startup (`db.Database.Migrate()`). The migration is compatible with both SQLite and PostgreSQL providers.

### Health check

The `/healthz` endpoint returns the application health status, including database connectivity.

```bash
curl http://localhost:8080/healthz
```

### Manual Docker build

```bash
docker build -t kanban-app .
docker run -p 8080:8080 \
  -e DB_PROVIDER=postgres \
  -e "ConnectionStrings__DefaultConnection=Host=db;Database=kanban;Username=kanban;Password=secret" \
  kanban-app
```
