#Requires -Version 7.4

<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Module 6: Package Manager Integration
    Section 5: NuGet Integration (~2,500 lines)

.DESCRIPTION
    Complete integration with NuGet package manager including package search,
    installation, updates, custom feeds, and package restoration. Supports
    both NuGet CLI and PowerShell package management.

.COMPONENT
    NuGet Integration
    - NuGet CLI Integration
    - PowerShell PackageManagement Integration
    - Package.config Support
    - Custom Feed Management
    - Package Restore Operations
    - Framework-Specific Resolution
    - Credential Management
    - Local Package Cache

.NOTES
    Version:        2.0.0
    Author:         WinPE PowerBuilder Development Team
    Creation Date:  2024-12-31
    Purpose:        Production-ready NuGet integration
    
.LINK
    https://docs.winpe-powerbuilder.com/modules/package-manager/nuget
#>

#region Module Dependencies

using module .\Section1-Core-Framework.ps1

#endregion

#region NuGet Manager Implementation

class NuGetManager : PackageManagerBase {
    [string]$NuGetVersion
    [string]$NuGetPath
    [string]$NuGetCachePath
    [string]$GlobalPackagesFolder
    [hashtable]$Sources
    [bool]$UsePackageManagement
    
    NuGetManager() : base('NuGet', [PackageSource]::NuGet) {
        $this.Sources = @{}
        $this.UsePackageManagement = $false
    }
    
    [bool]CheckAvailability() {
        try {
            # First, check for nuget.exe
            $nugetPaths = @(
                "$env:ProgramData\NuGet\nuget.exe"
                "$env:LOCALAPPDATA\NuGet\nuget.exe"
                "C:\Tools\nuget.exe"
            )
            
            # Try to find nuget.exe
            foreach ($path in $nugetPaths) {
                if (Test-Path $path) {
                    $this.ExecutablePath = $path
                    $this.NuGetPath = Split-Path $path -Parent
                    
                    # Get NuGet version
                    $versionOutput = & $this.ExecutablePath 2>&1
                    if ($versionOutput -match 'NuGet Version:\s*(\d+\.\d+\.\d+)') {
                        $this.NuGetVersion = $matches[1]
                    }
                    
                    $this.LogInfo("NuGet CLI found: v$($this.NuGetVersion)")
                    
                    # Set paths
                    $this.NuGetCachePath = "$env:LOCALAPPDATA\NuGet\Cache"
                    $this.GlobalPackagesFolder = "$env:USERPROFILE\.nuget\packages"
                    
                    return $true
                }
            }
            
            # Fallback: Check for PowerShell PackageManagement
            $packageProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
            
            if ($packageProvider) {
                $this.UsePackageManagement = $true
                $this.NuGetVersion = $packageProvider.Version.ToString()
                $this.LogInfo("NuGet via PackageManagement found: v$($this.NuGetVersion)")
                
                $this.NuGetCachePath = "$env:LOCALAPPDATA\NuGet\Cache"
                $this.GlobalPackagesFolder = "$env:USERPROFILE\.nuget\packages"
                
                return $true
            }
            
            $this.LogWarning("NuGet not found. Install from https://www.nuget.org/downloads")
            return $false
            
        } catch {
            $this.LogError("Failed to check NuGet availability: $_")
            return $false
        }
    }
    
    [void]LoadConfiguration() {
        try {
            if ($this.UsePackageManagement) {
                # Load sources from PackageManagement
                $sources = Get-PackageSource -ProviderName NuGet -ErrorAction SilentlyContinue
                
                foreach ($source in $sources) {
                    $this.Sources[$source.Name] = @{
                        Name = $source.Name
                        Location = $source.Location
                        Trusted = $source.IsTrusted
                        Registered = $source.IsRegistered
                    }
                }
            } else {
                # Load sources from NuGet CLI
                $sourcesOutput = & $this.ExecutablePath sources list 2>&1
                
                foreach ($line in $sourcesOutput) {
                    # Format: 1. Name [Enabled]
                    #         Location
                    if ($line -match '^\s*\d+\.\s+(.+?)\s+\[') {
                        $sourceName = $matches[1].Trim()
                        $this.Sources[$sourceName] = @{
                            Name = $sourceName
                            Enabled = $line -match '\[Enabled\]'
                        }
                    }
                }
            }
            
            $this.LogInfo("Loaded NuGet configuration: $($this.Sources.Count) sources")
            
        } catch {
            $this.LogWarning("Failed to load NuGet configuration: $_")
        }
    }
    
