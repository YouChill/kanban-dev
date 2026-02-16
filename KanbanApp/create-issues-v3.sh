#!/usr/bin/env bash
# =============================================================================
# KanbanDev — GitHub Issues import script v3
# 
# Zmiany vs v2:
#   - Faza cleanup: usuwa wszystkie istniejące issues
#   - Nowy issue: CSS Design Tokens (Etap 1)
#   - Nowy issue: IColumnService (Etap 2)
#   - Nowy issue: Global error handling (Etap 4)
#   - Split: TaskDetailDialog → szkielet + edycja/auto-save
#   - Usunięte sztywne numery z tytułów (GitHub nadaje własne)
#   - Cross-referencje przez nazwy opisowe (odporne na przesunięcia)
#   - Navigation properties w modelach (Board, Column)
#   - Seed data przeniesiony z modeli do migracji
#   - Fix: --label z wieloma labelami
#   - Tworzy brakujące labele automatycznie
#
# Requires: gh CLI >= 2.x zalogowany przez `gh auth login`
#
# Użycie:
#   chmod +x create-issues-v3.sh
#   ./create-issues-v3.sh [owner/repo]
# =============================================================================

set +e

# ---------------------------------------------------------------------------
# Repo
# ---------------------------------------------------------------------------
if [ -n "$1" ]; then
  REPO="$1"
else
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
  if [ -z "$REPO" ]; then
    echo "❌ Nie można wykryć repo. Podaj jako argument: ./create-issues-v3.sh owner/repo"
    exit 1
  fi
fi

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  KanbanDev — Issues v3                                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "📦 Repo: $REPO"
echo ""

# ---------------------------------------------------------------------------
# Faza 0: Cleanup — usunięcie istniejących issues
# ---------------------------------------------------------------------------
echo "🗑️  Usuwanie istniejących issues..."

EXISTING=$(gh issue list --repo "$REPO" --state all --limit 200 --json number -q '.[].number' 2>/dev/null)

if [ -z "$EXISTING" ]; then
  echo "  (brak issues do usunięcia)"
else
  echo "$EXISTING" | while read -r num; do
    gh issue delete "$num" --repo "$REPO" --yes 2>/dev/null
    echo "  🗑  Usunięto #$num"
  done
fi

echo ""

# ---------------------------------------------------------------------------
# Faza 0b: Upewnij się, że labele istnieją
# ---------------------------------------------------------------------------
echo "🏷️  Tworzenie brakujących labeli..."

declare -A LABELS=(
  ["etap-1"]="d4c5f9"
  ["etap-2"]="bfd4f2"
  ["etap-3"]="c2e0c6"
  ["etap-4"]="fef2c0"
  ["etap-5"]="f9d0c4"
  ["setup"]="e6e6e6"
  ["model"]="1d76db"
  ["ui"]="5319e7"
  ["service"]="0e8a16"
  ["css"]="fbca04"
  ["decision-needed"]="d93f0b"
)

for label in "${!LABELS[@]}"; do
  gh label create "$label" --repo "$REPO" --color "${LABELS[$label]}" --force 2>/dev/null
done

echo "  ✅ Labele gotowe"
echo ""

# ---------------------------------------------------------------------------
# Faza 0c: Upewnij się, że milestones istnieją
# ---------------------------------------------------------------------------
echo "🎯 Tworzenie brakujących milestones..."

MILESTONES=(
  "Etap 1 — Fundament"
  "Etap 2 — Kanban MVP"
  "Etap 3 — Task Details"
  "Etap 4 — UX Polish"
  "Etap 5 — Multi-board & Produkcja"
)

for ms in "${MILESTONES[@]}"; do
  gh api --method POST "repos/$REPO/milestones" \
    -f title="$ms" -f state="open" 2>/dev/null || true
done

echo "  ✅ Milestones gotowe"
echo ""

# ---------------------------------------------------------------------------
# Helper — tworzy issue i zwraca numer
# ---------------------------------------------------------------------------
create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"     # comma-separated
  local milestone="$4"

  # Build --label flags (bezpieczne dla gh 2.x)
  local label_args=()
  IFS=',' read -ra LABEL_ARRAY <<< "$labels"
  for l in "${LABEL_ARRAY[@]}"; do
    label_args+=(--label "$l")
  done

  local url
  url=$(gh issue create \
    --repo "$REPO" \
    --title "$title" \
    --body "$body" \
    "${label_args[@]}" \
    --milestone "$milestone" 2>&1)

  if echo "$url" | grep -q "github.com"; then
    local number
    number=$(echo "$url" | grep -oE '[0-9]+$')
    echo "  ✅ #$number — $title"
    echo "$number"  # return value (capture with $())
  else
    echo "  ❌ BŁĄD — $title" >&2
    echo "     $url" >&2
    echo "0"
  fi
}

# Wrapper — wypisuje tylko status, zwraca numer
ci() {
  local output
  output=$(create_issue "$@")
  # Ostatnia linia = numer, reszta = logi
  echo "$output" | head -n -1
  echo "$output" | tail -1
}

# ===========================================================================
#  ETAP 1 — FUNDAMENT
# ===========================================================================
echo "── Etap 1 — Fundament ──────────────────────────────────"

create_issue \
"[SETUP] Inicjalizacja projektu Blazor Server z MudBlazor" \
'## Opis
Stworzenie projektu Blazor Server .NET 8, instalacja zależności NuGet, konfiguracja MudBlazor z theme override zgodnym z design tokenami.

**Blokuje:** Modele danych, Layout, CSS Design Tokens

## Zadania
- [ ] `dotnet new blazorserver -n KanbanApp --framework net8.0`
- [ ] Instalacja pakietów NuGet:
  - `MudBlazor`
  - `Microsoft.EntityFrameworkCore`
  - `Microsoft.EntityFrameworkCore.Sqlite`
  - `Microsoft.EntityFrameworkCore.Design`
  - `Npgsql.EntityFrameworkCore.PostgreSQL`
- [ ] Konfiguracja `Program.cs`:
  - Rejestracja MudBlazor services
  - MudTheme override: `Primary="#6366f1"`, `Background="#f1f5f9"`, `Surface="#ffffff"`, `AppbarBackground="#ffffff"`
  - Placeholder na rejestrację serwisów (wypełnią kolejne issues)
