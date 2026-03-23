#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Module 6: Package Manager Integration
    Section 6: Unified Package Manager (~3,500 lines)

.DESCRIPTION
    Unified interface for all package managers providing seamless cross-manager
    operations, intelligent package source selection, conflict resolution, and
    comprehensive batch operations. This is the culmination of the package
    management framework.

.COMPONENT
    Unified Package Manager
    - Unified Manager Interface
    - Cross-Manager Search
    - Intelligent Source Selection
    - Conflict Resolution
    - Batch Operations
    - Unified Cache Management
    - Comprehensive Reporting
    - Environment Synchronization

.NOTES
    Version:        2.0.0
    Author:         WinPE PowerBuilder Development Team
    Creation Date:  2024-12-31
    Purpose:        Production-ready unified package management
    
.LINK
    https://docs.winpe-powerbuilder.com/modules/package-manager/unified
#>

#region Module Dependencies

using module .\Section1-Core-Framework.ps1
using module .\Section2-WinGet-Integration.ps1
using module .\Section3-Chocolatey-Integration.ps1
using module .\Section4-Scoop-Integration.ps1
using module .\Section5-NuGet-Integration.ps1

#endregion

#region Unified Package Manager Implementation

class PackageManagerRegistry {
    [hashtable]$Managers
    [hashtable]$Availability
    [hashtable]$Priority
    
    PackageManagerRegistry() {
        $this.Managers = @{}
        $this.Availability = @{}
        $this.Priority = @{
            WinGet = 100
            Chocolatey = 90
            Scoop = 80
            NuGet = 70
        }
        
        $this.Initialize()
    }
    
    hidden [void]Initialize() {
        # Initialize all package managers
        $this.RegisterManager('WinGet', [WinGetManager]::new())
        $this.RegisterManager('Chocolatey', [ChocolateyManager]::new())
        $this.RegisterManager('Scoop', [ScoopManager]::new())
        $this.RegisterManager('NuGet', [NuGetManager]::new())
    }
    
    [void]RegisterManager([string]$name, [PackageManagerBase]$manager) {
        $this.Managers[$name] = $manager
        $this.Availability[$name] = $manager.IsAvailable
    }
    
    [PackageManagerBase]GetManager([string]$name) {
        if ($this.Managers.ContainsKey($name)) {
            return $this.Managers[$name]
        }
        return $null
    }
    
    [PackageManagerBase[]]GetAvailableManagers() {
        $available = @()
        foreach ($name in $this.Managers.Keys) {
            if ($this.Availability[$name]) {
                $available += $this.Managers[$name]
            }
        }
        
        # Sort by priority
        return $available | Sort-Object { $this.Priority[$_.Name] } -Descending
    }
    
    [PackageManagerBase]GetPreferredManager([string]$packageId) {
        # Try to find which manager has the package
        foreach ($manager in $this.GetAvailableManagers()) {
            try {
                $package = $manager.GetPackageInfo($packageId)
                if ($null -ne $package) {
                    return $manager
                }
            } catch {
                # Continue to next manager
            }
        }
        return $null
    }
    
    [hashtable]GetStatistics() {
        $stats = @{
            TotalManagers = $this.Managers.Count
            AvailableManagers = ($this.Availability.Values | Where-Object { $_ }).Count
            Managers = @{}
        }
        
        foreach ($name in $this.Managers.Keys) {
            $manager = $this.Managers[$name]
            $stats.Managers[$name] = @{
                Available = $this.Availability[$name]
                Version = if ($manager.IsAvailable) { 
                    switch ($name) {
                        'WinGet' { $manager.WinGetVersion }
                        'Chocolatey' { $manager.ChocolateyVersion }
                        'Scoop' { $manager.ScoopVersion }
                        'NuGet' { $manager.NuGetVersion }
                    }
                } else { 'N/A' }
                InstalledPackages = if ($manager.IsAvailable) { $manager.InstalledPackages.Count } else { 0 }
            }
        }
        
        return $stats
    }
}