    [PackageMetadata[]]Search([string]$query) {
        try {
            $this.LogInfo("Searching for: $query")
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            
            if ($this.UsePackageManagement) {
                # Use Find-Package
                $foundPackages = Find-Package -Name "*$query*" -ProviderName NuGet -ErrorAction SilentlyContinue
                
                foreach ($pkg in $foundPackages) {
                    $metadata = [PackageMetadata]::new(
                        $pkg.Name,
                        $pkg.Version,
                        [PackageSource]::NuGet
                    )
                    
                    $metadata.Name = $pkg.Name
                    $metadata.Description = $pkg.Summary
                    
                    if ($pkg.Metadata) {
                        if ($pkg.Metadata.ContainsKey('authors')) {
                            $metadata.Author = $pkg.Metadata['authors']
                        }
                        if ($pkg.Metadata.ContainsKey('description')) {
                            $metadata.Description = $pkg.Metadata['description']
                        }
                        if ($pkg.Metadata.ContainsKey('projectUrl')) {
                            $metadata.Homepage = $pkg.Metadata['projectUrl']
                        }
                        if ($pkg.Metadata.ContainsKey('licenseUrl')) {
                            $metadata.License = $pkg.Metadata['licenseUrl']
                        }
                        if ($pkg.Metadata.ContainsKey('tags')) {
                            $metadata.Tags = $pkg.Metadata['tags'] -split '\s+'
                        }
                    }
                    
                    $packages.Add($metadata)
                }
            } else {
                # Use NuGet CLI
                $searchOutput = & $this.ExecutablePath list $query -PreRelease 2>&1
                
                foreach ($line in $searchOutput) {
                    # Format: PackageId Version
                    if ($line -match '^(\S+)\s+(\S+)') {
                        $packageId = $matches[1].Trim()
                        $version = $matches[2].Trim()
                        
                        $metadata = [PackageMetadata]::new(
                            $packageId,
                            $version,
                            [PackageSource]::NuGet
                        )
                        
                        $metadata.Name = $packageId
                        $packages.Add($metadata)
                    }
                }
            }
            
            $this.LogInfo("Found $($packages.Count) packages")
            return $packages.ToArray()
            
        } catch {
            $this.LogError("Search failed: $_")
            return @()
        }
    }
    
    [PackageMetadata]GetPackageInfo([string]$packageId) {
        try {
            $this.LogInfo("Getting package info: $packageId")
            
            if ($this.UsePackageManagement) {
                $pkg = Find-Package -Name $packageId -ProviderName NuGet -ErrorAction SilentlyContinue | 
                       Select-Object -First 1
                
                if (-not $pkg) {
                    return $null
                }
                
                $metadata = [PackageMetadata]::new(
                    $pkg.Name,
                    $pkg.Version,
                    [PackageSource]::NuGet
                )
                
                $metadata.Name = $pkg.Name
                $metadata.Description = $pkg.Summary
                
                if ($pkg.Metadata) {
                    if ($pkg.Metadata.ContainsKey('authors')) {
                        $metadata.Author = $pkg.Metadata['authors']
                    }
                    if ($pkg.Metadata.ContainsKey('owners')) {
                        $metadata.Publisher = $pkg.Metadata['owners']
                    }
                    if ($pkg.Metadata.ContainsKey('description')) {
                        $metadata.Description = $pkg.Metadata['description']
                    }
                    if ($pkg.Metadata.ContainsKey('projectUrl')) {
                        $metadata.Homepage = $pkg.Metadata['projectUrl']
                    }
                    if ($pkg.Metadata.ContainsKey('licenseUrl')) {
                        $metadata.License = $pkg.Metadata['licenseUrl']
                    }
                    if ($pkg.Metadata.ContainsKey('tags')) {
                        $metadata.Tags = $pkg.Metadata['tags'] -split '\s+'
                    }
                    if ($pkg.Metadata.ContainsKey('dependencies')) {
                        # Parse dependencies
                        $deps = $pkg.Metadata['dependencies'] -split '\|'
                        foreach ($dep in $deps) {
                            if ($dep -match '(.+?):(\[?[\d.]+\]?)') {
                                $depId = $matches[1].Trim()
                                $depVersion = $matches[2].Trim() -replace '[\[\]]', ''
                                $metadata.AddDependency($depId, $depVersion, [DependencyType]::Required)
                            }
                        }
                    }
                }
                
                # Check if installed
                $installed = Get-Package -Name $packageId -ProviderName NuGet -ErrorAction SilentlyContinue
                if ($installed) {
                    $metadata.Status = [PackageStatus]::Installed
                }
                
                return $metadata
                
            } else {
                # Use NuGet CLI - limited info available
                $listOutput = & $this.ExecutablePath list $packageId -AllVersions 2>&1
                
                $versions = @()
                foreach ($line in $listOutput) {
                    if ($line -match "^$packageId\s+(\S+)") {
                        $versions += $matches[1].Trim()
                    }
                }
                
                if ($versions.Count -eq 0) {
                    return $null
                }
                
                # Get latest version
                $latestVersion = $versions | Sort-Object { [PackageVersion]::new($_) } -Descending | Select-Object -First 1
                
                $metadata = [PackageMetadata]::new(
                    $packageId,
                    $latestVersion,
                    [PackageSource]::NuGet
                )
                
                $metadata.Name = $packageId
                
                return $metadata
            }
            
        } catch {
            $this.LogError("Failed to get package info: $_")
            return $null
        }
    }
    
