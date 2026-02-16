#!/usr/bin/env bash
# =============================================================================
# KanbanDev — GitHub Issues import script (v2 — fixed milestone titles)
# Requires: gh CLI zalogowany przez `gh auth login`
# Labele i milestones muszą już istnieć w repo (utworzone przez v1)
#
# Użycie:
#   chmod +x create-issues-v2.sh
#   ./create-issues-v2.sh
# =============================================================================

# Nie przerywaj na błędach — kontynuuj i raportuj
set +e

# ---------------------------------------------------------------------------
# Repo
# ---------------------------------------------------------------------------
if [ -n "$1" ]; then
  REPO="$1"
else
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
  if [ -z "$REPO" ]; then
    echo "❌ Nie można wykryć repo. Podaj jako argument: ./create-issues-v2.sh owner/repo"
    exit 1
  fi
fi

echo "📦 Repo: $REPO"
echo ""

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local milestone="$4"

  local url
  url=$(gh issue create \
    --repo "$REPO" \
    --title "$title" \
    --body "$body" \
    --label "$labels" \
    --milestone "$milestone" 2>&1)

  if echo "$url" | grep -q "github.com"; then
    local number
    number=$(echo "$url" | grep -oE '[0-9]+$')
    echo "  ✅ #$number — $title"
  else
    echo "  ❌ BŁĄD — $title"
    echo "     $url"
  fi
}

# ---------------------------------------------------------------------------
# ISSUES
# ---------------------------------------------------------------------------
echo "📝 Tworzenie issues..."
echo ""
echo "── Etap 1 — Fundament ──────────────────────────────────"

create_issue \
"[SETUP] #1 — Inicjalizacja projektu Blazor Server z MudBlazor" \
'## Opis
Stworzenie projektu Blazor Server .NET 8, instalacja zależności NuGet, konfiguracja MudBlazor z theme override zgodnym z design tokenami.

**Blokuje:** #2, #3, #4, #5

## Zadania
- [ ] `dotnet new blazorserver -n KanbanApp --framework net8.0`
- [ ] Instalacja pakietów NuGet:
  - `MudBlazor`
  - `Microsoft.EntityFrameworkCore`
  - `Microsoft.EntityFrameworkCore.Sqlite`
  - `Microsoft.EntityFrameworkCore.Design`
  - `Npgsql.EntityFrameworkCore.PostgreSQL`