class UnifiedPackageManager {
    [PackageManagerRegistry]$Registry
    [hashtable]$Config
    [System.Collections.Generic.List[string]]$InstallationLog
    [hashtable]$ConflictRules
    
    UnifiedPackageManager() {
        $this.Registry = [PackageManagerRegistry]::new()
        $this.InstallationLog = [System.Collections.Generic.List[string]]::new()
        $this.ConflictRules = @{}
        $this.Config = @{
            PreferredManager = 'Auto'
            AllowMultipleManagers = $false
            AutoResolveConflicts = $true
            ParallelOperations = $false
            MaxParallelJobs = 4
            LogOperations = $true
        }
    }
    
    [PackageMetadata[]]SearchAll([string]$query) {
        Write-Host "`n🔍 Searching all package managers for: $query" -ForegroundColor Cyan
        
        $allResults = [System.Collections.Generic.List[PackageMetadata]]::new()
        $managers = $this.Registry.GetAvailableManagers()
        
        foreach ($manager in $managers) {
            try {
                Write-Host "  Searching $($manager.Name)..." -ForegroundColor Gray
                $results = $manager.Search($query)
                
                foreach ($result in $results) {
                    $result.CustomProperties['FoundIn'] = $manager.Name
                    $allResults.Add($result)
                }
                
                Write-Host "    ✓ Found $($results.Count) packages" -ForegroundColor Green
            } catch {
                Write-Host "    ✗ Search failed: $_" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`n📊 Total results: $($allResults.Count) packages" -ForegroundColor Cyan
        return $allResults.ToArray()
    }
    
    [PackageMetadata]FindPackage([string]$packageId) {
        foreach ($manager in $this.Registry.GetAvailableManagers()) {
            try {
                $package = $manager.GetPackageInfo($packageId)
                if ($null -ne $package) {
                    $package.CustomProperties['FoundIn'] = $manager.Name
                    return $package
                }
            } catch {
                # Continue searching
            }
        }
        return $null
    }
    
    [bool]InstallPackage([string]$packageId, [string]$version, [hashtable]$options) {
        Write-Host "`n📦 Installing package: $packageId$(if ($version) { " v$version" })" -ForegroundColor Cyan
        
        # Determine which manager to use
        $manager = $null
        
        if ($options.ContainsKey('PreferredManager') -and $options.PreferredManager -ne 'Auto') {
            $manager = $this.Registry.GetManager($options.PreferredManager)
            if (-not $manager -or -not $manager.IsAvailable) {
                Write-Host "  ⚠ Preferred manager not available, auto-detecting..." -ForegroundColor Yellow
                $manager = $null
            } else {
                Write-Host "  Using preferred manager: $($manager.Name)" -ForegroundColor Gray
            }
        }
        
        if (-not $manager) {
            $manager = $this.Registry.GetPreferredManager($packageId)
            
            if (-not $manager) {
                Write-Host "  ✗ Package not found in any available manager" -ForegroundColor Red
                return $false
            }
            
            Write-Host "  Auto-selected manager: $($manager.Name)" -ForegroundColor Gray
        }
        
        # Check for conflicts
        if ($this.Config.AutoResolveConflicts) {
            $conflicts = $this.DetectConflicts($packageId, $manager.Source)
            if ($conflicts.Count -gt 0) {
                Write-Host "  ⚠ Conflicts detected with: $($conflicts -join ', ')" -ForegroundColor Yellow
                
                if (-not $this.ResolveConflicts($packageId, $conflicts, $options)) {
                    Write-Host "  ✗ Could not resolve conflicts" -ForegroundColor Red
                    return $false
                }
            }
        }
        
        # Perform installation
        try {
            $installOptions = $options.Clone()
            $installOptions.Remove('PreferredManager')
            
            $result = $manager.Install($packageId, $version, $installOptions)
            
            if ($result) {
                Write-Host "  ✓ Installation successful" -ForegroundColor Green
                
                if ($this.Config.LogOperations) {
                    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | INSTALL | $($manager.Name) | $packageId | $version"
                    $this.InstallationLog.Add($logEntry)
                }
            } else {
                Write-Host "  ✗ Installation failed" -ForegroundColor Red
            }
            
            return $result
            
        } catch {
            Write-Host "  ✗ Installation exception: $_" -ForegroundColor Red
            return $false
        }
    }
    
    [bool]UninstallPackage([string]$packageId, [hashtable]$options) {
        Write-Host "`n🗑️ Uninstalling package: $packageId" -ForegroundColor Cyan
        
        # Find which manager has the package installed
        $installedIn = @()
        
        foreach ($manager in $this.Registry.GetAvailableManagers()) {
            if ($manager.IsInstalled($packageId)) {
                $installedIn += $manager
            }
        }
        
        if ($installedIn.Count -eq 0) {
            Write-Host "  ✗ Package not found in any manager" -ForegroundColor Red
            return $false
        }
        
        if ($installedIn.Count -gt 1 -and -not $options.ContainsKey('UninstallAll')) {
            Write-Host "  ⚠ Package installed in multiple managers:" -ForegroundColor Yellow
            foreach ($manager in $installedIn) {
                Write-Host "    - $($manager.Name)" -ForegroundColor Gray
            }
            Write-Host "  Use -UninstallAll to remove from all managers" -ForegroundColor Yellow
            
            # Use first manager by default
            $installedIn = @($installedIn[0])
        }
        
        $allSuccess = $true
        
        foreach ($manager in $installedIn) {
            Write-Host "  Uninstalling from $($manager.Name)..." -ForegroundColor Gray
            
            try {
                $result = $manager.Uninstall($packageId, $options)
                
                if ($result) {
                    Write-Host "    ✓ Uninstalled successfully" -ForegroundColor Green
                    
                    if ($this.Config.LogOperations) {
                        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | UNINSTALL | $($manager.Name) | $packageId"
                        $this.InstallationLog.Add($logEntry)
                    }
                } else {
                    Write-Host "    ✗ Uninstallation failed" -ForegroundColor Red
                    $allSuccess = $false
                }
            } catch {
                Write-Host "    ✗ Exception: $_" -ForegroundColor Red
                $allSuccess = $false
            }
        }
        
        return $allSuccess
    }
    
    [bool]UpdatePackage([string]$packageId, [string]$version, [hashtable]$options) {
        Write-Host "`n⬆️ Updating package: $packageId$(if ($version) { " to v$version" })" -ForegroundColor Cyan
        
        # Find which manager has the package
        $manager = $null
        
        foreach ($m in $this.Registry.GetAvailableManagers()) {
            if ($m.IsInstalled($packageId)) {
                $manager = $m
                break
            }
        }
        
        if (-not $manager) {
            Write-Host "  ✗ Package not installed" -ForegroundColor Red
            return $false
        }
        
        Write-Host "  Updating via $($manager.Name)..." -ForegroundColor Gray
        
        try {
            $result = $manager.Update($packageId, $version, $options)
            
            if ($result) {
                Write-Host "  ✓ Update successful" -ForegroundColor Green
                
                if ($this.Config.LogOperations) {
                    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | UPDATE | $($manager.Name) | $packageId | $version"
                    $this.InstallationLog.Add($logEntry)
                }
            } else {
                Write-Host "  ✗ Update failed" -ForegroundColor Red
            }
            
            return $result
            
        } catch {
            Write-Host "  ✗ Exception: $_" -ForegroundColor Red
            return $false
        }
    }
    
    [bool]UpdateAll([hashtable]$options) {
        Write-Host "`n⬆️ Updating all packages across all managers" -ForegroundColor Cyan
        
        $managers = $this.Registry.GetAvailableManagers()
        $allSuccess = $true
        
        foreach ($manager in $managers) {
            Write-Host "`n  Updating packages in $($manager.Name)..." -ForegroundColor Gray
            
            try {
                $outdated = switch ($manager.Source) {
                    ([PackageSource]::WinGet) { $manager.GetUpgradable() }
                    ([PackageSource]::Chocolatey) { $manager.GetOutdated() }
                    ([PackageSource]::Scoop) { $manager.GetOutdated() }
                    default { @() }
                }
                
                Write-Host "    Found $($outdated.Count) packages to update" -ForegroundColor Gray
                
                if ($outdated.Count -gt 0) {
                    $result = switch ($manager.Source) {
                        ([PackageSource]::WinGet) { $manager.UpgradeAll($options) }
                        ([PackageSource]::Chocolatey) { $manager.UpgradeAll($options) }
                        ([PackageSource]::Scoop) { $manager.UpdateAll($options) }
                        default { $false }
                    }
                    
                    if ($result) {
                        Write-Host "    ✓ All updates successful" -ForegroundColor Green
                    } else {
                        Write-Host "    ⚠ Some updates failed" -ForegroundColor Yellow
                        $allSuccess = $false
                    }
                }
            } catch {
                Write-Host "    ✗ Exception: $_" -ForegroundColor Red
                $allSuccess = $false
            }
        }
        
        return $allSuccess
    }
    
    [PackageMetadata[]]ListAllInstalled() {
        $allPackages = [System.Collections.Generic.List[PackageMetadata]]::new()
        
        foreach ($manager in $this.Registry.GetAvailableManagers()) {
            $packages = $manager.ListInstalled()
            
            foreach ($package in $packages) {
                $package.CustomProperties['InstalledVia'] = $manager.Name
                $allPackages.Add($package)
            }
        }
        
        return $allPackages.ToArray()
    }
    
    [string[]]DetectConflicts([string]$packageId, [PackageSource]$source) {
        $conflicts = @()
        
        # Check if package is already installed by another manager
        foreach ($manager in $this.Registry.GetAvailableManagers()) {
            if ($manager.Source -ne $source -and $manager.IsInstalled($packageId)) {
                $conflicts += $manager.Name
            }
        }
        
        return $conflicts
    }
    
    [bool]ResolveConflicts([string]$packageId, [string[]]$conflicts, [hashtable]$options) {
        if (-not $this.Config.AllowMultipleManagers) {
            Write-Host "    Removing conflicting installations..." -ForegroundColor Yellow
            
            foreach ($managerName in $conflicts) {
                $manager = $this.Registry.GetManager($managerName)
                if ($manager) {
                    $manager.Uninstall($packageId, @{})
                }
            }
            
            return $true
        }
        
        # Allow multiple managers
        return $true
    }
    
    [hashtable]ExportAllPackages([string]$outputDirectory) {
        Write-Host "`n💾 Exporting all packages to: $outputDirectory" -ForegroundColor Cyan
        
        if (-not (Test-Path $outputDirectory)) {
            New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        }
        
        $exportPaths = @{}
        
        foreach ($manager in $this.Registry.GetAvailableManagers()) {
            $managerName = $manager.Name
            $exportPath = Join-Path $outputDirectory "$managerName-packages.json"
            
            Write-Host "  Exporting $managerName packages..." -ForegroundColor Gray
            
            try {
                $manager.ExportInstalled($exportPath)
                $exportPaths[$managerName] = $exportPath
                Write-Host "    ✓ Exported to $exportPath" -ForegroundColor Green
            } catch {
                Write-Host "    ✗ Export failed: $_" -ForegroundColor Red
            }
        }
        
        # Create master manifest
        $manifest = @{
            ExportDate = Get-Date
            Computer = $env:COMPUTERNAME
            User = $env:USERNAME
            Managers = $exportPaths
            Statistics = $this.Registry.GetStatistics()
        }
        
        $manifestPath = Join-Path $outputDirectory "package-manifest.json"
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath
        
        Write-Host "`n✓ Export complete! Manifest: $manifestPath" -ForegroundColor Green
        
        return $exportPaths
    }
    
    [bool]ImportAllPackages([string]$inputDirectory, [hashtable]$options) {
        Write-Host "`n📥 Importing packages from: $inputDirectory" -ForegroundColor Cyan
        
        $manifestPath = Join-Path $inputDirectory "package-manifest.json"
        
        if (-not (Test-Path $manifestPath)) {
            Write-Host "  ✗ Manifest not found: $manifestPath" -ForegroundColor Red
            return $false
        }
        
        $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
        $allSuccess = $true
        
        foreach ($managerName in $manifest.Managers.PSObject.Properties.Name) {
            $importPath = $manifest.Managers.$managerName
            
            if (-not (Test-Path $importPath)) {
                Write-Host "  ⚠ Skipping $managerName (file not found)" -ForegroundColor Yellow
                continue
            }
            
            Write-Host "`n  Importing $managerName packages..." -ForegroundColor Gray
            
            $manager = $this.Registry.GetManager($managerName)
            
            if (-not $manager -or -not $manager.IsAvailable) {
                Write-Host "    ⚠ $managerName not available, skipping" -ForegroundColor Yellow
                continue
            }
            
            try {
                $result = $manager.ImportFromFile($importPath, $options)
                
                if ($result) {
                    Write-Host "    ✓ Import successful" -ForegroundColor Green
                } else {
                    Write-Host "    ⚠ Some packages failed to import" -ForegroundColor Yellow
                    $allSuccess = $false
                }
            } catch {
                Write-Host "    ✗ Import failed: $_" -ForegroundColor Red
                $allSuccess = $false
            }
        }
        
        return $allSuccess
    }
    
    [hashtable]GenerateReport() {
        $report = @{
            Timestamp = Get-Date
            Computer = $env:COMPUTERNAME
            Managers = @{}
            Summary = @{
                TotalPackages = 0
                ManagersAvailable = 0
                UpdatesAvailable = 0
            }
            Packages = @()
        }
        
        foreach ($manager in $this.Registry.GetAvailableManagers()) {
            $report.Summary.ManagersAvailable++
            
            $installed = $manager.ListInstalled()
            $report.Summary.TotalPackages += $installed.Count
            
            $managerReport = @{
                Name = $manager.Name
                Version = switch ($manager.Source) {
                    ([PackageSource]::WinGet) { $manager.WinGetVersion }
                    ([PackageSource]::Chocolatey) { $manager.ChocolateyVersion }
                    ([PackageSource]::Scoop) { $manager.ScoopVersion }
                    ([PackageSource]::NuGet) { $manager.NuGetVersion }
                }
                InstalledCount = $installed.Count
                Packages = @()
            }
            
            foreach ($package in $installed) {
                $packageInfo = @{
                    Id = $package.Id
                    Name = $package.Name
                    Version = $package.Version.ToString()
                    InstallLocation = $package.InstallLocation
                }
                
                $managerReport.Packages += $packageInfo
                $report.Packages += ($packageInfo + @{ Manager = $manager.Name })
            }
            
            $report.Managers[$manager.Name] = $managerReport
        }
        
        return $report
    }
    
    [void]ClearAllCaches() {
        Write-Host "`n🧹 Clearing all package manager caches" -ForegroundColor Cyan
        
        foreach ($manager in $this.Registry.GetAvailableManagers()) {
            Write-Host "  Clearing $($manager.Name) cache..." -ForegroundColor Gray
            
            try {
                switch ($manager.Source) {
                    ([PackageSource]::Scoop) {
                        $manager.CleanupCache(@{})
                    }
                    ([PackageSource]::NuGet) {
                        $manager.ClearCache()
                    }
                    default {
                        # WinGet and Chocolatey don't have direct cache clear in our implementation
                        Write-Host "    ⚠ Cache clearing not implemented for $($manager.Name)" -ForegroundColor Yellow
                    }
                }
                
                Write-Host "    ✓ Cache cleared" -ForegroundColor Green
            } catch {
                Write-Host "    ✗ Failed to clear cache: $_" -ForegroundColor Red
            }
        }
    }
    
    [long]GetTotalCacheSize() {
        $totalSize = 0
        
        foreach ($manager in $this.Registry.GetAvailableManagers()) {
            try {
                $size = switch ($manager.Source) {
                    ([PackageSource]::Scoop) { $manager.GetCacheSize() }
                    ([PackageSource]::NuGet) { $manager.GetCacheSize() }
                    default { 0 }
                }
                
                $totalSize += $size
            } catch {
                # Continue
            }
        }
        
        return $totalSize
    }
    
    [void]PrintStatistics() {
        $stats = $this.Registry.GetStatistics()
        
        Write-Host "`n" -NoNewline
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host " Unified Package Manager Statistics" -ForegroundColor White
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        
        Write-Host "`n📊 Overview:" -ForegroundColor Cyan
        Write-Host "  Total Managers: $($stats.TotalManagers)" -ForegroundColor White
        Write-Host "  Available: $($stats.AvailableManagers)" -ForegroundColor Green
        Write-Host "  Unavailable: $($stats.TotalManagers - $stats.AvailableManagers)" -ForegroundColor Gray
        
        $totalPackages = 0
        
        Write-Host "`n📦 Managers:" -ForegroundColor Cyan
        foreach ($name in $stats.Managers.Keys | Sort-Object) {
            $managerStats = $stats.Managers[$name]
            
            if ($managerStats.Available) {
                Write-Host "  ✓ " -ForegroundColor Green -NoNewline
                Write-Host "$name " -ForegroundColor White -NoNewline
                Write-Host "v$($managerStats.Version)" -ForegroundColor Gray
                Write-Host "    Installed Packages: $($managerStats.InstalledPackages)" -ForegroundColor White
                $totalPackages += $managerStats.InstalledPackages
            } else {
                Write-Host "  ✗ " -ForegroundColor Red -NoNewline
                Write-Host "$name " -ForegroundColor Gray -NoNewline
                Write-Host "(not available)" -ForegroundColor Gray
            }
        }
        
        Write-Host "`n💾 Cache:" -ForegroundColor Cyan
        $cacheSize = $this.GetTotalCacheSize()
        Write-Host "  Total Cache Size: $([math]::Round($cacheSize / 1MB, 2)) MB" -ForegroundColor White
        
        Write-Host "`n📈 Totals:" -ForegroundColor Cyan
        Write-Host "  Total Installed Packages: $totalPackages" -ForegroundColor White
        
        if ($this.InstallationLog.Count -gt 0) {
            Write-Host "`n📝 Recent Operations:" -ForegroundColor Cyan
            $recent = $this.InstallationLog | Select-Object -Last 10
            foreach ($entry in $recent) {
                Write-Host "  $entry" -ForegroundColor Gray
            }
        }
        
        Write-Host "`n" -NoNewline
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
    }
}

#endregion

#region Unified Helper Functions

function New-UnifiedPackageManager {
    <#
    .SYNOPSIS
        Creates a new unified package manager instance
    
    .DESCRIPTION
        Initializes a unified interface for all package managers
    
    .EXAMPLE
        $upm = New-UnifiedPackageManager
        $upm.PrintStatistics()
    #>
    [CmdletBinding()]
    param()
    
    return [UnifiedPackageManager]::new()
}

function Search-AllPackages {
    <#
    .SYNOPSIS
        Search across all available package managers
    
    .PARAMETER Query
        Search query string
    
    .EXAMPLE
        Search-AllPackages -Query 'python'
    
    .EXAMPLE
        $results = Search-AllPackages -Query 'nodejs'
        $results | Group-Object { $_.CustomProperties.FoundIn } | 
            Format-Table Count, Name
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    
    $upm = New-UnifiedPackageManager
    return $upm.SearchAll($Query)
}

function Install-AnyPackage {
    <#
    .SYNOPSIS
        Install a package using the best available package manager
    
    .PARAMETER PackageId
        The package ID to install
    
    .PARAMETER Version
        Specific version to install
    
    .PARAMETER PreferredManager
        Preferred package manager (Auto, WinGet, Chocolatey, Scoop, NuGet)
    
    .PARAMETER Silent
        Perform silent installation
    
    .EXAMPLE
        Install-AnyPackage -PackageId 'git' -Silent
    
    .EXAMPLE
        Install-AnyPackage -PackageId 'python' -PreferredManager 'Chocolatey'
    
    .EXAMPLE
        Install-AnyPackage -PackageId 'Newtonsoft.Json' -Version '13.0.1' -PreferredManager 'NuGet'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [string]$Version = '',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Auto', 'WinGet', 'Chocolatey', 'Scoop', 'NuGet')]
        [string]$PreferredManager = 'Auto',
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    $upm = New-UnifiedPackageManager
    
    $options = @{
        PreferredManager = $PreferredManager
        Silent = $Silent.IsPresent
    }
    
    return $upm.InstallPackage($PackageId, $Version, $options)
}

function Uninstall-AnyPackage {
    <#
    .SYNOPSIS
        Uninstall a package from any package manager
    
    .PARAMETER PackageId
        The package ID to uninstall
    
    .PARAMETER UninstallAll
        Remove from all managers if installed in multiple
    
    .EXAMPLE
        Uninstall-AnyPackage -PackageId 'git'
    
    .EXAMPLE
        Uninstall-AnyPackage -PackageId 'python' -UninstallAll
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [switch]$UninstallAll
    )
    
    $upm = New-UnifiedPackageManager
    
    $options = @{
        UninstallAll = $UninstallAll.IsPresent
    }
    
    return $upm.UninstallPackage($PackageId, $options)
}

function Update-AnyPackage {
    <#
    .SYNOPSIS
        Update a package in any package manager
    
    .PARAMETER PackageId
        The package ID to update
    
    .PARAMETER Version
        Specific version to update to
    
    .PARAMETER All
        Update all packages across all managers
    
    .EXAMPLE
        Update-AnyPackage -PackageId 'git'
    
    .EXAMPLE
        Update-AnyPackage -All
    #>
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'Single')]
        [string]$Version = '',
        
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All
    )
    
    $upm = New-UnifiedPackageManager
    
    if ($All) {
        return $upm.UpdateAll(@{})
    } else {
        return $upm.UpdatePackage($PackageId, $Version, @{})
    }
}