    [bool]Install([string]$packageId, [string]$version, [hashtable]$options) {
        try {
            $this.LogInfo("Installing $packageId$(if ($version) { " v$version" })")
            
            if ($this.UsePackageManagement) {
                # Use Install-Package
                $installArgs = @{
                    Name = $packageId
                    ProviderName = 'NuGet'
                    Force = $true
                }
                
                if (-not [string]::IsNullOrEmpty($version)) {
                    $installArgs.RequiredVersion = $version
                }
                
                if ($options.Source) {
                    $installArgs.Source = $options.Source
                }
                
                if ($options.Scope) {
                    $installArgs.Scope = $options.Scope
                }
                
                $result = Install-Package @installArgs -ErrorAction SilentlyContinue
                
                $success = $null -ne $result
                
            } else {
                # Use NuGet CLI
                $installArgs = @('install', $packageId)
                
                if (-not [string]::IsNullOrEmpty($version)) {
                    $installArgs += '-Version', $version
                }
                
                # Output directory
                $outputDir = $options.OutputDirectory ?? '.\packages'
                $installArgs += '-OutputDirectory', $outputDir
                
                # Source
                if ($options.Source) {
                    $installArgs += '-Source', $options.Source
                }
                
                # No cache
                if ($options.NoCache) {
                    $installArgs += '-NoCache'
                }
                
                # Pre-release
                if ($options.PreRelease) {
                    $installArgs += '-PreRelease'
                }
                
                # Framework
                if ($options.Framework) {
                    $installArgs += '-Framework', $options.Framework
                }
                
                # Execute installation
                $output = & $this.ExecutablePath $installArgs 2>&1
                
                $success = $LASTEXITCODE -eq 0
            }
            
            if ($success) {
                $this.LogInfo("Installation successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogError("Installation failed")
            }
            
            return $success
            
        } catch {
            $this.LogError("Installation exception: $_")
            return $false
        }
    }
    
    [bool]Uninstall([string]$packageId, [hashtable]$options) {
        try {
            $this.LogInfo("Uninstalling $packageId")
            
            if ($this.UsePackageManagement) {
                $result = Uninstall-Package -Name $packageId -ProviderName NuGet -Force -ErrorAction SilentlyContinue
                $success = $null -ne $result
            } else {
                # NuGet CLI doesn't have uninstall - remove from packages folder
                $packagesDir = $options.PackagesDirectory ?? '.\packages'
                $packagePath = Get-ChildItem -Path $packagesDir -Filter "$packageId.*" -Directory | 
                               Select-Object -First 1
                
                if ($packagePath) {
                    Remove-Item -Path $packagePath.FullName -Recurse -Force
                    $success = $true
                } else {
                    $this.LogWarning("Package not found in packages directory")
                    $success = $false
                }
            }
            
            if ($success) {
                $this.LogInfo("Uninstallation successful")
                $this.RefreshInstalledPackages()
            }
            
            return $success
            
        } catch {
            $this.LogError("Uninstallation exception: $_")
            return $false
        }
    }
    
    [bool]Update([string]$packageId, [string]$version, [hashtable]$options) {
        try {
            $this.LogInfo("Updating $packageId$(if ($version) { " to v$version" })")
            
            if ($this.UsePackageManagement) {
                $updateArgs = @{
                    Name = $packageId
                    ProviderName = 'NuGet'
                    Force = $true
                }
                
                if (-not [string]::IsNullOrEmpty($version)) {
                    $updateArgs.RequiredVersion = $version
                }
                
                $result = Update-Package @updateArgs -ErrorAction SilentlyContinue
                $success = $null -ne $result
                
            } else {
                # Use NuGet CLI update
                $updateArgs = @('update', $packageId)
                
                if (-not [string]::IsNullOrEmpty($version)) {
                    $updateArgs += '-Version', $version
                }
                
                if ($options.Source) {
                    $updateArgs += '-Source', $options.Source
                }
                
                if ($options.PreRelease) {
                    $updateArgs += '-PreRelease'
                }
                
                $output = & $this.ExecutablePath $updateArgs 2>&1
                $success = $LASTEXITCODE -eq 0
            }
            
            if ($success) {
                $this.LogInfo("Update successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogError("Update failed")
            }
            
            return $success
            
        } catch {
            $this.LogError("Update exception: $_")
            return $false
        }
    }
    
    [PackageMetadata[]]ListInstalled() {
        try {
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            
            if ($this.UsePackageManagement) {
                $installed = Get-Package -ProviderName NuGet -ErrorAction SilentlyContinue
                
                foreach ($pkg in $installed) {
                    $metadata = [PackageMetadata]::new(
                        $pkg.Name,
                        $pkg.Version,
                        [PackageSource]::NuGet
                    )
                    
                    $metadata.Name = $pkg.Name
                    $metadata.Status = [PackageStatus]::Installed
                    
                    if ($pkg.Source) {
                        $metadata.CustomProperties['Source'] = $pkg.Source
                    }
                    
                    $packages.Add($metadata)
                }
            } else {
                # List from global packages folder
                if (Test-Path $this.GlobalPackagesFolder) {
                    $packageDirs = Get-ChildItem -Path $this.GlobalPackagesFolder -Directory
                    
                    foreach ($dir in $packageDirs) {
                        $versionDirs = Get-ChildItem -Path $dir.FullName -Directory
                        
                        foreach ($versionDir in $versionDirs) {
                            $metadata = [PackageMetadata]::new(
                                $dir.Name,
                                $versionDir.Name,
                                [PackageSource]::NuGet
                            )
                            
                            $metadata.Name = $dir.Name
                            $metadata.Status = [PackageStatus]::Installed
                            $metadata.InstallLocation = $versionDir.FullName
                            
                            $packages.Add($metadata)
                        }
                    }
                }
            }
            
            return $packages.ToArray()
            
        } catch {
            $this.LogError("Failed to list installed packages: $_")
            return @()
        }
    }
    
    [bool]RestorePackages([string]$configPath, [hashtable]$options) {
        try {
            $this.LogInfo("Restoring packages from: $configPath")
            
            if (-not (Test-Path $configPath)) {
                $this.LogError("Config file not found: $configPath")
                return $false
            }
            
            if ($this.UsePackageManagement) {
                # Parse packages.config and install each package
                [xml]$config = Get-Content -Path $configPath
                
                $successCount = 0
                $failCount = 0
                
                foreach ($package in $config.packages.package) {
                    $installOptions = @{
                        Source = $options.Source
                    }
                    
                    if ($this.Install($package.id, $package.version, $installOptions)) {
                        $successCount++
                    } else {
                        $failCount++
                    }
                }
                
                $this.LogInfo("Restore complete: $successCount succeeded, $failCount failed")
                return $failCount -eq 0
                
            } else {
                # Use NuGet CLI restore
                $restoreArgs = @('restore', $configPath)
                
                if ($options.PackagesDirectory) {
                    $restoreArgs += '-PackagesDirectory', $options.PackagesDirectory
                }
                
                if ($options.Source) {
                    $restoreArgs += '-Source', $options.Source
                }
                
                if ($options.NoCache) {
                    $restoreArgs += '-NoCache'
                }
                
                $output = & $this.ExecutablePath $restoreArgs 2>&1
                
                $success = $LASTEXITCODE -eq 0
                
                if ($success) {
                    $this.LogInfo("Restore successful")
                } else {
                    $this.LogError("Restore failed")
                }
                
                return $success
            }
            
        } catch {
            $this.LogError("Restore exception: $_")
            return $false
        }
    }
    
    [void]AddSource([string]$name, [string]$location, [hashtable]$options) {
        try {
            $this.LogInfo("Adding source: $name ($location)")
            
            if ($this.UsePackageManagement) {
                $registerArgs = @{
                    Name = $name
                    Location = $location
                    ProviderName = 'NuGet'
                }
                
                if ($options.Trusted) {
                    $registerArgs.Trusted = $true
                }
                
                Register-PackageSource @registerArgs -Force | Out-Null
                
            } else {
                $sourceArgs = @('sources', 'add', '-Name', $name, '-Source', $location)
                
                if ($options.UserName -and $options.Password) {
                    $sourceArgs += '-UserName', $options.UserName
                    $sourceArgs += '-Password', $options.Password
                }
                
                & $this.ExecutablePath $sourceArgs 2>&1 | Out-Null
            }
            
            if ($LASTEXITCODE -eq 0 -or $this.UsePackageManagement) {
                $this.LogInfo("Source added successfully")
                $this.LoadConfiguration()
            } else {
                $this.LogError("Failed to add source")
            }
            
        } catch {
            $this.LogError("Add source exception: $_")
        }
    }
    
    [void]RemoveSource([string]$name) {
        try {
            $this.LogInfo("Removing source: $name")
            
            if ($this.UsePackageManagement) {
                Unregister-PackageSource -Name $name -ProviderName NuGet -Force -ErrorAction SilentlyContinue
            } else {
                & $this.ExecutablePath sources remove -Name $name 2>&1 | Out-Null
            }
            
            if ($LASTEXITCODE -eq 0 -or $this.UsePackageManagement) {
                $this.LogInfo("Source removed successfully")
                $this.LoadConfiguration()
            } else {
                $this.LogError("Failed to remove source")
            }
            
        } catch {
            $this.LogError("Remove source exception: $_")
        }
    }
    
    [hashtable[]]ListSources() {
        try {
            $sources = @()
            
            if ($this.UsePackageManagement) {
                $packageSources = Get-PackageSource -ProviderName NuGet -ErrorAction SilentlyContinue
                
                foreach ($source in $packageSources) {
                    $sources += @{
                        Name = $source.Name
                        Location = $source.Location
                        Trusted = $source.IsTrusted
                        Registered = $source.IsRegistered
                    }
                }
            } else {
                $sourcesOutput = & $this.ExecutablePath sources list 2>&1
                
                $currentSource = $null
                foreach ($line in $sourcesOutput) {
                    if ($line -match '^\s*\d+\.\s+(.+?)\s+\[(Enabled|Disabled)\]') {
                        if ($currentSource) {
                            $sources += $currentSource
                        }
                        
                        $currentSource = @{
                            Name = $matches[1].Trim()
                            Enabled = $matches[2] -eq 'Enabled'
                        }
                    } elseif ($currentSource -and $line -match '^\s+(.+)$') {
                        $currentSource.Location = $matches[1].Trim()
                    }
                }
                
                if ($currentSource) {
                    $sources += $currentSource
                }
            }
            
            return $sources
            
        } catch {
            $this.LogError("Failed to list sources: $_")
            return @()
        }
    }
    
    [void]ClearCache() {
        try {
            $this.LogInfo("Clearing NuGet cache")
            
            if ($this.UsePackageManagement) {
                # Clear PackageManagement cache
                $cachePath = "$env:LOCALAPPDATA\PackageManagement\NuGet\Cache"
                if (Test-Path $cachePath) {
                    Remove-Item -Path $cachePath -Recurse -Force
                }
            } else {
                # Use NuGet CLI
                & $this.ExecutablePath locals all -clear 2>&1 | Out-Null
            }
            
            $this.LogInfo("Cache cleared successfully")
            
        } catch {
            $this.LogError("Clear cache exception: $_")
        }
    }
    
    [long]GetCacheSize() {
        try {
            $totalSize = 0
            
            $cachePaths = @(
                $this.NuGetCachePath
                $this.GlobalPackagesFolder
                "$env:LOCALAPPDATA\PackageManagement\NuGet\Cache"
            )
            
            foreach ($path in $cachePaths) {
                if (Test-Path $path) {
                    $size = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                             Measure-Object -Property Length -Sum).Sum
                    $totalSize += $size
                }
            }
            
            return $totalSize
            
        } catch {
            $this.LogError("Failed to get cache size: $_")
            return 0
        }
    }
    
    [void]ExportInstalled([string]$outputPath) {
        try {
            $this.LogInfo("Exporting installed packages to: $outputPath")
            
            $packages = $this.ListInstalled()
            
            $exportData = @{
                ExportDate = Get-Date
                NuGetVersion = $this.NuGetVersion
                Packages = @()
            }
            
            foreach ($package in $packages) {
                $exportData.Packages += @{
                    Id = $package.Id
                    Version = $package.Version.ToString()
                }
            }
            
            $exportData | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath
            
            $this.LogInfo("Export successful: $($packages.Count) packages")
            
        } catch {
            $this.LogError("Export exception: $_")
        }
    }
    
    [bool]ImportFromFile([string]$inputPath, [hashtable]$options) {
        try {
            $this.LogInfo("Importing packages from: $inputPath")
            
            if (-not (Test-Path $inputPath)) {
                $this.LogError("Import file not found: $inputPath")
                return $false
            }
            
            $importData = Get-Content -Path $inputPath -Raw | ConvertFrom-Json
            
            $successCount = 0
            $failCount = 0
            
            foreach ($package in $importData.Packages) {
                $version = if ($options.IgnoreVersions) { '' } else { $package.Version }
                
                $installOptions = @{}
                if ($options.Source) {
                    $installOptions.Source = $options.Source
                }
                
                if ($this.Install($package.Id, $version, $installOptions)) {
                    $successCount++
                } else {
                    $failCount++
                }
            }
            
            $this.LogInfo("Import complete: $successCount succeeded, $failCount failed")
            
            return $failCount -eq 0
            
        } catch {
            $this.LogError("Import exception: $_")
            return $false
        }
    }
}

#endregion

#region NuGet Helper Functions

function New-NuGetManager {
    <#
    .SYNOPSIS
        Creates a new NuGet package manager instance
    
    .EXAMPLE
        $nuget = New-NuGetManager
        $packages = $nuget.Search('newtonsoft')
    #>
    [CmdletBinding()]
    param()
    
    return [NuGetManager]::new()
}

function Install-NuGetPackage {
    <#
    .SYNOPSIS
        Install a NuGet package
    
    .PARAMETER PackageId
        The package ID to install
    
    .PARAMETER Version
        Specific version to install
    
    .PARAMETER Source
        Package source to use
    
    .PARAMETER OutputDirectory
        Directory to install packages to (CLI only)
    
    .PARAMETER Framework
        Target framework (CLI only)
    
    .PARAMETER PreRelease
        Include pre-release versions
    
    .PARAMETER NoCache
        Don't use the cache
    
    .PARAMETER Scope
        Installation scope (CurrentUser or AllUsers) - PackageManagement only
    
    .EXAMPLE
        Install-NuGetPackage -PackageId 'Newtonsoft.Json'
    
    .EXAMPLE
        Install-NuGetPackage -PackageId 'EntityFramework' -Version '6.4.4' -OutputDirectory '.\packages'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [string]$Version = '',
        
        [Parameter(Mandatory = $false)]
        [string]$Source,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDirectory,
        
        [Parameter(Mandatory = $false)]
        [string]$Framework,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreRelease,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoCache,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return $false
    }
    
