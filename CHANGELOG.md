# Changelog

All notable changes to this workspace are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [0.3.0] - 2026-03-23

### Added
- **Gaming Scripts:** Start-GameLauncher (game scanner/launcher with catalog), Invoke-ModManager (mod enable/disable/backup), Start-StreamHelper (streaming optimization)
- **Automation Scripts:** Invoke-DailyHealthReport (HTML/text health reports with scheduled task support), Invoke-BackupAutomation (config-driven local/cloud backup), Send-Notification (toast/email/Discord/Slack)
- **Tests:** Get-SystemInfo.Tests.ps1, ConvertTo-HashtableSplat.Tests.ps1, Get-FileHashBatch.Tests.ps1 (full Pester coverage for all 5 core functions)

### Changed
- Bumped Functions.psd1 module version to 0.3.0
- Updated plan.md: All 5 phases now complete
- Updated TODO.md: Added items 51-62, all complete

## [0.2.0] - 2026-02-28

### Added
- **Functions:** Write-Log, Get-SystemInfo, Test-AdminPrivilege, ConvertTo-HashtableSplat, Get-FileHashBatch
- **Utility Scripts:** Get-DiskUsage, Clear-TempFiles, Export-InstalledSoftware, Watch-ProcessMemory, Backup-GitRepos, Test-NetworkConnectivity, Get-StartupPrograms, Set-PowerPlan, Get-EventLogSummary, Invoke-BulkRename
- **Optimization Scripts:** Disable-Telemetry, Optimize-Services, Set-VisualPerformance, Clear-WindowsCache, Optimize-NetworkSettings
- **Registry:** Backup-Registry.ps1, Disable-Cortana.reg, Restore-ContextMenu.reg, Set-ExplorerDefaults.reg, Disable-LockScreen.reg
- **Gaming Scripts:** Backup-GameSaves, Get-GpuInfo, Set-GameMode, Get-FpsStats
- **Quality:** Pester test scaffolding, CHANGELOG.md, GitHub Actions lint workflow, module manifest, getting-started guide, script template generator
- **Tooling:** .editorconfig, PSScriptAnalyzerSettings.psd1, VS Code workspace settings
- **Docs:** plan.md, cursor.md, TODO.md with 50 entries

### Changed
- Updated CLAUDE.md with git hooks, key files table, and expanded guidelines
- Updated README.md with tooling documentation and setup instructions

## [0.1.0] - 2026-02-28

### Added
- Initial repository structure and documentation
- .gitignore with 158 exclusion rules
- .gitattributes for CRLF line ending enforcement
- Pre-commit hook for secret scanning
- Commit-msg hook for conventional commit validation
- Scaffolded all 10 project directories with .gitkeep files
- Scripts/Setup-Workspace.ps1 bootstrap script
- Scripts/Install-GitHooks.ps1 hook installer
- CLAUDE.md, README.md, CONTRIBUTING.md, LICENSE
