#!/usr/bin/env bash
# =============================================================================
# KanbanDev — GitHub Issues import script
# Requires: gh CLI (https://cli.github.com) — zalogowany przez `gh auth login`
#
# Użycie:
#   chmod +x create-issues.sh
#   ./create-issues.sh
#
# Opcjonalnie podaj repo jako argument:
#   ./create-issues.sh owner/repo
# =============================================================================

set -e

# ---------------------------------------------------------------------------
# Repo — wykryj automatycznie lub przyjmij z argumentu
# ---------------------------------------------------------------------------
if [ -n "$1" ]; then
  REPO="$1"
else
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
  if [ -z "$REPO" ]; then
    echo "❌ Nie można wykryć repo. Podaj jako argument: ./create-issues.sh owner/repo"
    exit 1
  fi
fi

echo "📦 Repo: $REPO"
echo ""

# ---------------------------------------------------------------------------
# Helper — tworzy issue, drukuje numer
# ---------------------------------------------------------------------------
create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local milestone="$4"

  local args=(--repo "$REPO" --title "$title" --body "$body")
  [ -n "$labels" ]    && args+=(--label "$labels")
  [ -n "$milestone" ] && args+=(--milestone "$milestone")

  local url
  url=$(gh issue create "${args[@]}" 2>/dev/null)
  local number
  number=$(echo "$url" | grep -oE '[0-9]+$')
  echo "  ✅ #$number — $title"
}

# ---------------------------------------------------------------------------
# 1. LABELS
# ---------------------------------------------------------------------------
echo "🏷️  Tworzenie labeli..."

create_label() {
  local name="$1" color="$2" desc="$3"
  gh label create "$name" --color "$color" --description "$desc" \
     --repo "$REPO" --force 2>/dev/null && echo "  ✅ $name" || echo "  ⚠️  $name (już istnieje)"
}

create_label "etap-1"          "1d76db" "Milestone 1: Fundament"
create_label "etap-2"          "0052cc" "Milestone 2: Kanban MVP"
create_label "etap-3"          "5319e7" "Milestone 3: Task Details"
create_label "etap-4"          "006b75" "Milestone 4: UX Polish"
create_label "etap-5"          "0075ca" "Milestone 5: Multi-board / Prod"
create_label "setup"           "e4e669" "Konfiguracja projektu"
create_label "model"           "d93f0b" "Model danych / migracja EF"
create_label "ui"              "0075ca" "Komponent Razor / UI"
create_label "service"         "5319e7" "Logika biznesowa / serwis"
create_label "blocked"         "b60205" "Czeka na decyzję lub inny issue"
create_label "decision-needed" "fbca04" "Wymaga decyzji przed implementacją"

echo ""

# ---------------------------------------------------------------------------
# 2. MILESTONES
# ---------------------------------------------------------------------------
echo "🎯 Tworzenie milestones..."

create_milestone() {
  local title="$1" desc="$2"
  gh api repos/"$REPO"/milestones \
    --method POST \
    --field title="$title" \
    --field description="$desc" \
    --field state="open" \
    -q .number 2>/dev/null \
    && echo "  ✅ $title" || echo "  ⚠️  $title (już istnieje lub błąd)"
}

M1=$(gh api repos/"$REPO"/milestones --method POST \
  --field title="Etap 1 — Fundament" \
  --field description="Setup projektu, EF Core, MudBlazor, migracje" \
  --field state="open" -q .number 2>/dev/null || echo "")

M2=$(gh api repos/"$REPO"/milestones --method POST \
  --field title="Etap 2 — Kanban MVP" \
  --field description="Kolumny, drag & drop, CRUD" \
  --field state="open" -q .number 2>/dev/null || echo "")

M3=$(gh api repos/"$REPO"/milestones --method POST \
  --field title="Etap 3 — Task Details" \
  --field description="Checklist, tagi, WIP limit" \
  --field state="open" -q .number 2>/dev/null || echo "")

M4=$(gh api repos/"$REPO"/milestones --method POST \
  --field title="Etap 4 — UX Polish" \
  --field description="Filtry, overdue, statystyki, animacje" \
  --field state="open" -q .number 2>/dev/null || echo "")

