# Changelog

All notable changes to this workspace are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).

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