- [ ] Konfiguracja `Program.cs`:
  - Rejestracja MudBlazor z services
  - MudTheme override: `Primary = "#6366f1"`, `Background = "#f1f5f9"`, `Surface = "#ffffff"`, `AppbarBackground = "#ffffff"`
  - Rejestracja serwisów (placeholder, wypełni #5 i #9)
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
"[MODEL] #2 — Modele danych i AppDbContext" \
'## Opis
Implementacja wszystkich modeli C# oraz konfiguracja Entity Framework Core z AppDbContext.

**Wymaga:** #1
**Blokuje:** #3, #5, #9

## Zadania
- [ ] `Models/Enums/Priority.cs` — enum `{ Low, Medium, High, Critical }`
- [ ] `Models/Board.cs` — Id, Name, Description, CreatedAt, `List<Column>`
- [ ] `Models/Column.cs` — Id, Name, Color, Order, WipLimit, BoardId, `List<TaskItem>`
- [ ] `Models/TaskItem.cs` — Id, Title, Description, Priority, DueDate, Order, ColumnId, `List<Tag>`, `List<ChecklistItem>`, CreatedAt, CompletedAt
- [ ] `Models/Tag.cs` — Id, Name, Color, `List<TaskItem>` (M:N)
- [ ] `Models/ChecklistItem.cs` — Id, Text, IsDone, TaskItemId
- [ ] `Data/AppDbContext.cs`:
  - DbSet dla każdego modelu
  - Fluent API: relacje, cascade delete (Column → Tasks, Task → Checklist)
  - Relacja M:N TaskItem ↔ Tag (tabela join `TaskItemTag`)
  - Indeksy na `BoardId`, `ColumnId`, `Order`
- [ ] Seed data w `OnModelCreating`: 1 tablica, 3 kolumny, 2–3 zadania z różnymi priorytetami

## Acceptance criteria
- Modele kompilują się bez błędów
- AppDbContext rejestruje wszystkie DbSet
- Relacje skonfigurowane przez Fluent API (nie atrybuty)' \
"etap-1,model" "Etap 1 — Fundament"

create_issue \
"[MODEL] #3 — Pierwsza migracja EF Core i konfiguracja SQLite" \
'## Opis
Wygenerowanie i zastosowanie pierwszej migracji EF Core tworzącej schemat bazy danych SQLite.

**Wymaga:** #2
**Blokuje:** #5, #9

## Zadania
- [ ] Rejestracja DbContext w `Program.cs` z connection string: `Data Source=kanban.db`
- [ ] `dotnet ef migrations add InitialCreate`
- [ ] Przegląd wygenerowanego pliku migracji — weryfikacja schematu
- [ ] `dotnet ef database update`
- [ ] Weryfikacja: `kanban.db` powstaje, seed data widoczny
- [ ] `.gitignore` — dodać `*.db`, `*.db-shm`, `*.db-wal`

## Acceptance criteria
- Migracja aplikuje się bez błędów
- Tabele odpowiadają modelom
- Seed data ładuje się przy starcie aplikacji' \
"etap-1,model" "Etap 1 — Fundament"

create_issue \
"[UI] #4 — Layout główny — MainLayout, Sidebar, TopBar" \
'## Opis
Implementacja szkieletu layoutu aplikacji zgodnie z design tokenami.

**Wymaga:** #1
**Blokuje:** #6, #7

## Zadania
- [ ] `Components/Layout/MainLayout.razor`: flex row, sidebar + main, stan `sidebarCollapsed`, bg `#f1f5f9`
- [ ] `Components/Layout/Sidebar.razor`:
  - Szerokość 220px → 0 (transition 0.25s ease)
  - Logo: gradient `#6366f1` → `#8b5cf6`, border-radius 9px
  - Menu items: normal `#64748b`, aktywne `bg: #eef2ff, color: #6366f1, fw: 600`, hover `bg: #f8fafc`
  - Nawigacja: "Tablice" → `/boards`
  - Przycisk collapse
- [ ] `Components/Layout/TopBar.razor`:
  - Wysokość 56px, tytuł (16px, 700, `#1e293b`)
  - Slot na akcje
  - `border-bottom: 1px solid #e2e8f0`
- [ ] Podpięcie `MainLayout` jako domyślny layout w `App.razor`

## Acceptance criteria
- Sidebar zwija się płynnie (transition 0.25s ease)
- TopBar wyświetla tytuł bieżącej strony
- Kolory zgodne z design tokenami' \
"etap-1,ui" "Etap 1 — Fundament"

create_issue \
"[SERVICE] #5 — IBoardService i BoardService — CRUD tablic" \
'## Opis
Implementacja warstwy serwisowej dla operacji na tablicach kanban.

**Wymaga:** #2, #3

## Zadania
- [ ] `Services/Interfaces/IBoardService.cs`:
  - `GetAllBoardsAsync() → List<Board>`
  - `GetBoardByIdAsync(int id) → Board?`
  - `CreateBoardAsync(string name, string? description) → Board`
  - `UpdateBoardAsync(int id, string name, string? description) → Board?`
  - `DeleteBoardAsync(int id) → bool`
- [ ] `Services/BoardService.cs` — implementacja przez EF Core z `Include(b => b.Columns)`
- [ ] Rejestracja `IBoardService` → `BoardService` w `Program.cs` jako Scoped
- [ ] Obsługa błędów: null guard, try-catch

## Acceptance criteria
- Serwis wstrzykiwany przez DI działa
- `GetBoardByIdAsync` eager-ładuje kolumny i zadania
- Usunięcie tablicy kaskadowo usuwa kolumny i zadania' \
"etap-1,service" "Etap 1 — Fundament"

create_issue \
"[UI] #6 — Strona Boards — lista tablic" \
'## Opis
Implementacja strony `/boards` wyświetlającej listę tablic kanban.

**Wymaga:** #4, #5

## Zadania
- [ ] `Pages/Boards.razor` (`@page "/boards"`):
  - MudGrid kart tablic: nazwa, opis, data utworzenia, przycisk "Otwórz"
  - Przycisk "Nowa tablica" → MudDialog (name + description)
  - Empty state gdy brak tablic
  - Loading state (MudProgressCircular)
- [ ] `Pages/Index.razor` — redirect do `/boards`
- [ ] TopBar title = "Tablice"

## Acceptance criteria
- Lista tablic ładuje seed data
- Tworzenie tablicy odświeża listę bez przeładowania
- "Otwórz" nawiguje do `/board/{id}`' \
"etap-1,ui" "Etap 1 — Fundament"

echo ""
echo "── Etap 2 — Kanban MVP ─────────────────────────────────"

create_issue \
"[UI] #7 — Strona Board — szkielet i ładowanie danych" \
'## Opis
Strona `/board/{id}` ładująca dane tablicy i renderująca szkielet z poziomym scrollem.

**Wymaga:** #5, #6
**Blokuje:** #8, #9

---

## ⚠️ DECYZJA WYMAGANA przed implementacją

**Agent musi zapytać właściciela projektu:**

> Czy drag & drop wewnątrz jednej kolumny (reordering kart) jest wymagany w tej iteracji?

- **Scenariusz A:** Tak — reordering w kolumnie + między kolumnami (pełna logika `Order`, bardziej złożony drop handler)
- **Scenariusz B:** Nie w MVP — tylko przenoszenie między kolumnami (Order = timestamp, prostszy kod)

Wybór wpływa na strukturę `MudDropContainer` i sygnaturę `MoveTaskAsync`. **Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] `Pages/Board.razor` (`@page "/board/{Id:int}"`): inject serwisów, `OnInitializedAsync`, obsługa 404
- [ ] `Components/Board/KanbanBoard.razor`: horizontal scroll, flex row (270px, gap 16px, padding 20px 24px), `MudDropContainer<TaskItem>`, przycisk "Dodaj kolumnę"
- [ ] TopBar title = nazwa tablicy, breadcrumb "Tablice / {nazwa}"

