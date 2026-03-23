# Better11 Source Trees

The repository uses a **single canonical C# source tree** for build, test, and release. A second tree exists for reference but is deprecated.

## Canonical Tree (single source of truth)

| Location | Role | Solution |
|----------|------|----------|
| **Better11\Better11\src** | **Primary.** All C# source (App, Core, Services, ViewModels). Includes 16+ XAML pages including Backup & Restore and User Accounts (placeholder pages). Built and tested in CI. | **Better11\Better11\Better11.sln** |

**Build from:** `Better11\Better11` — run `.\scripts\Build-Better11.ps1 -Configuration Release -Test -Package`.

## Deprecated Alternate Tree

| Location | Role |
|----------|------|
| **Better11\src** | **Deprecated.** Extended App with full implementations of Backup & Restore and User Accounts (ViewModels, Services, Core interfaces/DTOs). Not referenced by Better11.sln. Kept for reference; do not use for new development. |

To bring full Backup & Restore or User Account functionality into the canonical tree, copy the implementation from **Better11\src**:

- **Core:** `IBackupRestoreService.cs`, `IUserAccountService.cs`, and DTOs (`RestorePointDto`, `RegistryBackupDto`, `FileBackupDto`, `BackupScheduleDto`, `LocalAccountDto`, etc.) from `Better11\src\Better11.Core\Interfaces\`.
- **Services:** `BackupRestoreService.cs`, `UserAccountService.cs` from `Better11\src\Better11.Services\`.
- **ViewModels:** `BackupRestoreViewModel.cs`, `UserAccountViewModel.cs` from `Better11\src\Better11.ViewModels\`.
- **App:** Replace the placeholder `BackupRestorePage.xaml` / `UserAccountPage.xaml` (and code-behind) in `Better11\Better11\src\Better11.App\Views\` with the full pages from `Better11\src\Better11.App\Views\`, then register the ViewModels and Services in `ServiceCollectionExtensions.cs`.

## Navigation

The primary tree’s MainWindow includes menu entries for **Backup & Restore** and **User Accounts**. The corresponding pages in the canonical tree are placeholders until the full implementation is merged as above.
