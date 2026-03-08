# Better11 Source Trees

The repository uses a **single canonical C# source tree** for build, test, and release. A second tree exists for reference but is deprecated.

## Canonical Tree (single source of truth)

| Location | Role | Solution |
|----------|------|----------|
| **src\** | **Primary.** All C# source (App, Core, Services, ViewModels) built by the repo-root solution. | **Better11.sln** |

**Build from:** the repo root — run `.\scripts\Build-Better11.ps1 -Configuration Release -Test -Package`.

## Deprecated Alternate Tree

| Location | Role |
|----------|------|
| **Better11\src\** | **Deprecated.** Alternate App/Core/Services/ViewModels tree kept for reference. It is not referenced by the repo-root `Better11.sln` during the current stabilization pass. |

Backup & Restore and User Accounts are already implemented in the canonical tree:

- **Core:** `IBackupRestoreService.cs`, `IUserAccountService.cs`, and DTOs live under `src\Better11.Core\Interfaces\`.
- **Services:** `BackupRestoreService.cs` and `UserAccountService.cs` live under `src\Better11.Services\`.
- **ViewModels:** `BackupRestoreViewModel.cs` and `UserAccountViewModel.cs` live under `src\Better11.ViewModels\`.
- **App:** `BackupRestorePage.xaml` and `UserAccountPage.xaml` (plus code-behind) live under `src\Better11.App\Views\`, with DI registration in `ServiceCollectionExtensions.cs`.

The deprecated `Better11\src\` tree can still be used as reference material for historical comparison, but it is not a required merge source for these features.

## Navigation

The primary tree’s MainWindow includes menu entries for **Backup & Restore** and **User Accounts**, and those entries resolve to the canonical pages and DI-backed ViewModels in `src\`.

## Test Scope

- `Better11.sln` currently includes 7 projects: 4 production projects and 3 xUnit test projects.
- Canonical xUnit coverage for Backup & Restore and User Accounts belongs in the existing in-solution service and viewmodel test projects.
- Legacy tests under `tests\Better11.Tests\` remain in the repo as reference material but are not part of the supported solution test path.
- `tests\TUI\TuiAdapterTests.cs` and `tests\TUI\TuiComponentTests.cs` are present in the repo but are not referenced by `Better11.sln`.