## Acceptance criteria
- `/board/1` ładuje dane seed i renderuje kolumny
- Poziomy scroll działa
- 404 page gdy Id nie istnieje' \
"etap-2,ui,decision-needed" "Etap 2 — Kanban MVP"

create_issue \
"[UI] #8 — KanbanColumn — komponent kolumny" \
'## Opis
Komponent kolumny z headerem, listą kart i obsługą WIP limit badge.

**Wymaga:** #7
**Blokuje:** #10, #11

## Zadania
- [ ] `Components/Board/KanbanColumn.razor`:
  - **Header** (padding 14px 14px 10px): kropka koloru, nazwa (13px, 700), WIP badge, menu (⋯)
  - WIP badge stany:
    - OK: bg `#e2e8f0`, text `#64748b`
    - Na limicie: bg `#fff7ed`, text `#f97316`
    - Przekroczony: bg `#fef2f2`, text `#ef4444` + border kolumny `#fca5a5`
  - **Drop zone** (`MudDropZone`) — identyfikator = `Column.Id.ToString()`
  - **Footer**: "+ Dodaj zadanie" (border dashed `#e2e8f0`, hover border `#6366f1`)
  - Border-radius 14px, bg `#f8fafc`, transition `border-color 0.2s`

## Acceptance criteria
- WIP badge zmienia kolor dynamicznie
- Przekroczenie WIP = czerwona ramka kolumny
- Menu kontekstowe działa (Edytuj, Usuń)' \
"etap-2,ui" "Etap 2 — Kanban MVP"

create_issue \
"[SERVICE] #9 — ITaskService i TaskService" \
'## Opis
Pełna warstwa serwisowa dla zadań i kolumn.

**Wymaga:** #2, #3
**Blokuje:** #10, #11, #12

---

## ⚠️ DECYZJA WYMAGANA przed implementacją

**Agent musi zapytać właściciela projektu o DWA scenariusze:**