- [ ] Import MudBlazor w `_Imports.razor`
- [ ] Podpięcie MudBlazor CSS/JS w `App.razor` / `_Host.cshtml`
- [ ] Usunięcie boilerplate (Counter, FetchData, domyślne style)
- [ ] Weryfikacja: `dotnet run` — strona startuje bez błędów

## Acceptance criteria
- Projekt buduje się bez warningów
- MudBlazor działa (accent color = indigo widoczny w domyślnym MudButton)
- Brak plików z domyślnego szablonu' \
"etap-1,setup" "Etap 1 — Fundament"

create_issue \
"[MODEL] Modele danych i AppDbContext" \
'## Opis
Implementacja wszystkich modeli C# oraz konfiguracja Entity Framework Core z AppDbContext. **Bez seed data** — seed przeniesiony do issue z migracją.

**Wymaga:** Setup projektu
**Blokuje:** Migracja EF Core, serwisy (BoardService, TaskService, ColumnService)

## Zadania
- [ ] `Models/Enums/Priority.cs` — enum `{ Low, Medium, High, Critical }`
- [ ] `Models/Board.cs` — Id, Name, Description, CreatedAt, `List<Column>`
- [ ] `Models/Column.cs` — Id, Name, Color, Order, WipLimit, BoardId, **`Board Board`** (navigation), `List<TaskItem>`
- [ ] `Models/TaskItem.cs` — Id, Title, Description, Priority, DueDate, Order, ColumnId, **`Column Column`** (navigation), `List<Tag>`, `List<ChecklistItem>`, CreatedAt, CompletedAt
- [ ] `Models/Tag.cs` — Id, Name, Color, **`List<TaskItem> Tasks`** (M:N navigation)
- [ ] `Models/ChecklistItem.cs` — Id, Text, IsDone, TaskItemId, **`TaskItem TaskItem`** (navigation)
- [ ] `Data/AppDbContext.cs`:
  - DbSet dla każdego modelu
  - Fluent API: relacje, cascade delete (Column→Tasks, Task→Checklist)
  - **Relacja M:N TaskItem ↔ Tag** (implicit join table `TaskItemTag` lub explicit)
  - Indeksy na `BoardId`, `ColumnId`, `Order`

## ⚠️ Uwagi implementacyjne
- Navigation properties (`Board`, `Column`, `TaskItem`) są kluczowe dla eager loading — nie pomijać
- M:N Tag↔TaskItem: EF Core 8 obsługuje implicit join table, wystarczy `List<Tag>` + `List<TaskItem>` po obu stronach + konfiguracja w Fluent API

## Acceptance criteria
- Modele kompilują się bez błędów
- AppDbContext rejestruje wszystkie DbSet
- Relacje skonfigurowane przez Fluent API (nie atrybuty)
- Każdy model z FK ma navigation property' \
"etap-1,model" "Etap 1 — Fundament"

create_issue \
"[MODEL] Pierwsza migracja EF Core, SQLite i seed data" \
'## Opis
Rejestracja DbContext, wygenerowanie i zastosowanie pierwszej migracji, załadowanie seed data.

**Wymaga:** Modele danych i AppDbContext
**Blokuje:** Serwisy (BoardService, TaskService, ColumnService)

## Zadania
- [ ] Rejestracja DbContext w `Program.cs`: `Data Source=kanban.db`
- [ ] `dotnet ef migrations add InitialCreate`
- [ ] Przegląd wygenerowanego pliku migracji — weryfikacja schematu i indeksów
- [ ] `dotnet ef database update`
- [ ] **Seed data** w `OnModelCreating` (lub osobna klasa `DataSeeder`):
  - 1 tablica "Demo Board"
  - 3 kolumny: "Do zrobienia" (order 0), "W toku" (order 1, WipLimit=3), "Gotowe" (order 2)
  - 3–4 zadania z różnymi priorytetami, 1 z checklistą, 1 z tagami
  - Predefiniowane tagi: backend, frontend, db, design, devops, setup (kolory z design-tokens.md)
- [ ] `.gitignore` — dodać `*.db`, `*.db-shm`, `*.db-wal`
- [ ] Weryfikacja: `kanban.db` powstaje, seed data widoczny

## Acceptance criteria
- Migracja aplikuje się bez błędów
- Tabele odpowiadają modelom (w tym join table TagTaskItem)
- Seed data ładuje się przy pierwszym uruchomieniu
- Predefiniowane tagi mają poprawne kolory' \
"etap-1,model" "Etap 1 — Fundament"

create_issue \
"[CSS] Design Tokens — custom properties i klasy bazowe" \
'## Opis
Plik CSS z custom properties i klasami bazowymi zgodnymi z design-tokens.md. Jeden punkt prawdy dla kolorów, spacing i animacji — komponenty będą z niego korzystać.

**Wymaga:** Setup projektu
**Blokuje:** Layout, KanbanColumn, TaskCard

## Zadania
- [ ] `wwwroot/css/kanban-tokens.css` — custom properties:
  ```css
  :root {
    /* Surfaces */
    --surface-app: #f1f5f9;
    --surface-col: #f8fafc;
    --surface-card: #ffffff;
    --border: #e2e8f0;
    /* Text */
    --text-primary: #1e293b;
    --text-secondary: #64748b;
    --text-muted: #94a3b8;
    /* Accent */
    --accent: #6366f1;
    --accent-hover: #4f46e5;
    --accent-subtle: #eef2ff;
    --accent-border: #c7d2fe;
    /* Priority borders */
    --priority-critical: #ef4444;
    --priority-high: #f97316;
    --priority-medium: #eab308;
    --priority-low: #6366f1;
    /* Spacing */
    --sidebar-width: 220px;
    --topbar-height: 56px;
    --column-width: 270px;
    --column-gap: 16px;
    --card-gap: 8px;
    /* Radii */
    --radius-column: 14px;
    --radius-card: 10px;
    --radius-button: 8px;
    --radius-pill: 99px;
    --radius-modal: 16px;
  }
  ```
- [ ] Klasy priorytetów: `.priority-critical`, `.priority-high`, `.priority-medium`, `.priority-low` (border-left color)
- [ ] Klasy tagów: `.tag-backend`, `.tag-frontend`, `.tag-db`, `.tag-design`, `.tag-devops`, `.tag-setup`, `.tag-default` (bg + text color)
- [ ] Klasy animacji: `.card-hover` (shadow + translateY transition), `.wip-border` (border-color transition)
- [ ] Podpięcie w `App.razor` / `_Host.cshtml`
- [ ] Font import: Inter z Google Fonts (z fallback na system-ui)