    $options = @{
        PreRelease = $PreRelease.IsPresent
        NoCache = $NoCache.IsPresent
    }
    
    if ($Source) { $options.Source = $Source }
    if ($OutputDirectory) { $options.OutputDirectory = $OutputDirectory }
    if ($Framework) { $options.Framework = $Framework }
    if ($Scope) { $options.Scope = $Scope }
    
    return $nuget.Install($PackageId, $Version, $options)
}

function Uninstall-NuGetPackage {
    <#
    .SYNOPSIS
        Uninstall a NuGet package
    
    .PARAMETER PackageId
        The package ID to uninstall
    
    .PARAMETER PackagesDirectory
        Packages directory (CLI only)
    
    .EXAMPLE
        Uninstall-NuGetPackage -PackageId 'Newtonsoft.Json'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [string]$PackagesDirectory
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return $false
    }
    
    $options = @{}
    if ($PackagesDirectory) { $options.PackagesDirectory = $PackagesDirectory }
    
    return $nuget.Uninstall($PackageId, $options)
}

function Update-NuGetPackage {
    <#
    .SYNOPSIS
        Update a NuGet package
    
    .PARAMETER PackageId
        The package ID to update
    
    .PARAMETER Version
        Specific version to update to
    
    .PARAMETER Source
        Package source to use
    
    .PARAMETER PreRelease
        Include pre-release versions
    
    .EXAMPLE
        Update-NuGetPackage -PackageId 'Newtonsoft.Json'
    
    .EXAMPLE
        Update-NuGetPackage -PackageId 'EntityFramework' -PreRelease
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [string]$Version = '',
        
        [Parameter(Mandatory = $false)]
        [string]$Source,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreRelease
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return $false
    }
    
    $options = @{
        PreRelease = $PreRelease.IsPresent
    }
    
    if ($Source) { $options.Source = $Source }
    
    return $nuget.Update($PackageId, $Version, $options)
}