M5=$(gh api repos/"$REPO"/milestones --method POST \
  --field title="Etap 5 — Multi-board & Produkcja" \
  --field description="Multi-board, export, PostgreSQL, Docker" \
  --field state="open" -q .number 2>/dev/null || echo "")

echo "  Milestone IDs: M1=$M1 M2=$M2 M3=$M3 M4=$M4 M5=$M5"
echo ""

# ---------------------------------------------------------------------------
# 3. ISSUES
# ---------------------------------------------------------------------------
echo "📝 Tworzenie issues..."
echo ""

# ---- ETAP 1 ----------------------------------------------------------------

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
"etap-1,setup" "$M1"

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
"etap-1,model" "$M1"

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
"etap-1,model" "$M1"

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
  - Slot na akcje (przyszłe: filtry, przycisk nowej tablicy)
  - `border-bottom: 1px solid #e2e8f0`
- [ ] Podpięcie `MainLayout` jako domyślny layout w `App.razor`

## Acceptance criteria
- Sidebar zwija się płynnie
- TopBar wyświetla tytuł bieżącej strony
- Kolory zgodne z design tokenami' \
"etap-1,ui" "$M1"

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
"etap-1,service" "$M1"

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
"etap-1,ui" "$M1"

# ---- ETAP 2 ----------------------------------------------------------------

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
- [ ] `Pages/Board.razor` (`@page "/board/{Id:int}"`):
  - Inject `IBoardService`, `ITaskService`
  - `OnInitializedAsync` — ładuje Board z kolumnami i zadaniami
  - Obsługa 404 (brak tablicy)
  - Przekazanie danych do `KanbanBoard`
- [ ] `Components/Board/KanbanBoard.razor`:
  - Horizontal scroll container (`overflow-x: auto`)
  - Flex row: kolumny (270px, gap 16px, padding 20px 24px)
  - `MudDropContainer<TaskItem>` wrapper (po wyborze scenariusza)
  - Przycisk "Dodaj kolumnę" na końcu wiersza
- [ ] TopBar title = nazwa tablicy, breadcrumb "Tablice / {nazwa}"

## Acceptance criteria
- `/board/1` ładuje dane seed i renderuje kolumny
- Poziomy scroll działa
- 404 page gdy Id nie istnieje' \
"etap-2,ui,decision-needed" "$M2"

create_issue \
"[UI] #8 — KanbanColumn — komponent kolumny" \
'## Opis
Komponent kolumny z headerem, listą kart i obsługą WIP limit badge.

**Wymaga:** #7
**Blokuje:** #10, #11

## Zadania
- [ ] `Components/Board/KanbanColumn.razor`:
  - **Header** (padding 14px 14px 10px):
    - Kolorowa kropka (Column.Color)
    - Nazwa (13px, 700, `#1e293b`)
    - WIP badge `{current}/{limit}`:
      - OK: bg `#e2e8f0`, text `#64748b`
      - Na limicie: bg `#fff7ed`, text `#f97316`
      - Przekroczony: bg `#fef2f2`, text `#ef4444` + border kolumny `#fca5a5`
    - Menu (⋯): Edytuj, Usuń kolumnę
  - **Drop zone** (`MudDropZone`) — identyfikator = `Column.Id.ToString()`
  - **Footer**: "+ Dodaj zadanie" (border dashed `#e2e8f0`, hover border `#6366f1`)
  - Border-radius 14px, bg `#f8fafc`
  - Transition `border-color 0.2s`

## Acceptance criteria
- WIP badge zmienia kolor dynamicznie
- Przekroczenie WIP = czerwona ramka kolumny
- Menu kontekstowe działa' \
"etap-2,ui" "$M2"

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
- **Scenariusz B:** Serwis + blokada wizualna w UI (karta nie upuszcza się) — wymaga dodatkowego callbacku `MudDropContainer`

**2) Potwierdzić wybór drag & drop z #7** (wpływa na sygnaturę `MoveTaskAsync`).

**Nie wdrażaj bez potwierdzenia obu decyzji.**

---

