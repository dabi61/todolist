# todo_list_flutter

Offline-first task manager built with Flutter (Material 3), inspired by Todoist workflow. The app runs fully on-device with Isar and uses Riverpod + Clean Architecture for scalable feature growth.

> **Demo note**: screenshots and screen recordings are shown in the section below.

---

## What this project includes

- ✅ Clean Architecture (`core`, `domain`, `data`, `presentation`)
- ✅ Offline-first data with Isar + Isar Flutter libs
- ✅ Riverpod with annotation-based code generation
- ✅ Material 3 UI (`useMaterial3: true`)
- ✅ Todo features: inbox, today, upcoming, calendar, all, completed
- ✅ Rich task model: project, labels, due date/time, reminder, priority, recurrence
- ✅ Bulk actions and metadata management (projects/labels)

## Screenshot & Demo

### Screenshots

> Thêm ảnh của bạn vào thư mục `assets/readme/` rồi giữ tên theo mẫu sau:

| Màn hình | Mô tả |
|---|---|
| Home / Inbox | `assets/readme/home_inbox.png` |
| Today / Upcoming | `assets/readme/today_upcoming.png` |
| Calendar | `assets/readme/calendar.png` |
| Add Task Sheet | `assets/readme/add_task_sheet.png` |
| Completed / Bulk | `assets/readme/bulk_actions.png` |

Example snippet:
```md
![Home / Inbox](assets/readme/home_inbox.png)
```

### Demo workflow (copy to README)

```bash
# 1) install deps
flutter pub get

# 2) generate code (Isar + Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# 3) run
flutter run -d macos  # or -d chrome
```

Suggested demo script:
1. Tạo vài task ở `All`.
2. Gắn project/label.
3. Chuyển `Calendar` để xem task theo ngày.
4. Dùng `Bulk` để cập nhật nhanh nhiều task.
5. Test recurring task + toggle hoàn thành.

## Tech Stack

- Flutter SDK (stable)
- Dart >= 3.4.0
- `flutter_riverpod`
- `riverpod_annotation`
- `go_router`
- `isar`
- `isar_flutter_libs`
- `path_provider`
- `intl`

## Architecture Overview

### Domain
- `domain/entities/`
  - `TaskEntity`, `ProjectEntity`, `LabelEntity`
- `domain/repositories/`
  - `TaskRepository`
  - `ProjectRepository`
  - `LabelRepository`

### Data
- `data/models/` -> Isar schemas (`Task`, `Project`, `Label`)
- `data/repositories/` -> mapping + transactional CRUD

### Core
- `core/providers/app_providers.dart` -> DI + repository providers
- `core/router/app_router.dart` -> route config

### Presentation
- `presentation/providers/`
  - `task_notifier.dart`: state + business actions
  - `task_view_providers.dart`: filters/sort/search/view-mode
- `presentation/screens/` + `widgets/`: home UI, task cards, add/edit sheets, metadata management

## Folder Layout

```text
lib/
  core/
    providers/
    router/
  data/
    models/
    repositories/
  domain/
    entities/
    repositories/
  presentation/
    providers/
    screens/
    widgets/
```

## Features implemented

### Core productivity
- Create / edit / delete task
- Toggle complete + automatic recurring generation (daily/weekly/monthly/yearly/weekday)
- Priority levels and reminders
- Project and label metadata
- Sort by due date, priority, created date
- Global + scoped search

### Views
- `Inbox`, `Today`, `Upcoming`, `Calendar`, `All`, `Done`
- Calendar strip inline in `Calendar` mode
- Empty states and loading/error handling

### Bulk mode
- Select multiple tasks
- Mark done / un-done
- Move to project
- Apply labels
- Delete selected

## State & data flow (high-level)

1. `main.dart` opens Isar and injects DB via `ProviderScope`
2. `TaskNotifier` loads tasks from `TaskRepository`
3. UI observes `filteredTasksProvider`
4. User actions call `TaskNotifier` methods
5. Optimistic update is applied first, then repository writes
6. On write failure, local state can be reloaded for recovery

## Build, Run, Generate

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

For macOS specifically:
```bash
flutter run -d macos
```

## Changelog

### v0.4.0 (2026-03-09)
- Refactor documentation and add full product-ready README sections (`Screenshots`, `Demo`, `Changelog`, migration plan)
- Added project/label management in UI bottom sheets
- Added calendar mode filtering fix to ensure tasks are visible on selected date
- Updated clear-completed icon behavior in All mode (`Icons.access_time`)

### v0.3.0 (2026-03-08)
- Added recurring tasks with interval parsing
- Implemented bulk actions: bulk complete, incomplete, move project, set labels, delete
- Added calendar inline strip and task search/filter refinements
- Added sort options: due date / priority / created date

### v0.2.0 (2026-03-06)
- Added labels, project metadata entities and repositories
- Added offline repository impl for Project/Label
- Expanded TaskCard details with project/tag/reminder/priority indicators
- Improved task notifier with optimistic updates and error recovery

### v0.1.0 (2026-03-01)
- Set up Flutter project with Material 3
- Added Isar offline persistence for tasks, project, label
- Implemented base CRUD for tasks and clean domain/data split
- Added router, provider setup, and first home screen shell

## API / DB Migration Plan (cloud-ready roadmap)

### 1) Keep repository contract stable
- Keep current repository interfaces unchanged.
- Introduce 2 implementations:
  - `IsarTaskRepository` (local)
  - `ApiTaskRepository` (remote)

### 2) Add data source abstraction
- Create:
  - `TaskLocalDataSource` (Isar)
  - `TaskRemoteDataSource` (REST/GraphQL)
- `TaskRepositoryImpl` becomes orchestration layer:
  - write -> local + enqueue sync action
  - read -> local first (instant), then optional remote merge

### 3) Add sync layer
- Add `SyncQueue` table in Isar for pending mutations
- Store `operation`, `entityType`, `payload`, `version`, `updatedAt`
- Background worker drains queue when online

### 4) Resolve conflicts
- Add `updatedAt`/`version` to DTOs.
- Conflict strategy:
  - default: Last-Write-Wins
  - optional: field-level merge for recurring rules

### 5) Auth and multi-device
- Add auth token + userId in all entities/repositories
- Partition local DB by user for isolation
- Implement initial full-sync + incremental delta sync by `updatedAt` cursor

### 6) Rollout sequence
1. Add API DTO + remote data source behind a feature flag
2. Run local + remote in parallel, prefer local UI
3. Build sync queue and retry mechanism
4. Add merge conflict UI for manual review (optional)
5. Gradual rollout by user group

## Known caveats

- `flutter_lints` is not included in this stack.
- macOS build can sometimes fail from stale artifact metadata; run clean + rerun if needed.
- Reminder notifications are stored in task data but not yet tied to system notifications.

## Deployment notes (GitHub-ready summary)

If you only need a compact public README:
- Keep only: app purpose, features, setup, architecture, demo/screens, license
- Put full implementation notes below a `Contributing` or `Architecture` expandable section
- Add badges and screenshot thumbnails near the top for instant attractiveness

## Contributing

- Fork repo
- Create feature branch
- Follow existing provider + repository boundaries
- Keep UI updates through `TaskNotifier`

## License

MIT-style project for learning and portfolio reference.