function Search-NuGetPackage {
    <#
    .SYNOPSIS
        Search for NuGet packages
    
    .PARAMETER Query
        Search query string
    
    .EXAMPLE
        Search-NuGetPackage -Query 'json'
    
    .EXAMPLE
        $packages = Search-NuGetPackage -Query 'entityframework'
        $packages | Format-Table Name, Version, Author
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return @()
    }
    
    return $nuget.Search($Query)
}

function Get-NuGetPackageInfo {
    <#
    .SYNOPSIS
        Get detailed information about a NuGet package
    
    .PARAMETER PackageId
        The package ID to query
    
    .EXAMPLE
        Get-NuGetPackageInfo -PackageId 'Newtonsoft.Json'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return $null
    }
    
    return $nuget.GetPackageInfo($PackageId)
}

function Get-NuGetInstalledPackages {
    <#
    .SYNOPSIS
        List all installed NuGet packages
    
    .EXAMPLE
        Get-NuGetInstalledPackages
    #>
    [CmdletBinding()]
    param()
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return @()
    }
    
    return $nuget.ListInstalled()
}

function Restore-NuGetPackages {
    <#
    .SYNOPSIS
        Restore NuGet packages from packages.config
    
    .PARAMETER ConfigPath
        Path to packages.config file
    
    .PARAMETER PackagesDirectory
        Directory to restore packages to
    
    .PARAMETER Source
        Package source to use
    
    .PARAMETER NoCache
        Don't use the cache
    
    .EXAMPLE
        Restore-NuGetPackages -ConfigPath '.\packages.config'
    
    .EXAMPLE
        Restore-NuGetPackages -ConfigPath '.\packages.config' -PackagesDirectory '.\packages' -NoCache
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$PackagesDirectory,
        
        [Parameter(Mandatory = $false)]
        [string]$Source,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return $false
    }
    
    $options = @{
        NoCache = $NoCache.IsPresent
    }
    
    if ($PackagesDirectory) { $options.PackagesDirectory = $PackagesDirectory }
    if ($Source) { $options.Source = $Source }
    
    return $nuget.RestorePackages($ConfigPath, $options)
}