## Zadania
- [ ] `Services/Interfaces/ITaskService.cs`:
  - Columns: `AddColumnAsync`, `UpdateColumnAsync`, `DeleteColumnAsync`, `ReorderColumnsAsync`
  - Tasks: `GetTaskByIdAsync`, `CreateTaskAsync`, `UpdateTaskAsync`, `DeleteTaskAsync`, `MoveTaskAsync`, `CanAddToColumnAsync`
- [ ] `Services/TaskService.cs`:
  - `MoveTaskAsync`: aktualizuje `ColumnId`, przelicza `Order` w obu kolumnach
  - `CanAddToColumnAsync`: sprawdza WipLimit vs aktualna liczba zadań
- [ ] Rejestracja w `Program.cs` jako Scoped

## Acceptance criteria
- `CanAddToColumnAsync` zwraca `false` przy przekroczeniu WIP
- `MoveTaskAsync` poprawnie przelicza Order (brak duplikatów)
- Usunięcie kolumny kaskadowo usuwa zadania i ich dane' \
"etap-2,service,decision-needed" "$M2"

create_issue \
"[UI] #10 — TaskCard — komponent karty zadania" \
'## Opis
Karta zadania z priorytetem, tagami, metadanymi i hover efektem.

**Wymaga:** #8, #9

## Zadania
- [ ] `Components/Board/TaskCard.razor`:
  - Border-left 3px: Critical `#ef4444`, High `#f97316`, Medium `#eab308`, Low `#6366f1`
  - Tytuł (13px, 600, `#1e293b`)
  - Tagi jako MudChip (10px, 600, kolor z palety tagów)
  - Metadane (11px, `#94a3b8`): ikona + DueDate (czerwony gdy overdue), progress checklist `{done}/{total}`
  - `PriorityBadge` subkomponent
  - Hover: `box-shadow: 0 4px 16px rgba(0,0,0,0.08)`, `translateY(-1px)`, transition 0.15s
  - bg `#ffffff`, border-radius 10px, padding 12px 14px, gap 8px
  - `@onclick` → otwiera `TaskDetailDialog`
- [ ] `Components/Shared/PriorityBadge.razor`:
  - Parameter `Priority Priority`
  - Badge z bg i kolorem z design tokenów

## Acceptance criteria
- Border-left zmienia kolor wg priorytetu
- Overdue date wyświetla się czerwono
- Hover animacja płynna
- Kliknięcie otwiera dialog' \
"etap-2,ui" "$M2"

create_issue \
"[UI] #11 — Drag & Drop — implementacja MudDropContainer" \
'## Opis
Podpięcie drag & drop między kolumnami przez `MudDropContainer<TaskItem>`.

**Wymaga:** #8, #9, #10
**Blokuje:** #12

---

## ⚠️ DECYZJA WYMAGANA przed implementacją

**Agent musi potwierdzić oba scenariusze z #7 i #9** (reordering w kolumnie + sposób walidacji WIP), bo od nich zależy implementacja `ItemDropped` callback. **Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] Konfiguracja `MudDropContainer<TaskItem>` w `KanbanBoard.razor`:
  - `Items` = spłaszczona lista TaskItem ze wszystkich kolumn
  - `ItemsSelector = (item, zoneId) => item.ColumnId.ToString() == zoneId`
  - `ItemDropped` callback
- [ ] Implementacja `OnTaskDropped`:
  1. Parsuj `targetColumnId` z `dropInfo.DropzoneIdentifier`
  2. Wywołaj `CanAddToColumnAsync` (z wykluczeniem przenoszonego zadania)
  3. WIP exceeded → Snackbar "Kolumna osiągnęła limit WIP" + return
  4. Wywołaj `MoveTaskAsync(taskId, targetColumnId, dropInfo.IndexInZone)`
  5. `StateHasChanged()`
- [ ] Drop zone highlight: bg `#eef2ff` gdy karta nad kolumną
- [ ] Drag opacity: 0.5 na przeciąganej karcie

## Acceptance criteria
- Karta przenosi się między kolumnami i persystuje po odświeżeniu
- WIP limit blokuje upuszczenie z komunikatem po polsku
- UI nie desynchronizuje się z bazą' \
"etap-2,ui,decision-needed" "$M2"

create_issue \
"[UI] #12 — Dialogi CRUD — kolumny i szybkie tworzenie zadań" \
'## Opis
Dialogi zarządzania kolumnami i inline dodawania zadań.