## Acceptance criteria
- Zmiana wartości w `:root` propaguje się do wszystkich komponentów
- Klasy priorytetów i tagów renderują poprawne kolory
- Plik jest podpięty globalnie i działa' \
"etap-1,css" "Etap 1 — Fundament"

create_issue \
"[UI] Layout główny — MainLayout, Sidebar, TopBar" \
'## Opis
Szkielet layoutu aplikacji zgodny z design tokenami. Korzysta z CSS custom properties.

**Wymaga:** Setup projektu, CSS Design Tokens
**Blokuje:** Strona Boards, Strona Board

## Zadania
- [ ] `Components/Layout/MainLayout.razor`:
  - Flex row: sidebar + main content
  - Stan `sidebarCollapsed` (CascadingParameter)
  - Background: `var(--surface-app)`
- [ ] `Components/Layout/Sidebar.razor`:
  - Szerokość: `var(--sidebar-width)` → 0 (transition 0.25s ease)
  - Logo: gradient `#6366f1→#8b5cf6`, border-radius 9px
  - Menu items: normal `var(--text-secondary)`, active `bg: var(--accent-subtle), color: var(--accent), fw: 600`, hover `bg: var(--surface-col)`
  - Nawigacja: "Tablice" → `/boards`
  - Przycisk collapse (ikona toggle)
- [ ] `Components/Layout/TopBar.razor`:
  - Wysokość: `var(--topbar-height)`, border-bottom `1px solid var(--border)`
  - Tytuł (16px, 700, `var(--text-primary)`)
  - `[Parameter] RenderFragment? Actions` — slot na przyciski/filtry
  - `[Parameter] string? Title`
- [ ] Podpięcie `MainLayout` jako domyślny layout
- [ ] `CascadingParameter` dla `sidebarCollapsed` — dostępny w child komponentach

## Acceptance criteria
- Sidebar zwija się płynnie (transition 0.25s ease)
- TopBar wyświetla tytuł
- Kolory zgodne z design tokenami (CSS variables)
- Stan sidebara dostępny przez CascadingParameter' \
"etap-1,ui" "Etap 1 — Fundament"

create_issue \
"[SERVICE] IBoardService i BoardService — CRUD tablic" \
'## Opis
Warstwa serwisowa dla operacji na tablicach kanban.

**Wymaga:** Modele danych, Migracja EF Core
**Blokuje:** Strona Boards, Strona Board

## Zadania
- [ ] `Services/Interfaces/IBoardService.cs`:
  - `GetAllBoardsAsync() → List<Board>`
  - `GetBoardByIdAsync(int id) → Board?` (z Include Columns → Tasks → Tags, Checklist)
  - `CreateBoardAsync(string name, string? description) → Board`
  - `UpdateBoardAsync(int id, string name, string? description) → Board?`
  - `DeleteBoardAsync(int id) → bool`
- [ ] `Services/BoardService.cs` — implementacja przez EF Core
  - `GetBoardByIdAsync`: eager loading z `Include(b => b.Columns).ThenInclude(c => c.Tasks).ThenInclude(t => t.Tags)` + `.ThenInclude(t => t.Checklist)`
  - `GetAllBoardsAsync`: bez Include (lista = lekka)
- [ ] Rejestracja w `Program.cs` jako `Scoped`
- [ ] Obsługa błędów: null guard, try-catch z logowaniem

## Acceptance criteria
- Serwis wstrzykiwany przez DI działa
- `GetBoardByIdAsync` eager-ładuje kolumny → zadania → tagi + checklista
- Usunięcie tablicy kaskadowo usuwa kolumny i zadania' \
"etap-1,service" "Etap 1 — Fundament"

create_issue \
"[UI] Strona Boards — lista tablic" \
'## Opis
Strona `/boards` wyświetlająca listę tablic kanban z możliwością tworzenia nowych.

**Wymaga:** Layout, BoardService
**Blokuje:** Strona Board

## Zadania
- [ ] `Pages/Boards.razor` (`@page "/boards"`):
  - MudGrid kart tablic (MudCard): nazwa, opis (skrócony), data utworzenia, przycisk "Otwórz"
  - Przycisk "Nowa tablica" → MudDialog z polami Name + Description
  - Empty state: ilustracja/ikona + komunikat "Nie masz jeszcze żadnej tablicy"
  - Loading state: `MudProgressCircular`
- [ ] `Pages/Index.razor` (`@page "/"`) — `NavigationManager.NavigateTo("/boards")`
- [ ] TopBar title = "Tablice"

## Acceptance criteria
- Lista tablic ładuje seed data
- Tworzenie tablicy odświeża listę bez przeładowania strony
- "Otwórz" nawiguje do `/board/{id}`
- Empty state i loading state działają' \
"etap-1,ui" "Etap 1 — Fundament"

echo ""

# ===========================================================================
#  ETAP 2 — KANBAN MVP
# ===========================================================================
echo "── Etap 2 — Kanban MVP ─────────────────────────────────"

create_issue \
"[UI] Strona Board — szkielet i ładowanie danych (bez D&D)" \
'## Opis
Strona `/board/{id}` ładująca dane tablicy i renderująca statyczny szkielet z poziomym scrollem. **Bez MudDropContainer** — drag & drop będzie dodany w osobnym issue.

**Wymaga:** BoardService, Strona Boards, Layout
**Blokuje:** KanbanColumn, TaskCard, Drag & Drop

---

## ⚠️ DECYZJA WYMAGANA przed implementacją

> Czy drag & drop wewnątrz jednej kolumny (reordering kart) jest wymagany w tej iteracji?

- **Scenariusz A:** Tak — reordering w kolumnie + między kolumnami (pełna logika Order)
- **Scenariusz B:** Nie w MVP — tylko przenoszenie między kolumnami (Order = timestamp)

Wybór wpływa na TaskService.MoveTaskAsync. **Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] `Pages/Board.razor` (`@page "/board/{Id:int}"`):
  - Inject `IBoardService`, `NavigationManager`
  - `OnInitializedAsync`: załaduj board, obsługa 404 (redirect lub error page)