function Add-NuGetSource {
    <#
    .SYNOPSIS
        Add a NuGet package source
    
    .PARAMETER Name
        Name of the source
    
    .PARAMETER Location
        URL of the source
    
    .PARAMETER Trusted
        Mark source as trusted (PackageManagement only)
    
    .PARAMETER UserName
        Username for authenticated feeds
    
    .PARAMETER Password
        Password for authenticated feeds
    
    .EXAMPLE
        Add-NuGetSource -Name 'CompanyFeed' -Location 'https://nuget.company.com/feed'
    
    .EXAMPLE
        Add-NuGetSource -Name 'PrivateFeed' -Location 'https://feed.example.com' -UserName 'user' -Password 'pass'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $false)]
        [switch]$Trusted,
        
        [Parameter(Mandatory = $false)]
        [string]$UserName,
        
        [Parameter(Mandatory = $false)]
        [string]$Password
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return
    }
    
    $options = @{
        Trusted = $Trusted.IsPresent
    }
    
    if ($UserName) { $options.UserName = $UserName }
    if ($Password) { $options.Password = $Password }
    
    $nuget.AddSource($Name, $Location, $options)
}

function Remove-NuGetSource {
    <#
    .SYNOPSIS
        Remove a NuGet package source
    
    .PARAMETER Name
        Name of the source to remove
    
    .EXAMPLE
        Remove-NuGetSource -Name 'CompanyFeed'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return
    }
    
    $nuget.RemoveSource($Name)
}