**Wymaga:** #9, #11

## Zadania
- [ ] `Components/Dialogs/AddColumnDialog.razor` (MudDialog):
  - Nazwa kolumny (wymagane)
  - Color picker: 6 predefiniowanych hex + custom
  - WIP Limit (opcjonalne, number, min 1)
  - Przyciski: Anuluj / Dodaj
- [ ] Edit Column: ten sam komponent w trybie Edit (pre-fill + "Zapisz zmiany")
- [ ] Inline "Dodaj zadanie" w footer kolumny:
  - Kliknięcie → `MudTextField` inline (animacja 0.15s)
  - Enter / Blur → `CreateTaskAsync(columnId, title)`
  - Escape → anuluje
- [ ] Potwierdzenie usunięcia kolumny: MudDialog z ostrzeżeniem + liczba zadań

## Acceptance criteria
- Nowa kolumna pojawia się na tablicy bez przeładowania
- Inline add task działa klawiaturowo
- Usunięcie pyta o potwierdzenie z info o liczbie zadań' \
"etap-2,ui" "$M2"

# ---- ETAP 3 ----------------------------------------------------------------

create_issue \
"[UI] #13 — TaskDetailDialog — szkielet i edycja podstawowych pól" \
'## Opis
Główny dialog szczegółów zadania z dwukolumnowym layoutem.

**Wymaga:** #10, #12
**Blokuje:** #14, #15

