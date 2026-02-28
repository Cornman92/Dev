# TODO - Workspace Task List

> **Last Updated:** 2026-02-28
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
- [ ] 19. Create Functions/ConvertTo-HashtableSplat.ps1 - parameter splatting helper
- [ ] 20. Create Functions/Get-FileHash.ps1 - batch file hashing utility

## Utility Scripts

- [ ] 21. Create Scripts/Get-DiskUsage.ps1 - disk space analyzer and reporter
- [ ] 22. Create Scripts/Clear-TempFiles.ps1 - temp file and cache cleaner
- [ ] 23. Create Scripts/Export-InstalledSoftware.ps1 - installed software inventory
- [ ] 24. Create Scripts/Watch-ProcessMemory.ps1 - process memory monitor
- [ ] 25. Create Scripts/Backup-GitRepos.ps1 - batch git repository backup
- [ ] 26. Create Scripts/Test-NetworkConnectivity.ps1 - network diagnostic toolkit
- [ ] 27. Create Scripts/Get-StartupPrograms.ps1 - startup program lister
- [ ] 28. Create Scripts/Set-PowerPlan.ps1 - power plan switcher
- [ ] 29. Create Scripts/Get-EventLogSummary.ps1 - Windows event log summarizer
- [ ] 30. Create Scripts/Invoke-BulkRename.ps1 - batch file rename utility

## System Optimization

- [ ] 31. Create Optimizations/Disable-Telemetry.ps1 - disable Windows telemetry services
- [ ] 32. Create Optimizations/Optimize-Services.ps1 - disable unnecessary Windows services
- [ ] 33. Create Optimizations/Set-VisualPerformance.ps1 - toggle visual effects for performance
- [ ] 34. Create Optimizations/Clear-WindowsCache.ps1 - clear system caches (DNS, icon, font)
- [ ] 35. Create Optimizations/Optimize-NetworkSettings.ps1 - TCP/network stack tuning

## Registry

- [ ] 36. Create Registry/Backup-Registry.ps1 - full or partial registry backup
- [ ] 37. Create Registry/Disable-Cortana.reg - disable Cortana via registry
- [ ] 38. Create Registry/Restore-ContextMenu.reg - restore classic right-click context menu (Win 11)
- [ ] 39. Create Registry/Set-ExplorerDefaults.reg - configure Explorer defaults (show extensions, hidden files)
- [ ] 40. Create Registry/Disable-LockScreen.reg - disable Windows lock screen

## Gaming Utilities

- [ ] 41. Create Scripts/Backup-GameSaves.ps1 - game save file backup manager
- [ ] 42. Create Scripts/Get-GpuInfo.ps1 - GPU information and driver version checker
- [ ] 43. Create Scripts/Set-GameMode.ps1 - toggle Windows Game Mode and optimizations
- [ ] 44. Create Scripts/Get-FpsStats.ps1 - FPS log parser and statistics reporter

## Documentation & Quality

- [ ] 45. Add Pester test scaffolding for Functions/ (Tests/ directory)
- [ ] 46. Create a CHANGELOG.md to track releases and changes
- [ ] 47. Add GitHub Actions workflow for PSScriptAnalyzer linting
- [ ] 48. Create module manifest for Functions/ (Functions.psd1)
- [ ] 49. Write getting-started tutorial in Assets/docs/ for onboarding
- [ ] 50. Create Scripts/New-ScriptFromTemplate.ps1 - script scaffolding generator