function Get-NuGetSources {
    <#
    .SYNOPSIS
        List all NuGet package sources
    
    .EXAMPLE
        Get-NuGetSources
    #>
    [CmdletBinding()]
    param()
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return @()
    }
    
    return $nuget.ListSources()
}

function Clear-NuGetCache {
    <#
    .SYNOPSIS
        Clear the NuGet package cache
    
    .EXAMPLE
        Clear-NuGetCache
    #>
    [CmdletBinding()]
    param()
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return
    }
    
    $nuget.ClearCache()
}

function Get-NuGetCacheSize {
    <#
    .SYNOPSIS
        Get the size of the NuGet cache
    
    .EXAMPLE
        Get-NuGetCacheSize
        
    .EXAMPLE
        $size = Get-NuGetCacheSize
        Write-Host "Cache size: $([math]::Round($size / 1GB, 2)) GB"
    #>
    [CmdletBinding()]
    param()
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return 0
    }
    
    return $nuget.GetCacheSize()
}

function Export-NuGetPackages {
    <#
    .SYNOPSIS
        Export installed NuGet packages to a JSON file
    
    .PARAMETER OutputPath
        Path to the output JSON file
    
    .EXAMPLE
        Export-NuGetPackages -OutputPath 'C:\Backup\nuget-packages.json'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return
    }
    
    $nuget.ExportInstalled($OutputPath)
}

