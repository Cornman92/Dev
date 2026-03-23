# Pre-commit Hooks (4.1.2)

Optional Git hooks to run PSScriptAnalyzer on key scripts before commit.

## Setup

Copy the hook into your repo (if using Git):

```powershell
# From D:\Dev
$hookDir = Join-Path (Git rev-parse --git-dir 2>$null) 'hooks'
if ($hookDir -and (Test-Path (Split-Path $hookDir))) {
    $preCommit = Join-Path $hookDir 'pre-commit'
    @'
#!/bin/sh
# Run PSScriptAnalyzer on migration script (optional)
pwsh -NoProfile -ExecutionPolicy Bypass -File "D:/Dev/_lint-migrate.ps1" -Path "D:/Dev/Migrate-OneDriveDevToLocal.ps1"
exit 0
'@ | Set-Content -Path $preCommit -Encoding utf8
    (Get-Item $preCommit).Attributes = 'Normal'
}
```

Or use a pre-commit framework (e.g. [pre-commit.com](https://pre-commit.com)) with a local hook that runs `_lint-migrate.ps1`.

## Scripts to lint

- `Migrate-OneDriveDevToLocal.ps1`
- `Invoke-DevMigration.ps1`
- `consolidate_workspace.ps1`

Batch example:

```powershell
.\_lint-migrate.ps1 -Path 'D:\Dev\Migrate-OneDriveDevToLocal.ps1','D:\Dev\Invoke-DevMigration.ps1'
```