**1) Walidacja WIP limit:**
- **Scenariusz A:** Tylko serwis — UI dostaje error, wyświetla Snackbar
- **Scenariusz B:** Serwis + blokada wizualna w UI (karta nie upuszcza się) — wymaga dodatkowego callbacku

**2) Potwierdzić wybór drag & drop z #7** (wpływa na sygnaturę `MoveTaskAsync`).

**Nie wdrażaj bez potwierdzenia obu decyzji.**

---

## Zadania
- [ ] `Services/Interfaces/ITaskService.cs`: metody CRUD dla Column i Task, `MoveTaskAsync`, `CanAddToColumnAsync`
- [ ] `Services/TaskService.cs`: `MoveTaskAsync` przelicza Order w obu kolumnach, `CanAddToColumnAsync` sprawdza WipLimit
- [ ] Rejestracja w `Program.cs` jako Scoped

## Acceptance criteria
- `CanAddToColumnAsync` zwraca `false` przy przekroczeniu WIP
- `MoveTaskAsync` poprawnie przelicza Order (brak duplikatów)
- Usunięcie kolumny kaskadowo usuwa zadania i ich dane' \
"etap-2,service,decision-needed" "Etap 2 — Kanban MVP"

create_issue \
"[UI] #10 — TaskCard — komponent karty zadania" \
'## Opis
Karta zadania z priorytetem, tagami, metadanymi i hover efektem.

**Wymaga:** #8, #9

## Zadania
- [ ] `Components/Board/TaskCard.razor`:
  - Border-left 3px: Critical `#ef4444`, High `#f97316`, Medium `#eab308`, Low `#6366f1`
  - Tytuł (13px, 600, `#1e293b`)
  - Tagi jako MudChip (10px, 600, kolor z palety)
  - Metadane (11px, `#94a3b8`): DueDate (czerwony gdy overdue), progress checklist `{done}/{total}`
  - Hover: `box-shadow: 0 4px 16px rgba(0,0,0,0.08)`, `translateY(-1px)`, transition 0.15s
  - bg `#ffffff`, border-radius 10px, padding 12px 14px
  - `@onclick` → otwiera `TaskDetailDialog`
- [ ] `Components/Shared/PriorityBadge.razor`: parameter `Priority Priority`, badge z design tokenów

## Acceptance criteria
- Border-left zmienia kolor wg priorytetu
- Overdue date wyświetla się czerwono
- Hover animacja płynna
- Kliknięcie otwiera dialog' \
"etap-2,ui" "Etap 2 — Kanban MVP"

create_issue \
"[UI] #11 — Drag & Drop — implementacja MudDropContainer" \
'## Opis
Podpięcie drag & drop między kolumnami przez `MudDropContainer<TaskItem>`.

**Wymaga:** #8, #9, #10
**Blokuje:** #12

---

## ⚠️ DECYZJA WYMAGANA przed implementacją

**Agent musi potwierdzić oba scenariusze z #7 i #9** (reordering w kolumnie + sposób walidacji WIP). **Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] `MudDropContainer<TaskItem>` w `KanbanBoard.razor`: `Items`, `ItemsSelector`, `ItemDropped` callback
- [ ] `OnTaskDropped`: parsuj targetColumnId, wywołaj `CanAddToColumnAsync`, WIP exceeded → Snackbar po polsku, wywołaj `MoveTaskAsync`, `StateHasChanged()`
- [ ] Drop zone highlight: bg `#eef2ff` gdy karta nad kolumną
- [ ] Drag opacity: 0.5 na przeciąganej karcie

## Acceptance criteria
- Karta przenosi się między kolumnami i persystuje po odświeżeniu
- WIP limit blokuje z komunikatem po polsku
- UI nie desynchronizuje się z bazą' \
"etap-2,ui,decision-needed" "Etap 2 — Kanban MVP"

create_issue \
"[UI] #12 — Dialogi CRUD — kolumny i szybkie tworzenie zadań" \
'## Opis
Dialogi zarządzania kolumnami i inline dodawania zadań.

**Wymaga:** #9, #11