## Zadania
- [ ] `Components/Board/TaskDetailDialog.razor` (MudDialog, max-width 800px):
  - **Layout**: flex row — lewy panel (`flex: 1`) + prawy panel (260px)
  - **Lewy panel**:
    - Tytuł inline editable (MudTextField, save on blur/Enter)
    - Opis (MudTextField multiline, placeholder "Dodaj opis...")
    - Placeholder sekcja Checklist (wypełni #14)
  - **Prawy panel**:
    - Label "PRIORYTET" (11px, 700, `#94a3b8`) + `MudSelect<Priority>`
    - Label "TERMIN" + `MudDatePicker`
    - Label "TAGI" + placeholder (wypełni #15)
    - Separator + przycisk "Usuń zadanie" (Color.Error)
  - Auto-save przy każdej zmianie pola (bez przycisku "Zapisz")
  - Modal shadow: `0 20px 60px rgba(0,0,0,0.18)`, border-radius 16px
- [ ] Podpięcie `@onclick` na TaskCard (DialogParameters z taskId)

## Acceptance criteria
- Dialog otwiera się z aktualnymi danymi
- Zmiana priorytetu aktualizuje kartę po zamknięciu
- Auto-save persystuje zmiany
- Usunięcie zamyka dialog i usuwa kartę' \
"etap-3,ui" "$M3"

create_issue \
"[UI] #14 — Checklist w TaskDetailDialog" \
'## Opis
Sekcja checklist z paskiem postępu wewnątrz dialogu szczegółów zadania.

**Wymaga:** #13

## Zadania
- [ ] Sekcja "Checklist" w lewym panelu:
  - Progress bar: MudProgressLinear, animacja width 0.4s, kolor `#6366f1`
  - Tekst "{done} z {total}" (11px, `#94a3b8`)
  - Lista ChecklistItem:
    - MudCheckBox + tekst (editable inline po kliknięciu)
    - Ikona usuń (pojawia się na hover)
    - `IsDone = true` → tekst przekreślony, kolor `#94a3b8`
  - Input "+ Dodaj element" na końcu (Enter dodaje)
- [ ] Serwis: `AddChecklistItemAsync`, `UpdateChecklistItemAsync`, `DeleteChecklistItemAsync` w `ITaskService`
- [ ] Aktualizacja pojedynczego elementu bez przeładowania całego zadania

## Acceptance criteria
- Progress bar aktualizuje się przy zaznaczeniu checkboxa
- Można dodawać, edytować i usuwać elementy
- Zaznaczone mają przekreślony tekst' \
"etap-3,ui" "$M3"

create_issue \
"[UI] #15 — System tagów w TaskDetailDialog" \
'## Opis
Implementacja systemu tagów z predefiniowaną paletą i przypisywaniem do zadań.

**Wymaga:** #13

---

## ⚠️ DECYZJA WYMAGANA przed implementacją

**Agent musi zapytać właściciela projektu:**

> Czy użytkownicy mogą tworzyć własne tagi?

- **Scenariusz A:** Tylko 7 predefiniowanych tagów (prostsze — seed + statyczna lista)
- **Scenariusz B:** Predefiniowane + custom (UI do tworzenia: Name + color picker, zapis do bazy)

**Nie wdrażaj bez potwierdzenia.**

---

## Zadania
- [ ] Predefiniowane tagi (seed lub statyczna lista):
  - `backend` → bg `#dbeafe`, text `#3b82f6`
  - `frontend` → bg `#ede9fe`, text `#6366f1`
  - `db` → bg `#f3e8ff`, text `#8b5cf6`
  - `design` → bg `#fce7f3`, text `#ec4899`
  - `devops` → bg `#dcfce7`, text `#16a34a`
  - `setup` → bg `#fef3c7`, text `#d97706`
- [ ] Sekcja "TAGI" w prawym panelu:
  - Istniejące tagi na zadaniu jako MudChip z `×`
  - "+ Dodaj tag" → dropdown dostępnych tagów
- [ ] `AddTagToTaskAsync(taskId, tagId)`, `RemoveTagFromTaskAsync(taskId, tagId)`
- [ ] MudChip: 10px, 600, kolor z palety

## Acceptance criteria
- Tagi wyświetlają się w poprawnych kolorach na karcie i w dialogu
- Dodanie/usunięcie persystuje
- Tag chip spójny między TaskCard a TaskDetailDialog' \
"etap-3,ui,decision-needed" "$M3"

# ---- ETAP 4 ----------------------------------------------------------------

create_issue \
"[SERVICE] #16 — BoardFilterState — serwis filtrowania" \
'## Opis
Scoped serwis przechowujący stan aktywnych filtrów i notyfikujący komponenty o zmianach.

**Wymaga:** #12
**Blokuje:** #17

## Zadania
- [ ] `Services/BoardFilterState.cs` (Scoped):
  - Properties: `SearchText`, `SelectedPriorities: List<Priority>`, `SelectedTagIds: List<int>`
  - Event `OnFilterChanged: Action`
  - Metody: `SetSearch`, `SetPriorities`, `SetTags`, `ClearAll`
  - `Matches(TaskItem task) → bool` — logika filtrowania (AND)
- [ ] Rejestracja w `Program.cs` jako Scoped
- [ ] Aktualizacja `KanbanColumn.razor` — filtruje widoczne karty przez `BoardFilterState.Matches`

## Acceptance criteria
- Zmiana filtra odświeża wszystkie kolumny
- `ClearAll` resetuje wszystkie filtry' \
"etap-4,service" "$M4"

create_issue \
"[UI] #17 — Filter Bar w TopBar" \
'## Opis
Pasek filtrów w TopBar na stronie tablicy.

**Wymaga:** #16

## Zadania
- [ ] Rozszerzenie `TopBar.razor` o slot filtrów (tylko na `/board/{id}`):
  - MudTextField — wyszukiwanie po tytule (debounce 300ms)
  - MudSelect<Priority> — multi-select
  - MudChipSet tagów — toggle = filtr po tagu
  - Przycisk "Wyczyść filtry" (widoczny gdy aktywny ≥1 filtr)
- [ ] Podpięcie do `BoardFilterState`
- [ ] Badge z liczbą aktywnych filtrów

## Acceptance criteria
- Filtrowanie działa w czasie rzeczywistym (debounce ≤ 300ms)
- Wyczyszczenie przywraca wszystkie karty
- Filtry kumulują się (logika AND)' \
"etap-4,ui" "$M4"

create_issue \
"[UI] #18 — Overdue styling i statystyki tablicy" \
'## Opis
Wizualne oznaczenie przeterminowanych zadań i panel statystyk.

**Wymaga:** #10

## Zadania
- [ ] Overdue w `TaskCard.razor`:
  - `DueDate < DateTime.Today` → data w `#ef4444`, ikona ostrzeżenia
  - Tooltip "Termin minął X dni temu"
- [ ] Statystyki (panel w KanbanBoard lub MudMenu w TopBar):
  - Liczba zadań per kolumna
  - Liczba zadań overdue globalnie
  - % zadań z ukończonym checklistem
  - WIP status per kolumna

## Acceptance criteria
- Overdue widoczne bez otwierania dialogu
- Statystyki aktualizują się po zmianach na tablicy' \
"etap-4,ui" "$M4"

create_issue \
"[UI] #19 — Empty states i animacje CSS" \
'## Opis
Dopracowanie UX: puste stany, weryfikacja animacji, keyboard shortcuts.

**Wymaga:** #8, #10

## Zadania
- [ ] Empty states:
  - Pusta kolumna: ikona + "Brak zadań. Kliknij '"'"'+'"'"' aby dodać."
  - Pusta tablica (0 kolumn): SVG + "Zacznij od dodania pierwszej kolumny"
  - Brak wyników filtrowania: "Brak zadań pasujących do filtrów"
- [ ] Weryfikacja animacji (design-tokens):
  - Karta hover: `box-shadow 0.15s`, `transform 0.1s`, `translateY(-1px)`
  - Sidebar collapse: `width 0.25s ease`
  - WIP border: `border-color 0.2s`
  - Progress bar: `width 0.4s`
- [ ] Keyboard shortcuts:
  - `N` → focus na "Dodaj zadanie" w pierwszej kolumnie
  - `Escape` → zamknij otwarty dialog
- [ ] Scroll do nowo dodanej karty (`ElementReference.ScrollIntoViewAsync`)

## Acceptance criteria
- Żaden pusty stan nie jest białą pustką
- Wszystkie animacje zgodne z design tokenami
- Escape zamyka dialog niezawodnie' \
"etap-4,ui" "$M4"

# ---- ETAP 5 ----------------------------------------------------------------

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
- [ ] Drag & drop reorder tablic (opcjonalny — MudDropContainer)
- [ ] Potwierdzenie usunięcia z info o liczbie kolumn/zadań
- [ ] Template picker przy tworzeniu (po wyborze scenariusza)

## Acceptance criteria
- Rename i delete działają z potwierdzeniem
- Lista tablic odświeża się bez przeładowania' \
"etap-5,ui,decision-needed" "$M5"

create_issue \
"[SERVICE] #21 — ExportService — JSON i CSV" \
'## Opis
Serwis eksportujący dane tablicy do JSON (pełny dump) i CSV (lista zadań).

**Wymaga:** #9

## Zadania
- [ ] `Services/Interfaces/IExportService.cs`:
  - `ExportBoardToJsonAsync(int boardId) → string`
  - `ExportTasksToCsvAsync(int boardId) → string`
- [ ] `Services/ExportService.cs`:
  - JSON: pełna serializacja Board → Columns → Tasks (`System.Text.Json`)
  - CSV: nagłówki (Id, Tytuł, Kolumna, Priorytet, Termin, Tagi, Status checklist) + wiersze
- [ ] Przycisk "Eksportuj" w TopBar → MudMenu: "Eksport JSON" / "Eksport CSV"
- [ ] Download przez `IJSRuntime` (trigger pobierania pliku w przeglądarce)

## Acceptance criteria
- JSON zawiera pełną strukturę (nadaje się do przyszłego importu)
- CSV otwiera się poprawnie w Excel/LibreOffice
- Pobieranie działa w przeglądarce' \
"etap-5,service" "$M5"

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
- [ ] `docker-compose.yml`: serwis `app` + `db` (postgres:16-alpine, volume)
- [ ] `Dockerfile` (multi-stage: build + runtime, .NET 8)
- [ ] `.env.example` z wszystkimi wymaganymi zmiennymi

## Acceptance criteria
- `docker-compose up` startuje app + PostgreSQL
- Zmiana `DB_PROVIDER=sqlite` przełącza bazę bez zmiany kodu
- Migracje działają na obydwu providerach' \
"etap-5,setup,decision-needed" "$M5"

# ---------------------------------------------------------------------------
echo ""
echo "🎉 Gotowe! Wszystkie issues utworzone."
echo "   Sprawdź: https://github.com/$REPO/issues"