- [ ] `Components/Board/KanbanBoard.razor`:
  - Horizontal scroll container (overflow-x: auto)
  - Flex row: kolumny `var(--column-width)`, gap `var(--column-gap)`, padding 20px 24px
  - Renderowanie `KanbanColumn` dla każdej kolumny (posortowane wg Order)
  - Przycisk "+ Dodaj kolumnę" na końcu
- [ ] TopBar: title = nazwa tablicy, breadcrumb "Tablice / {nazwa}"

## Acceptance criteria
- `/board/1` ładuje seed data i renderuje kolumny statycznie
- Poziomy scroll działa przy wielu kolumnach
- `/board/999` → obsługa 404
- **Brak** MudDropContainer na tym etapie' \
"etap-2,ui,decision-needed" "Etap 2 — Kanban MVP"

create_issue \
"[SERVICE] IColumnService i ColumnService" \
'## Opis
Dedykowana warstwa serwisowa dla operacji na kolumnach. Wydzielona z TaskService aby zachować Single Responsibility.

**Wymaga:** Modele danych, Migracja EF Core
**Blokuje:** KanbanColumn, Dialogi CRUD kolumn

## Zadania
- [ ] `Services/Interfaces/IColumnService.cs`:
  - `GetColumnsByBoardAsync(int boardId) → List<Column>`
  - `CreateColumnAsync(int boardId, string name, string color, int? wipLimit) → Column`
  - `UpdateColumnAsync(int columnId, string name, string color, int? wipLimit) → Column?`
  - `DeleteColumnAsync(int columnId) → bool`
  - `ReorderColumnsAsync(int boardId, List<int> columnIdsInOrder) → bool`
  - `GetColumnTaskCountAsync(int columnId) → int` (helper dla WIP check)
- [ ] `Services/ColumnService.cs`:
  - `CreateColumnAsync`: Order = max(existing) + 1
  - `DeleteColumnAsync`: kaskadowe usunięcie tasków (EF cascade)
  - `ReorderColumnsAsync`: aktualizacja Order dla każdej kolumny w transakcji
- [ ] Rejestracja w `Program.cs` jako `Scoped`

## Acceptance criteria
- CRUD kolumn działa poprawnie
- `ReorderColumnsAsync` nie tworzy luk/duplikatów w Order
- Usunięcie kolumny kaskadowo usuwa zadania' \
"etap-2,service" "Etap 2 — Kanban MVP"

create_issue \
"[SERVICE] ITaskService i TaskService" \
'## Opis
Warstwa serwisowa dla operacji na zadaniach (TaskItem). Nie zawiera operacji na kolumnach — te są w ColumnService.

**Wymaga:** Modele danych, Migracja EF Core
**Blokuje:** TaskCard, Drag & Drop, TaskDetailDialog

---

## ⚠️ DECYZJA WYMAGANA

**Walidacja WIP limit przy drag & drop:**
- **Scenariusz A:** Serwis zwraca error → UI wyświetla Snackbar
- **Scenariusz B:** Serwis + blokada wizualna (karta nie upuszcza się) — wymaga dodatkowego callbacku

**Potwierdź również wybór D&D z issue "Strona Board"** — wpływa na sygnaturę `MoveTaskAsync`.

---

## Zadania
- [ ] `Services/Interfaces/ITaskService.cs`:
  - `GetTaskByIdAsync(int id) → TaskItem?` (z Include Tags, Checklist)
  - `CreateTaskAsync(int columnId, string title, Priority priority = Medium) → TaskItem`
  - `UpdateTaskAsync(TaskItem task) → TaskItem?`
  - `DeleteTaskAsync(int id) → bool`
  - `MoveTaskAsync(int taskId, int targetColumnId, int? newOrder) → bool`
  - `CanMoveToColumnAsync(int columnId) → bool` (WIP limit check)
- [ ] `Services/TaskService.cs`:
  - `CreateTaskAsync`: Order = max w kolumnie + 1
  - `MoveTaskAsync`: przelicza Order w source i target kolumnie, sprawdza WIP
  - `CanMoveToColumnAsync`: porównuje count vs WipLimit
- [ ] Rejestracja w `Program.cs` jako `Scoped`

## Acceptance criteria
- `CanMoveToColumnAsync` zwraca `false` przy pełnej kolumnie
- `MoveTaskAsync` poprawnie przelicza Order (brak duplikatów)
- Usunięcie taska kaskadowo usuwa checklist items' \
"etap-2,service,decision-needed" "Etap 2 — Kanban MVP"

create_issue \
"[UI] KanbanColumn — komponent kolumny" \
'## Opis
Komponent kolumny z headerem, listą kart, WIP badge i przyciskiem dodawania.

**Wymaga:** Strona Board, ColumnService
**Blokuje:** TaskCard, Drag & Drop

## Zadania
- [ ] `Components/Board/KanbanColumn.razor`:
  - **Header** (padding 14px 14px 10px):
    - Kropka koloru kolumny (8px circle)
    - Nazwa (13px, 700, `var(--text-primary)`)
    - WIP badge (pill): count / limit
    - Menu ⋯ (MudMenu): Edytuj, Usuń
  - **WIP badge stany:**
    - OK (count < limit): bg `#e2e8f0`, text `#64748b`
    - Na limicie (count == limit): bg `#fff7ed`, text `#f97316`
    - Przekroczony (count > limit): bg `#fef2f2`, text `#ef4444` + border kolumny `#fca5a5` (transition 0.2s)
  - **Lista kart**: renderowanie `TaskCard` posortowanych wg Order, gap `var(--card-gap)`
  - **Footer**: przycisk "+ Dodaj zadanie" — border dashed `var(--border)`, hover border `var(--accent)`
  - Styling: border-radius `var(--radius-column)`, bg `var(--surface-col)`
- [ ] Parametry: `[Parameter] Column Column`, `[Parameter] EventCallback OnColumnChanged`

## Acceptance criteria
- WIP badge zmienia kolor dynamicznie przy zmianie liczby kart
- Przekroczenie WIP = czerwona ramka kolumny z transition
- Menu kontekstowe (Edytuj, Usuń) otwiera się' \
"etap-2,ui" "Etap 2 — Kanban MVP"

create_issue \
"[UI] TaskCard — komponent karty zadania" \
'## Opis
Karta zadania z priorytetem, tagami, metadanymi i hover efektem.

