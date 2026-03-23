# TODO - Workspace Task List

> **Last Updated:** 2026-03-23
> Legend: `[ ]` Pending | `[x]` Done | `[~]` In Progress

---

## Foundation & Repository Setup

- [x] 1. Initialize repository with documentation (CLAUDE.md, README.md, CONTRIBUTING.md, LICENSE)
- [x] 2. Create .gitignore with comprehensive exclusion rules
- [x] 3. Add .gitattributes for CRLF line ending enforcement
- [x] 4. Implement pre-commit hook for secret scanning
- [x] 5. Implement commit-msg hook for conventional commit validation
- [x] 6. Create plan.md workspace development roadmap
- [x] 7. Create cursor.md editor configuration rules
- [x] 8. Update CLAUDE.md with git hooks and expanded agent guidelines
- [x] 9. Update README.md with tooling documentation and key documents table
- [x] 10. Scaffold all 10 project directories with .gitkeep files
- [x] 11. Add .editorconfig for cross-editor consistency
- [x] 12. Create Scripts/Setup-Workspace.ps1 bootstrap script
- [x] 13. Create Scripts/Install-GitHooks.ps1 hook installer for fresh clones
- [x] 14. Add PSScriptAnalyzer settings file (PSScriptAnalyzerSettings.psd1)
- [x] 15. Create VS Code workspace settings (.vscode/settings.json)

## Core Function Libraries

- [x] 16. Create Functions/Write-Log.ps1 - structured logging utility
- [x] 17. Create Functions/Get-SystemInfo.ps1 - system information gatherer
- [x] 18. Create Functions/Test-AdminPrivilege.ps1 - admin check helper
- [x] 19. Create Functions/ConvertTo-HashtableSplat.ps1 - parameter splatting helper
- [x] 20. Create Functions/Get-FileHashBatch.ps1 - batch file hashing utility

## Utility Scripts

- [x] 21. Create Scripts/Get-DiskUsage.ps1 - disk space analyzer and reporter
- [x] 22. Create Scripts/Clear-TempFiles.ps1 - temp file and cache cleaner
- [x] 23. Create Scripts/Export-InstalledSoftware.ps1 - installed software inventory
- [x] 24. Create Scripts/Watch-ProcessMemory.ps1 - process memory monitor
- [x] 25. Create Scripts/Backup-GitRepos.ps1 - batch git repository backup
- [x] 26. Create Scripts/Test-NetworkConnectivity.ps1 - network diagnostic toolkit
- [x] 27. Create Scripts/Get-StartupPrograms.ps1 - startup program lister
- [x] 28. Create Scripts/Set-PowerPlan.ps1 - power plan switcher
- [x] 29. Create Scripts/Get-EventLogSummary.ps1 - Windows event log summarizer
- [x] 30. Create Scripts/Invoke-BulkRename.ps1 - batch file rename utility

## System Optimization

- [x] 31. Create Optimizations/Disable-Telemetry.ps1 - disable Windows telemetry services
- [x] 32. Create Optimizations/Optimize-Services.ps1 - disable unnecessary Windows services
- [x] 33. Create Optimizations/Set-VisualPerformance.ps1 - toggle visual effects for performance
- [x] 34. Create Optimizations/Clear-WindowsCache.ps1 - clear system caches (DNS, icon, font)
- [x] 35. Create Optimizations/Optimize-NetworkSettings.ps1 - TCP/network stack tuning

## Registry

- [x] 36. Create Registry/Backup-Registry.ps1 - full or partial registry backup
- [x] 37. Create Registry/Disable-Cortana.reg - disable Cortana via registry
- [x] 38. Create Registry/Restore-ContextMenu.reg - restore classic right-click context menu (Win 11)
- [x] 39. Create Registry/Set-ExplorerDefaults.reg - configure Explorer defaults (show extensions, hidden files)
- [x] 40. Create Registry/Disable-LockScreen.reg - disable Windows lock screen

## Gaming Utilities

- [x] 41. Create Scripts/Backup-GameSaves.ps1 - game save file backup manager
- [x] 42. Create Scripts/Get-GpuInfo.ps1 - GPU information and driver version checker
- [x] 43. Create Scripts/Set-GameMode.ps1 - toggle Windows Game Mode and optimizations
- [x] 44. Create Scripts/Get-FpsStats.ps1 - FPS log parser and statistics reporter

## Documentation & Quality

- [x] 45. Add Pester test scaffolding for Functions/ (Tests/ directory)
- [x] 46. Create a CHANGELOG.md to track releases and changes
- [x] 47. Add GitHub Actions workflow for PSScriptAnalyzer linting
- [x] 48. Create module manifest for Functions/ (Functions.psd1)
- [x] 49. Write getting-started tutorial in Assets/docs/ for onboarding
- [x] 50. Create Scripts/New-ScriptFromTemplate.ps1 - script scaffolding generator

## Phase 4 Remaining - Gaming Utilities

- [x] 51. Create Scripts/Start-GameLauncher.ps1 - game scanner/launcher with catalog
- [x] 52. Create Scripts/Invoke-ModManager.ps1 - game mod enable/disable/backup manager
- [x] 53. Create Scripts/Start-StreamHelper.ps1 - streaming/recording optimization helper

## Phase 5 Remaining - Automation & Integration

- [x] 54. Create Scripts/Invoke-DailyHealthReport.ps1 - scheduled health report (HTML/Text)
- [x] 55. Create Scripts/Invoke-BackupAutomation.ps1 - config-driven backup automation
- [x] 56. Create Scripts/Send-Notification.ps1 - toast/email/webhook notification system

## Test Coverage

- [x] 57. Create Tests/Get-SystemInfo.Tests.ps1 - system info function tests
- [x] 58. Create Tests/ConvertTo-HashtableSplat.Tests.ps1 - splatting helper tests
- [x] 59. Create Tests/Get-FileHashBatch.Tests.ps1 - batch hashing function tests

## Housekeeping

- [x] 60. Update plan.md - mark Phase 4 & 5 items complete
- [x] 61. Update CHANGELOG.md - add v0.3.0 entry
- [x] 62. Bump Functions.psd1 module version to 0.3.0