## Zadania
- [ ] `Components/Dialogs/AddColumnDialog.razor`: nazwa (wymagane), color picker (6 hex + custom), WIP Limit (opcjonalne), Anuluj / Dodaj
- [ ] Edit Column: ten sam komponent w trybie Edit
- [ ] Inline "Dodaj zadanie": kliknięcie → MudTextField inline (animacja 0.15s), Enter → `CreateTaskAsync`, Escape → anuluje
- [ ] Potwierdzenie usunięcia kolumny z info o liczbie zadań

## Acceptance criteria
- Nowa kolumna pojawia się bez przeładowania
- Inline add task działa klawiaturowo (Enter / Escape)
- Usunięcie pyta o potwierdzenie' \
"etap-2,ui" "Etap 2 — Kanban MVP"

echo ""
echo "── Etap 3 — Task Details ───────────────────────────────"

create_issue \
"[UI] #13 — TaskDetailDialog — szkielet i edycja podstawowych pól" \
'## Opis
Główny dialog szczegółów zadania z dwukolumnowym layoutem.

**Wymaga:** #10, #12
**Blokuje:** #14, #15

## Zadania
- [ ] `Components/Board/TaskDetailDialog.razor` (MudDialog, max-width 800px):
  - Layout: flex row — lewy panel (`flex: 1`) + prawy panel (260px)
  - Lewy: tytuł inline editable (save on blur/Enter), opis (multiline), placeholder checklist
  - Prawy: PRIORYTET (MudSelect), TERMIN (MudDatePicker), TAGI placeholder, "Usuń zadanie" (Color.Error)
  - Auto-save przy każdej zmianie pola
  - Shadow: `0 20px 60px rgba(0,0,0,0.18)`, border-radius 16px
- [ ] Podpięcie `@onclick` na TaskCard (DialogParameters z taskId)

## Acceptance criteria
- Dialog otwiera się z aktualnymi danymi
- Zmiana priorytetu aktualizuje kartę po zamknięciu
- Auto-save persystuje zmiany
- Usunięcie zamyka dialog i usuwa kartę' \
"etap-3,ui" "Etap 3 — Task Details"

create_issue \
"[UI] #14 — Checklist w TaskDetailDialog" \
'## Opis
Sekcja checklist z paskiem postępu wewnątrz dialogu.

**Wymaga:** #13

## Zadania
- [ ] Sekcja "Checklist" w lewym panelu:
  - MudProgressLinear, animacja width 0.4s, kolor `#6366f1`
  - Tekst "{done} z {total}" (11px, `#94a3b8`)
  - Lista ChecklistItem: MudCheckBox + tekst editable, ikona usuń na hover, IsDone → tekst przekreślony
  - Input "+ Dodaj element" (Enter dodaje)
- [ ] Serwis: `AddChecklistItemAsync`, `UpdateChecklistItemAsync`, `DeleteChecklistItemAsync` w `ITaskService`

## Acceptance criteria
- Progress bar aktualizuje się przy zaznaczeniu checkboxa
- Można dodawać, edytować i usuwać elementy
- Zaznaczone mają przekreślony tekst' \
"etap-3,ui" "Etap 3 — Task Details"

create_issue \
"[UI] #15 — System tagów w TaskDetailDialog" \
'## Opis
Implementacja systemu tagów z predefiniowaną paletą.

**Wymaga:** #13

---

## ⚠️ DECYZJA WYMAGANA przed implementacją

**Agent musi zapytać właściciela projektu:**

> Czy użytkownicy mogą tworzyć własne tagi?

- **Scenariusz A:** Tylko 7 predefiniowanych tagów (seed + statyczna lista)
- **Scenariusz B:** Predefiniowane + custom (UI: Name + color picker, zapis do bazy)

**Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] Predefiniowane tagi: `backend`, `frontend`, `db`, `design`, `devops`, `setup` (kolory z design-tokens.md)
- [ ] Sekcja "TAGI" w prawym panelu: istniejące jako MudChip z `×`, "+ Dodaj tag" → dropdown
- [ ] `AddTagToTaskAsync(taskId, tagId)`, `RemoveTagFromTaskAsync(taskId, tagId)` w `ITaskService`
- [ ] MudChip: 10px, 600, kolor z palety