**Wymaga:** KanbanColumn, TaskService
**Blokuje:** Drag & Drop, TaskDetailDialog

## Zadania
- [ ] `Components/Board/TaskCard.razor`:
  - Border-left 3px z klasą priorytetu (`.priority-critical` etc.)
  - Tytuł: 13px, 600, `var(--text-primary)`
  - Tagi: MudChip z klasami tagów (`.tag-backend` etc.), 10px, 600
  - Metadane (11px, `var(--text-muted)`):
    - DueDate (format "dd MMM"), **czerwony** gdy overdue
    - Checklist progress: `{done}/{total}` (ikona ✓)
  - Hover: `box-shadow: 0 4px 16px rgba(0,0,0,0.08)`, `translateY(-1px)`, transition 0.15s
  - Bg: `var(--surface-card)`, border-radius `var(--radius-card)`, padding 12px 14px
  - `@onclick` → otwiera `TaskDetailDialog` (EventCallback)
- [ ] `Components/Shared/PriorityBadge.razor`:
  - `[Parameter] Priority Priority`
  - Badge z kolorami z design tokenów (border dot + bg)

## Acceptance criteria
- Border-left zmienia kolor wg priorytetu
- Overdue date wyświetla się czerwono
- Hover animacja płynna (CSS, nie Blazor re-render)
- Kliknięcie emituje event (dialog podpięty w kolejnym issue)' \
"etap-2,ui" "Etap 2 — Kanban MVP"

create_issue \
"[UI] Drag & Drop — MudDropContainer" \
'## Opis
Implementacja drag & drop między kolumnami przez `MudDropContainer<TaskItem>`. Dodaje D&D do istniejącego KanbanBoard.

**Wymaga:** KanbanColumn, TaskCard, TaskService
**Blokuje:** Dialogi CRUD

---

## ⚠️ DECYZJA WYMAGANA

Potwierdź oba scenariusze z issues "Strona Board" i "TaskService" (reordering w kolumnie + walidacja WIP). **Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] Owinięcie listy kolumn w `MudDropContainer<TaskItem>` w `KanbanBoard.razor`:
  - `Items` = flat list wszystkich tasków
  - `ItemsSelector` = `(item, zone) => item.ColumnId.ToString() == zone`
  - `ItemDropped` = callback `OnTaskDropped`
- [ ] Każda `KanbanColumn` zawiera `MudDropZone` z identyfikatorem = `Column.Id.ToString()`
- [ ] `OnTaskDropped` handler:
  1. Parsuj `targetColumnId` z drop zone identifier
  2. Sprawdź `CanMoveToColumnAsync` → jeśli false: `MudSnackbar` po polsku ("Kolumna osiągnęła limit WIP")
  3. Wywołaj `MoveTaskAsync`
  4. `StateHasChanged()`
- [ ] Visual feedback: drop zone highlight bg `var(--accent-subtle)` przy dragover
- [ ] Drag opacity: 0.5 na przeciąganej karcie (CSS `.mud-drop-item-dragging`)

## Acceptance criteria
- Karta przenosi się między kolumnami i persystuje po F5
- WIP limit blokuje przenoszenie z komunikatem po polsku
- UI nie desynchronizuje się z bazą
- Visual feedback podczas przeciągania' \
"etap-2,ui,decision-needed" "Etap 2 — Kanban MVP"

create_issue \
"[UI] Dialogi CRUD — kolumny i szybkie tworzenie zadań" \
'## Opis
Dialogi zarządzania kolumnami (add/edit/delete) i inline dodawanie zadań.

**Wymaga:** ColumnService, TaskService, Drag & Drop

## Zadania
- [ ] `Components/Dialogs/AddColumnDialog.razor`:
  - Pola: Nazwa (required), Color picker (6 presetów hex + custom input), WIP Limit (opcjonalne, MudNumericField)
  - Przyciski: Anuluj / Dodaj
  - Tryb Edit: ten sam komponent z `[Parameter] Column? ExistingColumn`
- [ ] Usunięcie kolumny:
  - MudDialog z potwierdzeniem: "Czy na pewno? Kolumna zawiera {n} zadań."
  - Info o kaskadowym usunięciu
- [ ] Inline "Dodaj zadanie" w footer kolumny:
  - Kliknięcie → MudTextField inline (animacja border 0.15s)
  - Enter → `CreateTaskAsync(columnId, title)`, clear input, scroll do nowej karty
  - Escape → anuluj (ukryj input)
- [ ] Refresh danych po każdej operacji (EventCallback chain)

## Acceptance criteria
- Nowa kolumna pojawia się bez przeładowania
- Color picker pokazuje 6 presetów + custom hex
- Inline add task działa klawiaturowo (Enter / Escape)
- Usunięcie kolumny pyta o potwierdzenie z liczbą zadań' \
"etap-2,ui" "Etap 2 — Kanban MVP"

echo ""

# ===========================================================================
#  ETAP 3 — TASK DETAILS
# ===========================================================================
echo "── Etap 3 — Task Details ───────────────────────────────"

create_issue \
"[UI] TaskDetailDialog — szkielet i layout" \
'## Opis
Główny dialog szczegółów zadania — dwukolumnowy layout, otwieranie z TaskCard, wyświetlanie danych (bez edycji).

**Wymaga:** TaskCard, Dialogi CRUD
**Blokuje:** TaskDetailDialog edycja, Checklist, Tagi

## Zadania
- [ ] `Components/Board/TaskDetailDialog.razor` (MudDialog):
  - `[Parameter] int TaskId` — ładuje task przez `ITaskService.GetTaskByIdAsync`
  - Max-width 800px, shadow `0 20px 60px rgba(0,0,0,0.18)`, border-radius `var(--radius-modal)`
  - Layout: flex row:
    - **Lewy panel** (flex: 1): tytuł (display), opis (display), placeholder sekcji Checklist
    - **Prawy panel** (260px): priorytet badge, termin (display), sekcja tagów (display), przycisk "Usuń zadanie" (Color.Error)
  - Loading state wewnątrz dialogu
- [ ] Podpięcie `@onclick` na `TaskCard` → otwiera dialog przez `IDialogService`
- [ ] Zamknięcie dialogu odświeża KanbanBoard