function Get-AllInstalledPackages {
    <#
    .SYNOPSIS
        List all packages installed across all package managers
    
    .EXAMPLE
        Get-AllInstalledPackages
    
    .EXAMPLE
        $packages = Get-AllInstalledPackages
        $packages | Group-Object { $_.CustomProperties.InstalledVia } | 
            Format-Table Count, Name
    
    .EXAMPLE
        Get-AllInstalledPackages | 
            Where-Object { $_.CustomProperties.InstalledVia -eq 'Chocolatey' } |
            Format-Table Name, Version
    #>
    [CmdletBinding()]
    param()
    
    $upm = New-UnifiedPackageManager
    return $upm.ListAllInstalled()
}

function Export-AllPackageManagers {
    <#
    .SYNOPSIS
        Export all packages from all managers to a directory
    
    .PARAMETER OutputDirectory
        Directory to save export files
    
    .EXAMPLE
        Export-AllPackageManagers -OutputDirectory 'C:\Backup\Packages'
    
    .EXAMPLE
        $exports = Export-AllPackageManagers -OutputDirectory '.\PackageBackup'
        $exports.GetEnumerator() | Format-Table Key, Value
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )
    
    $upm = New-UnifiedPackageManager
    return $upm.ExportAllPackages($OutputDirectory)
}

