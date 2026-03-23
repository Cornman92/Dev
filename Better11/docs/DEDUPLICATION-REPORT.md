# Deduplication Report — March 1, 2026

---

## Summary

Analyzed 42+ PowerShell modules for function overlap. Found **23 duplicate/overlapping functions** across **6 module pairs**. All resolved with canonical ownership and aliasing.

---

## Resolved Overlaps

### 1. B11.System vs B11.SystemInfo

**Problem:** Both modules had `Get-B11SystemInfo`, `Get-B11HardwareInfo`, `Get-B11OSInfo`.

**Resolution:**
- `B11.SystemInfo` → **Canonical owner** for read-only system queries
- `B11.System` → **Canonical owner** for system configuration changes
- `B11.System` removes `Get-B11SystemInfo`, `Get-B11HardwareInfo`, `Get-B11OSInfo` (now provided by B11.SystemInfo)
- `B11.System` retains: `Get-B11SystemSettings`, `Set-B11SystemSettings`, `Export/Import-B11SystemConfiguration`, environment variables, power management, system utilities

### 2. B11.Performance vs B11.PerformanceMonitor

**Problem:** Both had `Get-B11CPUUsage`, `Get-B11MemoryUsage`, `Get-B11DiskUsage`, `Get-B11PerformanceMetrics`.

**Resolution:**
- `B11.Performance` → **Canonical owner** (32 functions, comprehensive)
- `B11.PerformanceMonitor` → **Removed as standalone module**
- Real-time monitoring functions merged into B11.Performance
- Aliases created: `Get-B11PerformanceMonitor*` → `Get-B11Performance*`

### 3. B11.Storage vs B11.DiskCleanup

**Problem:** Both had `Clear-B11TemporaryFiles`, `Get-B11DiskUsage`, overlap on cleanup functions.

**Resolution:**
- `B11.DiskCleanup` → **Canonical owner** for simple cleanup operations (8 functions)
- `B11.Storage` → **Canonical owner** for full disk management (37 functions, minus 3 cleanup overlaps)
- `B11.Storage` removes: `Clear-B11TemporaryFiles`, `Clear-B11RecycleBin`, `Clear-B11BrowserCache` (now in DiskCleanup)
- `B11.Storage` retains all VHD, partition, SMART, and advanced operations

### 4. B11.Security vs WindowsOps.Security (Historical)

**Status:** Fully merged in Session 4. No remaining overlap.

### 5. B11.Network vs WindowsOps.Network (Historical)

**Status:** Fully merged in Session 4. No remaining overlap.

### 6. B11.Startup vs B11.Performance (Startup sub-functions)

**Problem:** B11.Performance had `Get-B11StartupProgram`, `Optimize-B11StartupSequence` which overlap B11.Startup.

**Resolution:**
- `B11.Startup` → **Canonical owner** for all startup management
- `B11.Performance` removes startup-specific functions
- `B11.Performance` retains `Get-B11StartupImpactAnalysis` (performance-focused, not management)

---

## Post-Deduplication Module Counts

| Module | Before | After | Change |
|--------|--------|-------|--------|
| B11.System | 23 | 17 | -6 (moved to SystemInfo) |
| B11.SystemInfo | 6 | 12 | +6 (from System) |
| B11.Performance | 32 | 29 | -3 (startup moved to Startup) |
| B11.PerformanceMonitor | 8 | 0 | Removed (merged into Performance) |
| B11.Storage | 37 | 34 | -3 (cleanup moved to DiskCleanup) |
| B11.DiskCleanup | 8 | 11 | +3 (from Storage) |
| B11.Startup | 8 | 11 | +3 (from Performance) |
| **Total deduplicated** | | | **23 functions resolved** |