## Acceptance criteria
- Tagi wyświetlają się w poprawnych kolorach na karcie i w dialogu
- Dodanie/usunięcie persystuje
- Tag chip spójny między TaskCard a TaskDetailDialog' \
"etap-3,ui,decision-needed" "Etap 3 — Task Details"

echo ""
echo "── Etap 4 — UX Polish ──────────────────────────────────"

create_issue \
"[SERVICE] #16 — BoardFilterState — serwis filtrowania" \
'## Opis
Scoped serwis stanu aktywnych filtrów z notyfikacją komponentów.

**Wymaga:** #12
**Blokuje:** #17

## Zadania
- [ ] `Services/BoardFilterState.cs` (Scoped): properties `SearchText`, `SelectedPriorities`, `SelectedTagIds`, event `OnFilterChanged`, metody `SetSearch / SetPriorities / SetTags / ClearAll`, metoda `Matches(TaskItem) → bool`
- [ ] Rejestracja w `Program.cs` jako Scoped
- [ ] Aktualizacja `KanbanColumn.razor` — filtruje karty przez `BoardFilterState.Matches`

## Acceptance criteria
- Zmiana filtra odświeża wszystkie kolumny
- `ClearAll` resetuje wszystkie filtry' \
"etap-4,service" "Etap 4 — UX Polish"

create_issue \
"[UI] #17 — Filter Bar w TopBar" \
'## Opis
Pasek filtrów w TopBar na stronie tablicy.

**Wymaga:** #16

## Zadania
- [ ] Rozszerzenie `TopBar.razor` o slot filtrów (tylko na `/board/{id}`):
  - MudTextField — wyszukiwanie po tytule (debounce 300ms)
  - MudSelect<Priority> — multi-select
  - MudChipSet tagów — toggle chip = filtr
  - Przycisk "Wyczyść filtry" (widoczny gdy aktywny ≥1 filtr)
- [ ] Podpięcie do `BoardFilterState`
- [ ] Badge z liczbą aktywnych filtrów

## Acceptance criteria
- Filtrowanie działa w czasie rzeczywistym (debounce ≤ 300ms)
- Wyczyszczenie przywraca wszystkie karty
- Filtry kumulują się (AND)' \
"etap-4,ui" "Etap 4 — UX Polish"

create_issue \
"[UI] #18 — Overdue styling i statystyki tablicy" \
'## Opis
Oznaczenie przeterminowanych zadań i panel statystyk.

**Wymaga:** #10

## Zadania
- [ ] Overdue w `TaskCard.razor`: `DueDate < DateTime.Today` → data `#ef4444`, ikona ostrzeżenia, tooltip "Termin minął X dni temu"
- [ ] Statystyki (panel w KanbanBoard lub MudMenu w TopBar):
  - Liczba zadań per kolumna
  - Liczba zadań overdue globalnie
  - % zadań z ukończonym checklistem
  - WIP status per kolumna

## Acceptance criteria
- Overdue widoczne bez otwierania dialogu
- Statystyki aktualizują się po zmianach' \
"etap-4,ui" "Etap 4 — UX Polish"

create_issue \
"[UI] #19 — Empty states i animacje CSS" \
'## Opis
Dopracowanie UX: puste stany, animacje, keyboard shortcuts.

**Wymaga:** #8, #10

## Zadania
- [ ] Empty states: pusta kolumna, pusta tablica (SVG), brak wyników filtrowania
- [ ] Weryfikacja animacji z design-tokens: karta hover (shadow 0.15s + translateY -1px), sidebar (0.25s ease), WIP border (0.2s), progress bar (0.4s)
- [ ] Keyboard shortcuts: `N` → focus "Dodaj zadanie", `Escape` → zamknij dialog
- [ ] Scroll do nowo dodanej karty (`ElementReference.ScrollIntoViewAsync`)

## Acceptance criteria
- Żaden pusty stan nie jest białą pustką
- Wszystkie animacje zgodne z design tokenami
- Escape zamyka dialog niezawodnie' \
"etap-4,ui" "Etap 4 — UX Polish"