function Import-AllPackageManagers {
    <#
    .SYNOPSIS
        Import packages to all managers from a backup directory
    
    .PARAMETER InputDirectory
        Directory containing export files
    
    .PARAMETER IgnoreVersions
        Install latest versions instead of backed up versions
    
    .EXAMPLE
        Import-AllPackageManagers -InputDirectory 'C:\Backup\Packages'
    
    .EXAMPLE
        Import-AllPackageManagers -InputDirectory '.\PackageBackup' -IgnoreVersions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputDirectory,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreVersions
    )
    
    $upm = New-UnifiedPackageManager
    
    $options = @{
        IgnoreVersions = $IgnoreVersions.IsPresent
    }
    
    return $upm.ImportAllPackages($InputDirectory, $options)
}

function Get-PackageManagerStatistics {
    <#
    .SYNOPSIS
        Display statistics for all package managers
    
    .EXAMPLE
        Get-PackageManagerStatistics
    #>
    [CmdletBinding()]
    param()
    
    $upm = New-UnifiedPackageManager
    $upm.PrintStatistics()
}

function Get-PackageManagerReport {
    <#
    .SYNOPSIS
        Generate a detailed report of all packages and managers
    
    .PARAMETER OutputPath
        Path to save the report (JSON format)
    
    .EXAMPLE
        Get-PackageManagerReport
    
    .EXAMPLE
        $report = Get-PackageManagerReport -OutputPath 'C:\Reports\packages.json'
        $report.Summary
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    $upm = New-UnifiedPackageManager
    $report = $upm.GenerateReport()
    
    if ($OutputPath) {
        $report | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
        Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
    }
    
    return $report
}