## Acceptance criteria
- Dialog otwiera się z aktualnymi danymi po kliknięciu karty
- Layout dwukolumnowy renderuje się poprawnie
- Zamknięcie dialogu nie powoduje utraty kontekstu' \
"etap-3,ui" "Etap 3 — Task Details"

create_issue \
"[UI] TaskDetailDialog — edycja pól i auto-save" \
'## Opis
Rozbudowa TaskDetailDialog o inline edycję pól z auto-save.

**Wymaga:** TaskDetailDialog szkielet
**Blokuje:** Checklist, Tagi

## Zadania
- [ ] **Tytuł**: kliknięcie → inline MudTextField, save on blur / Enter
- [ ] **Opis**: MudTextField multiline, save on blur (debounce 500ms)
- [ ] **Priorytet**: MudSelect<Priority>, zmiana → natychmiast `UpdateTaskAsync`
- [ ] **Termin**: MudDatePicker, zmiana → natychmiast `UpdateTaskAsync`
- [ ] **Usuń zadanie**: MudButton Color.Error → dialog potwierdzenia → `DeleteTaskAsync` → zamknij dialog
- [ ] Auto-save pattern: każda zmiana pola wywołuje `UpdateTaskAsync`, Snackbar "Zapisano" (krótki, subtle)
- [ ] Po zamknięciu dialogu: `EventCallback` odświeża kartę na boardzie (priorytet border, tytuł)

## Acceptance criteria
- Zmiana każdego pola persystuje bez ręcznego "Zapisz"
- Zmiana priorytetu natychmiast aktualizuje border karty po zamknięciu
- Usunięcie zamyka dialog i usuwa kartę z kolumny
- Debounce na opisie zapobiega spam-save' \
"etap-3,ui" "Etap 3 — Task Details"

create_issue \
"[UI] Checklist w TaskDetailDialog" \
'## Opis
Sekcja checklist z paskiem postępu wewnątrz dialogu.

**Wymaga:** TaskDetailDialog edycja

## Zadania
- [ ] Sekcja "CHECKLIST" w lewym panelu (label 11px, 700, `var(--text-muted)`):
  - `MudProgressLinear`: animacja width 0.4s, kolor `var(--accent)`
  - Tekst "{done} z {total}" (11px, `var(--text-muted)`)
  - Lista `ChecklistItem`:
    - MudCheckBox + tekst (editable on click)
    - Ikona usuń (widoczna on hover)
    - `IsDone` → tekst przekreślony + `var(--text-muted)`
  - Input "+ Dodaj element" na dole (Enter dodaje)
- [ ] Metody w `ITaskService`:
  - `AddChecklistItemAsync(int taskId, string text) → ChecklistItem`
  - `UpdateChecklistItemAsync(ChecklistItem item) → bool`
  - `DeleteChecklistItemAsync(int id) → bool`
- [ ] Aktualizacja metadanych w `TaskCard` po zamknięciu (progress `{done}/{total}`)

## Acceptance criteria
- Progress bar aktualizuje się przy zaznaczeniu checkboxa (animacja 0.4s)
- Można dodawać, edytować (inline) i usuwać elementy
- Zaznaczone elementy mają przekreślony tekst
- Karta na boardzie pokazuje aktualny progress' \
"etap-3,ui" "Etap 3 — Task Details"

create_issue \
"[UI] System tagów w TaskDetailDialog" \
'## Opis
Implementacja systemu tagów z predefiniowaną paletą kolorów.

**Wymaga:** TaskDetailDialog edycja

---

## ⚠️ DECYZJA WYMAGANA

> Czy użytkownicy mogą tworzyć własne tagi?

- **Scenariusz A:** Tylko 7 predefiniowanych tagów (seed data z migracji)
- **Scenariusz B:** Predefiniowane + custom (UI: Name + color picker, zapis do bazy)

**Nie wdrażaj bez potwierdzenia.**

---

## ⚠️ Uwaga implementacyjna
Relacja M:N TaskItem↔Tag została już skonfigurowana w issue z migracją (Fluent API + join table). **Nie twórz jej od nowa** — korzystaj z istniejącej konfiguracji.

## Zadania
- [ ] Sekcja "TAGI" w prawym panelu:
  - Istniejące tagi jako MudChip z przyciskiem `×` (usunięcie z taska)
  - MudChip style: klasy z CSS Design Tokens (`.tag-backend` etc.)
  - "+ Dodaj tag" → MudMenu/dropdown z listą dostępnych tagów (bez już przypiętych)
- [ ] Metody w `ITaskService`:
  - `AddTagToTaskAsync(int taskId, int tagId) → bool`
  - `RemoveTagFromTaskAsync(int taskId, int tagId) → bool`
  - `GetAvailableTagsAsync() → List<Tag>` (wszystkie predefiniowane)
- [ ] Synchronizacja: tagi na karcie w kolumnie odpowiadają tagom w dialogu

## Acceptance criteria
- Tagi renderują się w poprawnych kolorach (spójne między TaskCard i Dialog)
- Dodanie/usunięcie taga persystuje w bazie
- Nie można dodać tego samego taga dwa razy
- Lista dostępnych tagów nie pokazuje już przypiętych' \
"etap-3,ui,decision-needed" "Etap 3 — Task Details"

echo ""

# ===========================================================================
#  ETAP 4 — UX POLISH
# ===========================================================================
echo "── Etap 4 — UX Polish ──────────────────────────────────"

create_issue \
"[SERVICE] BoardFilterState — serwis filtrowania" \
'## Opis
Scoped serwis stanu aktywnych filtrów z notyfikacją komponentów.

**Wymaga:** Dialogi CRUD
**Blokuje:** Filter Bar w TopBar

## Zadania
- [ ] `Services/BoardFilterState.cs` (Scoped):
  - Properties: `string SearchText`, `HashSet<Priority> SelectedPriorities`, `HashSet<int> SelectedTagIds`
  - Event: `Action OnFilterChanged`
  - Metody: `SetSearch(string)`, `SetPriorities(IEnumerable<Priority>)`, `SetTags(IEnumerable<int>)`, `ClearAll()`
  - `bool Matches(TaskItem task)` — sprawdza czy task pasuje do aktywnych filtrów (AND logic)
  - `int ActiveFilterCount` — computed property