echo ""
echo "── Etap 5 — Multi-board & Produkcja ────────────────────"

create_issue \
"[UI] #20 — Zarządzanie tablicami — rename, delete, reorder" \
'## Opis
Rozbudowa strony `/boards` o pełne zarządzanie tablicami.

**Wymaga:** #5, #6

---

## ⚠️ DECYZJA WYMAGANA przed implementacją

**Agent musi zapytać właściciela projektu:**

> Czy wdrożyć gotowe szablony przy tworzeniu nowej tablicy?

- **Scenariusz A:** Tak — 3 szablony: "Scrum" (Backlog/Sprint/Review/Done), "Kanban" (Do zrobienia/W toku/Gotowe), "To-do" (2 kolumny)
- **Scenariusz B:** Nie — tylko pusta tablica z nazwą i opisem

**Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] Menu kontekstowe na karcie tablicy: Zmień nazwę, Usuń
- [ ] Inline rename (kliknięcie nazwy → editable)
- [ ] Drag & drop reorder tablic (opcjonalny)
- [ ] Potwierdzenie usunięcia z info o liczbie kolumn/zadań
- [ ] Template picker (po wyborze scenariusza)

## Acceptance criteria
- Rename i delete działają z potwierdzeniem
- Lista tablic odświeża się bez przeładowania' \
"etap-5,ui,decision-needed" "Etap 5 — Multi-board & Produkcja"

create_issue \
"[SERVICE] #21 — ExportService — JSON i CSV" \
'## Opis
Serwis eksportujący dane tablicy do JSON i CSV.

**Wymaga:** #9

## Zadania
- [ ] `Services/Interfaces/IExportService.cs`: `ExportBoardToJsonAsync(int boardId)`, `ExportTasksToCsvAsync(int boardId)`
- [ ] `Services/ExportService.cs`: JSON pełna serializacja (`System.Text.Json`), CSV z nagłówkami (Id, Tytuł, Kolumna, Priorytet, Termin, Tagi, Status checklist)
- [ ] Przycisk "Eksportuj" w TopBar → MudMenu: "Eksport JSON" / "Eksport CSV"
- [ ] Download przez `IJSRuntime`

## Acceptance criteria
- JSON zawiera pełną strukturę (nadaje się do przyszłego importu)
- CSV otwiera się poprawnie w Excel/LibreOffice
- Pobieranie działa w przeglądarce' \
"etap-5,service" "Etap 5 — Multi-board & Produkcja"

create_issue \
"[SETUP] #22 — Konfiguracja PostgreSQL i deployment-ready setup" \
'## Opis
Konfiguracja produkcyjna: PostgreSQL, zmienne środowiskowe, Docker Compose.

**Wymaga:** #3

---

## ⚠️ DECYZJA WYMAGANA przed implementacją

**Agent musi zapytać właściciela projektu:**

> Jak zarządzać migracjami w produkcji?

- **Scenariusz A:** Auto-migrate przy starcie (`await db.Database.MigrateAsync()` w `Program.cs`)
- **Scenariusz B:** Ręczne migracje (`dotnet ef database update`) jako krok w deployment pipeline

**Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] `appsettings.json` — connection string SQLite (dev default)
- [ ] `appsettings.Production.json` — placeholder `${DB_CONNECTION_STRING}`
- [ ] `Program.cs` — wybór providera przez env `DB_PROVIDER` (sqlite / postgres)
- [ ] Weryfikacja migracji na PostgreSQL
- [ ] `docker-compose.yml`: app + postgres:16-alpine z volume
- [ ] `Dockerfile` multi-stage (.NET 8)
- [ ] `.env.example` z wymaganymi zmiennymi

## Acceptance criteria
- `docker-compose up` startuje app + PostgreSQL
- Zmiana `DB_PROVIDER=sqlite` przełącza bazę bez zmiany kodu
- Migracje działają na obydwu providerach' \
"etap-5,setup,decision-needed" "Etap 5 — Multi-board & Produkcja"

echo ""
echo "🎉 Gotowe! Sprawdź: https://github.com/$REPO/issues"
