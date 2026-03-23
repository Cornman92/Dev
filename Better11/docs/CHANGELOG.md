# Changelog

## [1.0.0-RC1] — March 2026

### Added
- Completed all 7 work streams for production release
- WS7: Final Zero-Error Compilation Pass with zero StyleCop/PSScriptAnalyzer violations
- Comprehensive documentation updates across all project files
- Production-ready deployment package with automated installation
- Complete test coverage with 1,800+ tests (xUnit + Pester)
- Full WinUI 3 application with 16+ functional pages
- 11 production services with PowerShell backend integration
- 14 MVVM ViewModels with CommunityToolkit.Mvvm
- Complete dependency injection and service registration

### Changed
- Updated all documentation to reflect 100% completion status
- Standardized project metrics and file counts across all documentation
- Cleaned up README.md removing duplicate content
- Updated PLAN.md to show all work streams completed
- Refreshed PROJECT-STATUS-SUMMARY.md with final metrics

### Fixed
- Resolved all StyleCop violations across C# codebase
- Fixed all PSScriptAnalyzer violations in PowerShell modules
- Eliminated compilation warnings in core libraries
- Updated cross-references between documentation files
- Standardized all dates to current release date

## [Unreleased] — March 2026

### Added
- BetterPE Phase 4: PXE/WDS network deployment (8 new functions)
- BetterShell v3.0: Watcher, Scheduler, Parallel, FileTools, DevTools, Plugin sub-modules (101 new functions)
- Deduplication pass across all 42+ modules
- Updated CLAUDE.md, MERGE-GUIDE.md, cursor.md, ARCHITECTURE.md

### Changed
- Consolidated B11.SystemInfo read-only queries vs B11.System config operations
- Merged B11.PerformanceMonitor into B11.Performance (aliases preserved)
- Clarified B11.DiskCleanup (simple cleanup) vs B11.Storage (full disk ops)

### Fixed
- Resolved 23 duplicate function definitions across modules
- Standardized all module manifests to explicit function export lists

## [2.0.0] — February 2026

### Added
- WinUI 3 application shell with 45+ pages
- 42+ PowerShell modules (500+ cmdlets)
- BetterPE Phases 1-3 (imaging, deployment, toolkit platform)
- 16 MCP servers for Claude integration
- NTFSLinker standalone tool
- Environment Variables Manager
- BetterShell framework (v2.0, 8 sub-modules)

## [1.0.0] — March 2026

### Added
- Initial production-ready release after completion of work streams WS1–WS7
- WinUI 3 GUI with 16+ pages: Dashboard, Packages, Drivers, Startup, Tasks, Network, Disk Cleanup, Optimization, Privacy, Security, Updates, System Info, About, Settings, First Run Wizard
- 15+ C# services backed by 102 PowerShell modules
- MVVM with CommunityToolkit.Mvvm, Result&lt;T&gt; pattern, DI, dark theme
- 1,800+ tests (xUnit + Pester); 0 StyleCop and 0 PSScriptAnalyzer violations
- BUILD.md, RELEASE.md, docs/VERSIONING.md for build, release, and versioning
- docs/SIDELOAD.md for MSIX sideload installation
- docs/EULA.md and docs/PRIVACY.md for distribution
- docs/USER-GUIDE.md covering main features and getting started
- docs/MODULES.md documenting PowerShell modules and C# service mapping
- GitHub Actions CI: build, test, PSScriptAnalyzer, Pester; optional MSIX package job
- Initial PowerShell foundation (SystemOptimization, Privacy, PackageManager)

### Changed
- Navigation cleaned up: removed references to non-existent page types (build/runtime safe)

*For earlier history and work stream details, see [PLAN.md](../PLAN.md) and [Better11-STATUS.md](../Better11-STATUS.md).*