function Import-NuGetPackages {
    <#
    .SYNOPSIS
        Import and install packages from a NuGet export file
    
    .PARAMETER InputPath
        Path to the input JSON file
    
    .PARAMETER IgnoreVersions
        Install latest versions instead of specified versions
    
    .PARAMETER Source
        Package source to use
    
    .EXAMPLE
        Import-NuGetPackages -InputPath 'C:\Backup\nuget-packages.json'
    
    .EXAMPLE
        Import-NuGetPackages -InputPath 'packages.json' -IgnoreVersions -Source 'https://api.nuget.org/v3/index.json'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreVersions,
        
        [Parameter(Mandatory = $false)]
        [string]$Source
    )
    
    $nuget = New-NuGetManager
    
    if (-not $nuget.IsAvailable) {
        Write-Error "NuGet is not available"
        return $false
    }
    
    $options = @{
        IgnoreVersions = $IgnoreVersions.IsPresent
    }
    
    if ($Source) { $options.Source = $Source }
    
    return $nuget.ImportFromFile($InputPath, $options)
}

#endregion

#region Module Initialization

Write-Host "NuGet integration module loaded!" -ForegroundColor Green

# Test NuGet availability
$testNuGet = New-NuGetManager
if ($testNuGet.IsAvailable) {
    $method = if ($testNuGet.UsePackageManagement) { 'PackageManagement' } else { 'CLI' }
    Write-Host "  NuGet $method: v$($testNuGet.NuGetVersion)" -ForegroundColor White
    Write-Host "  Sources: $($testNuGet.Sources.Count) configured" -ForegroundColor White
    $cacheSize = $testNuGet.GetCacheSize()
    Write-Host "  Cache Size: $([math]::Round($cacheSize / 1MB, 2)) MB" -ForegroundColor White
} else {
    Write-Host "  NuGet is not available on this system" -ForegroundColor Yellow
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-NuGetManager'
    'Install-NuGetPackage'
    'Uninstall-NuGetPackage'
    'Update-NuGetPackage'
    'Search-NuGetPackage'
    'Get-NuGetPackageInfo'
    'Get-NuGetInstalledPackages'
    'Restore-NuGetPackages'
    'Add-NuGetSource'
    'Remove-NuGetSource'
    'Get-NuGetSources'
    'Clear-NuGetCache'
    'Get-NuGetCacheSize'
    'Export-NuGetPackages'
    'Import-NuGetPackages'
)

#endregion