- [ ] Rejestracja w `Program.cs` jako `Scoped`
- [ ] Aktualizacja `KanbanColumn.razor` — filtruje wyświetlane karty przez `BoardFilterState.Matches`
- [ ] Subskrypcja na `OnFilterChanged` → `StateHasChanged()` w kolumnach

## Acceptance criteria
- Zmiana dowolnego filtra odświeża wszystkie kolumny
- `ClearAll` resetuje wszystkie filtry i pokazuje wszystkie karty
- Filtry kumulują się (AND): tekst + priorytet + tag
- WIP badge uwzględnia tylko widoczne (filtrowane) karty — lub nie (decyzja do podjęcia)' \
"etap-4,service" "Etap 4 — UX Polish"

create_issue \
"[UI] Filter Bar w TopBar" \
'## Opis
Pasek filtrów w TopBar widoczny tylko na stronie tablicy.

**Wymaga:** BoardFilterState

## Zadania
- [ ] Rozszerzenie slotu `Actions` w TopBar (tylko na `/board/{id}`):
  - MudTextField: wyszukiwanie po tytule, ikona lupy, debounce 300ms
  - MudSelect<Priority>: multi-select, placeholder "Priorytet"
  - MudChipSet tagów: toggle chip = filtr taga
  - Przycisk "Wyczyść" (MudIconButton, widoczny gdy `ActiveFilterCount >= 1`)
- [ ] Podpięcie do `BoardFilterState` — każda zmiana wywołuje odpowiednią metodę Set
- [ ] Badge na ikonie filtrów z `ActiveFilterCount`
- [ ] Responsywność: na małym ekranie filtry w MudMenu/drawer

## Acceptance criteria
- Filtrowanie działa w czasie rzeczywistym (debounce ≤ 300ms)
- Wyczyszczenie przywraca wszystkie karty
- Badge poprawnie pokazuje liczbę aktywnych filtrów
- Układ nie rozjeżdża się na 1280px+' \
"etap-4,ui" "Etap 4 — UX Polish"

create_issue \
"[UI] Overdue styling i statystyki tablicy" \
'## Opis
Oznaczenie przeterminowanych zadań na kartach i panel statystyk tablicy.

**Wymaga:** TaskCard

## Zadania
- [ ] Overdue w `TaskCard.razor`:
  - Warunek: `DueDate.HasValue && DueDate.Value.Date < DateTime.Today`
  - Data w kolorze `var(--priority-critical)`, ikona ostrzeżenia ⚠️
  - Tooltip: "Termin minął X dni temu"
- [ ] Panel statystyk (drawer lub sekcja w TopBar):
  - Liczba zadań per kolumna (mini bar chart lub tekst)
  - Liczba zadań overdue globalnie
  - % zadań z ukończoną checklistą (done == total, total > 0)
  - WIP status per kolumna (OK / na limicie / przekroczony)
- [ ] Ikona/przycisk "Statystyki" w TopBar otwiera panel

## Acceptance criteria
- Overdue widoczne bez otwierania dialogu (na karcie)
- Statystyki aktualizują się po zmianach (D&D, edycja, dodawanie)
- Tooltip na overdue pokazuje liczbę dni' \
"etap-4,ui" "Etap 4 — UX Polish"

create_issue \
"[UI] Empty states i animacje CSS" \
'## Opis
Dopracowanie UX: puste stany, weryfikacja animacji, keyboard shortcuts.

**Wymaga:** KanbanColumn, TaskCard

## Zadania
- [ ] Empty states (z ikoną/ilustracją + tekst po polsku):
  - Pusta kolumna: "Przeciągnij tutaj zadanie lub dodaj nowe"
  - Pusta tablica (0 kolumn): "Dodaj pierwszą kolumnę, aby rozpocząć"
  - Brak wyników filtrowania: "Żadne zadanie nie pasuje do filtrów"
- [ ] Weryfikacja animacji z design-tokens:
  - Karta hover: shadow 0.15s + translateY(-1px) ✓
  - Sidebar: width 0.25s ease ✓
  - WIP border: border-color 0.2s ✓
  - Progress bar: width 0.4s ✓
  - Dodaj zadanie: border + color 0.15s ✓
- [ ] Keyboard shortcuts:
  - `N` → focus na input "Dodaj zadanie" w pierwszej kolumnie
  - `Escape` → zamknij otwarty dialog
- [ ] Scroll do nowo dodanej karty (`ScrollIntoViewAsync` przez `ElementReference` lub JS interop)

## Acceptance criteria
- Żaden pusty stan nie jest białą pustką — zawsze ikona + komunikat
- Wszystkie animacje zgodne z design tokenami (wartości CSS)
- Escape zamyka dialog niezawodnie
- Nowa karta jest widoczna po dodaniu (auto-scroll)' \
"etap-4,ui" "Etap 4 — UX Polish"

create_issue \
"[SERVICE] Global error handling i loading states" \
'## Opis
Spójne podejście do obsługi błędów i stanów ładowania w całej aplikacji.

**Wymaga:** BoardService, TaskService, ColumnService

## Zadania
- [ ] `Components/Shared/ErrorBoundary.razor` lub użycie wbudowanego `<ErrorBoundary>`:
  - Catch unhandled exceptions w komponentach
  - Friendly error message po polsku: "Coś poszło nie tak. Odśwież stronę."
  - Przycisk "Odśwież" / "Spróbuj ponownie"
  - Logowanie błędu (`ILogger`)
- [ ] `SnackbarService` wrapper (opcjonalnie):
  - `ShowSuccess(string message)`, `ShowError(string message)`, `ShowWarning(string message)`
  - Spójne ustawienia: position bottom-right, duration 3s, font po polsku
- [ ] Loading state pattern:
  - `MudProgressLinear` na górze strony podczas ładowania danych
  - `MudSkeleton` placeholder dla kart/kolumn (opcjonalnie)
  - `MudOverlay` + spinner na operacjach D&D (jeśli trwają > 500ms)
- [ ] Obsługa concurrent edit: co jeśli dane zmieniły się od ostatniego load?
  - Reload danych po powrocie z dialogu
  - Optimistic UI update + rollback przy błędzie (opcjonalnie)

## Acceptance criteria
- Błąd serwisu nie crashuje aplikacji — wyświetla Snackbar z komunikatem
- Loading states widoczne przy ładowaniu boardu i operacjach zapisu
- ErrorBoundary łapie nieobsłużone wyjątki' \
"etap-4,service" "Etap 4 — UX Polish"