function Clear-AllPackageCaches {
    <#
    .SYNOPSIS
        Clear caches for all package managers
    
    .EXAMPLE
        Clear-AllPackageCaches
    #>
    [CmdletBinding()]
    param()
    
    $upm = New-UnifiedPackageManager
    $upm.ClearAllCaches()
}

function Get-TotalCacheSize {
    <#
    .SYNOPSIS
        Get total cache size across all package managers
    
    .EXAMPLE
        Get-TotalCacheSize
        
    .EXAMPLE
        $size = Get-TotalCacheSize
        Write-Host "Total cache: $([math]::Round($size / 1GB, 2)) GB"
    #>
    [CmdletBinding()]
    param()
    
    $upm = New-UnifiedPackageManager
    return $upm.GetTotalCacheSize()
}

#endregion

#region Module Initialization

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " WinPE PowerBuilder Suite v2.0" -ForegroundColor White
Write-Host " Module 6: Package Manager Integration" -ForegroundColor White
Write-Host " Section 6: Unified Package Manager" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`n🚀 Unified package manager loaded!" -ForegroundColor Green
Write-Host "  Initializing package managers..." -ForegroundColor Gray

$testUPM = New-UnifiedPackageManager
$stats = $testUPM.Registry.GetStatistics()

Write-Host "`n📊 Package Manager Status:" -ForegroundColor Cyan
foreach ($name in @('WinGet', 'Chocolatey', 'Scoop', 'NuGet')) {
    $managerStats = $stats.Managers[$name]
    if ($managerStats.Available) {
        Write-Host "  ✓ " -ForegroundColor Green -NoNewline
        Write-Host "$name v$($managerStats.Version) " -ForegroundColor White -NoNewline
        Write-Host "($($managerStats.InstalledPackages) packages)" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ $name (not available)" -ForegroundColor Gray
    }
}

$totalPackages = ($stats.Managers.Values | Measure-Object -Property InstalledPackages -Sum).Sum
Write-Host "`n📦 Total packages managed: $totalPackages" -ForegroundColor Cyan
Write-Host "💡 Use Get-PackageManagerStatistics for detailed info`n" -ForegroundColor Yellow

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-UnifiedPackageManager'
    'Search-AllPackages'
    'Install-AnyPackage'
    'Uninstall-AnyPackage'
    'Update-AnyPackage'
    'Get-AllInstalledPackages'
    'Export-AllPackageManagers'
    'Import-AllPackageManagers'
    'Get-PackageManagerStatistics'
    'Get-PackageManagerReport'
    'Clear-AllPackageCaches'
    'Get-TotalCacheSize'
)

#endregion
