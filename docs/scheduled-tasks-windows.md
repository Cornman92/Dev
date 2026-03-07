# Scheduled Tasks (Windows) — FEATURES-AND-AUTOMATIONS-PLAN 4.1

Use Windows Task Scheduler to run workspace report and migration dry-run on a schedule.

## 1. Workspace report (4.1.1)

**Goal:** Regenerate `workspace_report.json` daily.

**Action:** Run `Schedule-WorkspaceReport.ps1` (optionally with `-LogDir D:\Dev\logs`).

**Example (PowerShell as admin):**

```powershell
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File "D:\Dev\Schedule-WorkspaceReport.ps1" -LogDir "D:\Dev\logs"'
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName 'Dev-WorkspaceReport' -Action $action -Trigger $trigger -Settings $settings
```

## 2. Migration dry-run (4.1.4)

**Goal:** Run `Invoke-DevMigration.ps1 -WhatIf` periodically and save log.

**Action:** Run `Invoke-MigrationDryRun.ps1`.

**Example:**

```powershell
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File "D:\Dev\Invoke-MigrationDryRun.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -TaskName 'Dev-MigrationDryRun' -Action $action -Trigger $trigger
```

## 3. Pre-commit / lint (4.1.2)

See [pre-commit hooks](pre-commit-hooks.md) for Git hook setup to run `_lint-migrate.ps1` on key scripts.