echo ""

# ===========================================================================
#  ETAP 5 — MULTI-BOARD & PRODUKCJA
# ===========================================================================
echo "── Etap 5 — Multi-board & Produkcja ────────────────────"

create_issue \
"[UI] Zarządzanie tablicami — rename, delete, reorder" \
'## Opis
Rozbudowa strony `/boards` o pełne zarządzanie tablicami.

**Wymaga:** BoardService, Strona Boards

---

## ⚠️ DECYZJA WYMAGANA

> Czy wdrożyć gotowe szablony przy tworzeniu nowej tablicy?

- **Scenariusz A:** 3 szablony: "Scrum" (Backlog/Sprint/Review/Done), "Kanban" (Do zrobienia/W toku/Gotowe), "To-do" (2 kolumny)
- **Scenariusz B:** Tylko pusta tablica z nazwą i opisem

**Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] Menu kontekstowe na karcie tablicy (MudMenu): Zmień nazwę, Usuń
- [ ] Inline rename: kliknięcie nazwy → MudTextField editable, save on blur/Enter
- [ ] Potwierdzenie usunięcia: MudDialog z info "Tablica zawiera {n} kolumn i {m} zadań"
- [ ] Drag & drop reorder tablic (opcjonalny, niski priorytet)
- [ ] Template picker w dialogu tworzenia (po wyborze scenariusza)

## Acceptance criteria
- Rename persystuje natychmiast (auto-save)
- Delete z potwierdzeniem i info o zawartości
- Lista tablic odświeża się bez przeładowania' \
"etap-5,ui,decision-needed" "Etap 5 — Multi-board & Produkcja"

create_issue \
"[SERVICE] ExportService — JSON i CSV" \
'## Opis
Serwis eksportujący dane tablicy do JSON i CSV z możliwością pobrania w przeglądarce.

**Wymaga:** TaskService, BoardService

## Zadania
- [ ] `Services/Interfaces/IExportService.cs`:
  - `ExportBoardToJsonAsync(int boardId) → string` (JSON)
  - `ExportTasksToCsvAsync(int boardId) → string` (CSV)
- [ ] `Services/ExportService.cs`:
  - JSON: pełna serializacja board → columns → tasks → tags, checklist (`System.Text.Json`, pretty-printed)
  - CSV z nagłówkami: Id, Tytuł, Kolumna, Priorytet, Termin, Tagi (joined), Checklist (done/total), Status
- [ ] Przycisk "Eksportuj" w TopBar → MudMenu: "Eksport JSON" / "Eksport CSV"
- [ ] Download przez `IJSRuntime.InvokeVoidAsync("downloadFile", fileName, content)`:
  - JS helper: tworzy Blob → URL → klik na `<a>` → cleanup
- [ ] Rejestracja w `Program.cs`

## Acceptance criteria
- JSON zawiera pełną strukturę (nadaje się do przyszłego importu)
- CSV otwiera się poprawnie w Excel/LibreOffice (separator `;` lub `,`, UTF-8 BOM)
- Pobieranie działa we wszystkich głównych przeglądarkach' \
"etap-5,service" "Etap 5 — Multi-board & Produkcja"

create_issue \
"[SETUP] Konfiguracja PostgreSQL i deployment-ready setup" \
'## Opis
Konfiguracja produkcyjna: PostgreSQL, multi-provider, Docker Compose.

**Wymaga:** Migracja EF Core

---

## ⚠️ DECYZJA WYMAGANA

> Jak zarządzać migracjami w produkcji?

- **Scenariusz A:** Auto-migrate przy starcie (`await db.Database.MigrateAsync()` w `Program.cs`)
- **Scenariusz B:** Ręczne migracje (`dotnet ef database update`) w deployment pipeline

**Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] `appsettings.json` — connection string SQLite (dev default)
- [ ] `appsettings.Production.json` — placeholder `${DB_CONNECTION_STRING}`
- [ ] `Program.cs` — wybór providera przez env `DB_PROVIDER`:
  ```csharp
  var provider = builder.Configuration["DB_PROVIDER"] ?? "sqlite";
  if (provider == "postgres")
      services.AddDbContext<AppDbContext>(o => o.UseNpgsql(connStr));
  else
      services.AddDbContext<AppDbContext>(o => o.UseSqlite(connStr));
  ```
- [ ] Weryfikacja migracji na PostgreSQL (osobny migration assembly lub shared)
- [ ] `docker-compose.yml`: app + postgres:16-alpine z volume
- [ ] `Dockerfile` multi-stage (.NET 8 SDK → runtime)
- [ ] `.env.example` z wymaganymi zmiennymi
- [ ] `README.md` — sekcja "Deployment" z instrukcją

## Acceptance criteria
- `docker-compose up` startuje app + PostgreSQL z działającą bazą
- `DB_PROVIDER=sqlite` przełącza bazę bez zmiany kodu
- Migracje działają na obydwu providerach
- Health check endpoint działa' \
"etap-5,setup,decision-needed" "Etap 5 — Multi-board & Produkcja"

# ===========================================================================
#  Podsumowanie
# ===========================================================================
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅ Gotowe!                                             ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Etap 1 — Fundament:          7 issues                 ║"
echo "║  Etap 2 — Kanban MVP:         7 issues                 ║"
echo "║  Etap 3 — Task Details:       5 issues                 ║"
echo "║  Etap 4 — UX Polish:          5 issues                 ║"
echo "║  Etap 5 — Multi-board & Prod: 3 issues                 ║"
echo "║                                ─────────                ║"
echo "║  RAZEM:                       27 issues                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "🔗 Sprawdź: https://github.com/$REPO/issues"
echo ""
echo "📋 Zmiany vs v2:"
echo "   + CSS Design Tokens (nowy issue)"
echo "   + IColumnService (nowy issue)"  
echo "   + TaskDetailDialog split → szkielet + edycja"
echo "   + Global error handling (nowy issue)"
echo "   + Navigation properties w modelach"
echo "   + Seed data przeniesiony do migracji"
echo "   + M:N uwaga w issue tagów"
echo "   + Usunięte sztywne numery — cross-ref przez nazwy"
echo "   + Fix: --label jako osobne flagi"
echo "   + Auto-tworzenie labeli i milestones"
