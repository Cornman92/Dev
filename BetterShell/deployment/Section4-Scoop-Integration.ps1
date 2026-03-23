#Requires -Version 7.4

<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Module 6: Package Manager Integration
    Section 4: Scoop Integration (~3,000 lines)

.DESCRIPTION
    Complete integration with Scoop package manager including package search,
    installation, updates, bucket management, and app manifests. Supports
    custom buckets and portable application management.

.COMPONENT
    Scoop Integration
    - Scoop CLI Integration
    - Bucket Management
    - Package Search & Discovery
    - Installation & Updates
    - Manifest Parser
    - Portable App Management
    - Shim Management
    - Cache Management

.NOTES
    Version:        2.0.0
    Author:         WinPE PowerBuilder Development Team
    Creation Date:  2024-12-31
    Purpose:        Production-ready Scoop integration
    
.LINK
    https://docs.winpe-powerbuilder.com/modules/package-manager/scoop
#>

#region Module Dependencies

using module .\Section1-Core-Framework.ps1

#endregion

#region Scoop Manager Implementation

class ScoopManager : PackageManagerBase {
    [string]$ScoopVersion
    [string]$ScoopPath
    [string]$ScoopAppsPath
    [string]$ScoopCachePath
    [System.Collections.Generic.List[hashtable]]$Buckets
    [hashtable]$GlobalApps
    
    ScoopManager() : base('Scoop', [PackageSource]::Scoop) {
        $this.Buckets = [System.Collections.Generic.List[hashtable]]::new()
        $this.GlobalApps = @{}
    }
    
    [bool]CheckAvailability() {
        try {
            # Check for scoop command
            $scoopCommand = Get-Command scoop -ErrorAction SilentlyContinue
            
            if ($scoopCommand) {
                $this.ExecutablePath = $scoopCommand.Source
                
                # Get Scoop paths
                $this.ScoopPath = $env:SCOOP ?? "$env:USERPROFILE\scoop"
                $this.ScoopAppsPath = Join-Path $this.ScoopPath 'apps'
                $this.ScoopCachePath = Join-Path $this.ScoopPath 'cache'
                
                # Get Scoop version
                $versionOutput = & scoop --version 2>&1
                if ($versionOutput -match 'v?(\d+\.\d+\.\d+)') {
                    $this.ScoopVersion = $matches[1]
                }
                
                $this.LogInfo("Scoop found: v$($this.ScoopVersion)")
                return $true
            }
            
            $this.LogWarning("Scoop not found. Install from https://scoop.sh")
            return $false
            
        } catch {
            $this.LogError("Failed to check Scoop availability: $_")
            return $false
        }
    }
    
    [void]LoadConfiguration() {
        try {
            # Load buckets
            $bucketsPath = Join-Path $this.ScoopPath 'buckets'
            
            if (Test-Path $bucketsPath) {
                $bucketDirs = Get-ChildItem -Path $bucketsPath -Directory
                
                foreach ($dir in $bucketDirs) {
                    $bucket = @{
                        Name = $dir.Name
                        Path = $dir.FullName
                        Updated = $dir.LastWriteTime
                    }
                    
                    # Try to get bucket URL from git config
                    $gitConfigPath = Join-Path $dir.FullName '.git\config'
                    if (Test-Path $gitConfigPath) {
                        $gitConfig = Get-Content $gitConfigPath -Raw
                        if ($gitConfig -match 'url\s*=\s*(.+)') {
                            $bucket.Url = $matches[1].Trim()
                        }
                    }
                    
                    $this.Buckets.Add($bucket)
                }
            }
            
            # Load global apps
            $globalPath = "$env:ProgramData\scoop\apps"
            if (Test-Path $globalPath) {
                $globalApps = Get-ChildItem -Path $globalPath -Directory
                foreach ($app in $globalApps) {
                    $this.GlobalApps[$app.Name] = $true
                }
            }
            
            $this.LogInfo("Loaded $($this.Buckets.Count) buckets, $($this.GlobalApps.Count) global apps")
            
        } catch {
            $this.LogWarning("Failed to load Scoop configuration: $_")
        }
    }
    
    [PackageMetadata[]]Search([string]$query) {
        try {
            $this.LogInfo("Searching for: $query")
            
            # Execute scoop search
            $searchOutput = & scoop search $query 2>&1
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            $inResults = $false
            
            foreach ($line in $searchOutput) {
                # Results start after "Results from..."
                if ($line -match '^Results from') {
                    $inResults = $true
                    continue
                }
                
                if ($inResults) {
                    # Format: 'bucket/app' (version) - description
                    if ($line -match "^\s*'([^/]+)/([^']+)'\s+\(([^)]+)\)") {
                        $bucket = $matches[1].Trim()
                        $appName = $matches[2].Trim()
                        $version = $matches[3].Trim()
                        
                        $metadata = [PackageMetadata]::new(
                            $appName,
                            $version,
                            [PackageSource]::Scoop
                        )
                        
                        $metadata.Name = $appName
                        $metadata.CustomProperties['Bucket'] = $bucket
                        
                        # Get description if present
                        if ($line -match '\)\s*-\s*(.+)$') {
                            $metadata.Description = $matches[1].Trim()
                        }
                        
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
            
            # Execute scoop info
            $infoOutput = & scoop info $packageId 2>&1 | Out-String
            
            if ($infoOutput -match 'not found|could not find') {
                return $null
            }
            
            # Parse info output
            $metadata = [PackageMetadata]::new($packageId, '0.0.0', [PackageSource]::Scoop)
            
            # Extract version
            if ($infoOutput -match 'Version:\s+(.+)') {
                $metadata.Version = [PackageVersion]::new($matches[1].Trim())
            }
            
            # Extract description
            if ($infoOutput -match 'Description:\s+(.+)') {
                $metadata.Description = $matches[1].Trim()
            }
            
            # Extract homepage
            if ($infoOutput -match 'Website:\s+(.+)') {
                $metadata.Homepage = $matches[1].Trim()
            }
            
            # Extract license
            if ($infoOutput -match 'License:\s+(.+)') {
                $metadata.License = $matches[1].Trim()
            }
            
            # Extract bucket
            if ($infoOutput -match 'Bucket:\s+(.+)') {
                $metadata.CustomProperties['Bucket'] = $matches[1].Trim()
            }
            
            # Extract binary/shim info
            if ($infoOutput -match 'Binaries:\s+(.+)') {
                $metadata.CustomProperties['Binaries'] = $matches[1].Trim()
            }
            
            # Check if installed
            $appPath = Join-Path $this.ScoopAppsPath $packageId
            if (Test-Path $appPath) {
                $metadata.Status = [PackageStatus]::Installed
                $metadata.InstallLocation = $appPath
                
                # Check if global
                $globalPath = "$env:ProgramData\scoop\apps\$packageId"
                if (Test-Path $globalPath) {
                    $metadata.CustomProperties['Global'] = $true
                }
            }
            
            return $metadata
            
        } catch {
            $this.LogError("Failed to get package info: $_")
            return $null
        }
    }
    
    [bool]Install([string]$packageId, [string]$version, [hashtable]$options) {
        try {
            $this.LogInfo("Installing $packageId$(if ($version) { " v$version" })")
            
            $installArgs = @('install', $packageId)
            
            # Global installation
            if ($options.Global) {
                $installArgs = @('install', $packageId, '--global')
            }
            
            # Skip hash check
            if ($options.SkipHashCheck) {
                $installArgs += '--skip'
            }
            
            # No cache
            if ($options.NoCache) {
                $installArgs += '--no-cache'
            }
            
            # Independent (don't install dependencies)
            if ($options.Independent) {
                $installArgs += '--independent'
            }
            
            # Specific architecture
            if ($options.Architecture) {
                $installArgs += '--arch', $options.Architecture
            }
            
            # Execute installation
            $output = & scoop $installArgs 2>&1
            
            # Check result
            $success = $LASTEXITCODE -eq 0
            
            if ($success) {
                $this.LogInfo("Installation successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogError("Installation failed with exit code: $LASTEXITCODE")
                $this.LogError($output | Out-String)
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
            
            $uninstallArgs = @('uninstall', $packageId)
            
            # Global uninstallation
            if ($options.Global) {
                $uninstallArgs += '--global'
            }
            
            # Purge (remove all versions and data)
            if ($options.Purge) {
                $uninstallArgs += '--purge'
            }
            
            # Execute uninstallation
            $output = & scoop $uninstallArgs 2>&1
            
            $success = $LASTEXITCODE -eq 0
            
            if ($success) {
                $this.LogInfo("Uninstallation successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogError("Uninstallation failed with exit code: $LASTEXITCODE")
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
            
            $updateArgs = @('update', $packageId)
            
            # Global update
            if ($options.Global) {
                $updateArgs += '--global'
            }
            
            # Force update
            if ($options.Force) {
                $updateArgs += '--force'
            }
            
            # Skip hash check
            if ($options.SkipHashCheck) {
                $updateArgs += '--skip'
            }
            
            # No cache
            if ($options.NoCache) {
                $updateArgs += '--no-cache'
            }
            
            # Independent
            if ($options.Independent) {
                $updateArgs += '--independent'
            }
            
            # Quiet
            if ($options.Quiet) {
                $updateArgs += '--quiet'
            }
            
            $output = & scoop $updateArgs 2>&1
            
            $success = $LASTEXITCODE -eq 0
            
            if ($success) {
                $this.LogInfo("Update successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogError("Update failed with exit code: $LASTEXITCODE")
            }
            
            return $success
            
        } catch {
            $this.LogError("Update exception: $_")
            return $false
        }
    }
    
    [PackageMetadata[]]ListInstalled() {
        try {
            # List local apps
            $listOutput = & scoop list 2>&1
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            $inList = $false
            
            foreach ($line in $listOutput) {
                # Skip header lines
                if ($line -match '^Installed apps:' -or $line -match '^Name\s+Version') {
                    $inList = $true
                    continue
                }
                
                if ($inList -and $line -match '^\s*(\S+)\s+(\S+)') {
                    $appName = $matches[1].Trim()
                    $version = $matches[2].Trim()
                    
                    $metadata = [PackageMetadata]::new(
                        $appName,
                        $version,
                        [PackageSource]::Scoop
                    )
                    
                    $metadata.Name = $appName
                    $metadata.Status = [PackageStatus]::Installed
                    
                    # Determine install location
                    $localPath = Join-Path $this.ScoopAppsPath $appName
                    $globalPath = "$env:ProgramData\scoop\apps\$appName"
                    
                    if (Test-Path $globalPath) {
                        $metadata.InstallLocation = $globalPath
                        $metadata.CustomProperties['Global'] = $true
                    } else {
                        $metadata.InstallLocation = $localPath
                    }
                    
                    # Check for updates
                    if ($line -match '\(Update to (\S+) available\)') {
                        $metadata.CustomProperties['AvailableVersion'] = $matches[1].Trim()
                    }
                    
                    $packages.Add($metadata)
                }
            }
            
            return $packages.ToArray()
            
        } catch {
            $this.LogError("Failed to list installed packages: $_")
            return @()
        }
    }
    
    [PackageMetadata[]]GetOutdated() {
        try {
            $statusOutput = & scoop status 2>&1
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            $inOutdated = $false
            
            foreach ($line in $statusOutput) {
                if ($line -match 'Updates are available for:') {
                    $inOutdated = $true
                    continue
                }
                
                if ($inOutdated -and $line -match '^\s+(\S+):\s+(\S+)\s+->\s+(\S+)') {
                    $appName = $matches[1].Trim()
                    $currentVersion = $matches[2].Trim()
                    $availableVersion = $matches[3].Trim()
                    
                    $metadata = [PackageMetadata]::new(
                        $appName,
                        $currentVersion,
                        [PackageSource]::Scoop
                    )
                    
                    $metadata.Name = $appName
                    $metadata.CustomProperties['AvailableVersion'] = $availableVersion
                    
                    $packages.Add($metadata)
                }
            }
            
            return $packages.ToArray()
            
        } catch {
            $this.LogError("Failed to get outdated packages: $_")
            return @()
        }
    }
    
    [bool]UpdateAll([hashtable]$options) {
        try {
            $this.LogInfo("Updating all packages")
            
            $updateArgs = @('update', '*')
            
            if ($options.Global) {
                $updateArgs += '--global'
            }
            
            if ($options.Force) {
                $updateArgs += '--force'
            }
            
            if ($options.Quiet) {
                $updateArgs += '--quiet'
            }
            
            $output = & scoop $updateArgs 2>&1
            
            $success = $LASTEXITCODE -eq 0
            
            if ($success) {
                $this.LogInfo("Update all successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogWarning("Some packages may have failed to update")
            }
            
            return $success
            
        } catch {
            $this.LogError("Update all exception: $_")
            return $false
        }
    }
    
    [bool]AddBucket([string]$name, [string]$url) {
        try {
            $this.LogInfo("Adding bucket: $name$(if ($url) { " ($url)" })")
            
            if ($url) {
                $output = & scoop bucket add $name $url 2>&1
            } else {
                $output = & scoop bucket add $name 2>&1
            }
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Bucket added successfully")
                $this.LoadConfiguration()  # Reload buckets
                return $true
            } else {
                $this.LogError("Failed to add bucket: $output")
                return $false
            }
            
        } catch {
            $this.LogError("Add bucket exception: $_")
            return $false
        }
    }
    
    [bool]RemoveBucket([string]$name) {
        try {
            $this.LogInfo("Removing bucket: $name")
            
            $output = & scoop bucket rm $name 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Bucket removed successfully")
                $this.LoadConfiguration()  # Reload buckets
                return $true
            } else {
                $this.LogError("Failed to remove bucket")
                return $false
            }
            
        } catch {
            $this.LogError("Remove bucket exception: $_")
            return $false
        }
    }
    
    [hashtable[]]ListBuckets() {
        try {
            $bucketOutput = & scoop bucket list 2>&1
            
            $buckets = @()
            
            foreach ($line in $bucketOutput) {
                # Format: Name Source Updated Manifests
                if ($line -match '^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\d+)') {
                    $buckets += @{
                        Name = $matches[1].Trim()
                        Source = $matches[2].Trim()
                        Updated = $matches[3].Trim()
                        Manifests = [int]$matches[4].Trim()
                    }
                }
            }
            
            return $buckets
            
        } catch {
            $this.LogError("Failed to list buckets: $_")
            return @()
        }
    }
    
    [bool]UpdateBuckets() {
        try {
            $this.LogInfo("Updating all buckets")
            
            $output = & scoop update 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Buckets updated successfully")
                return $true
            } else {
                $this.LogError("Failed to update buckets")
                return $false
            }
            
        } catch {
            $this.LogError("Update buckets exception: $_")
            return $false
        }
    }
    
    [void]CleanupCache([hashtable]$options) {
        try {
            $this.LogInfo("Cleaning up cache")
            
            $cleanupArgs = @('cache', 'rm', '*')
            
            if ($options.App) {
                $cleanupArgs = @('cache', 'rm', $options.App)
            }
            
            & scoop $cleanupArgs 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Cache cleanup successful")
            } else {
                $this.LogWarning("Cache cleanup completed with warnings")
            }
            
        } catch {
            $this.LogError("Cache cleanup exception: $_")
        }
    }
    
    [long]GetCacheSize() {
        try {
            if (Test-Path $this.ScoopCachePath) {
                $cacheSize = (Get-ChildItem -Path $this.ScoopCachePath -Recurse -File | 
                             Measure-Object -Property Length -Sum).Sum
                return $cacheSize
            }
            return 0
            
        } catch {
            $this.LogError("Failed to get cache size: $_")
            return 0
        }
    }
    
    [bool]ResetApp([string]$packageId) {
        try {
            $this.LogInfo("Resetting app: $packageId")
            
            $output = & scoop reset $packageId 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("App reset successful")
                return $true
            } else {
                $this.LogError("Failed to reset app")
                return $false
            }
            
        } catch {
            $this.LogError("Reset app exception: $_")
            return $false
        }
    }
    
    [hashtable]GetAppConfig([string]$packageId) {
        try {
            $configPath = Join-Path $this.ScoopAppsPath "$packageId\current\scoop-manifest.json"
            
            if (Test-Path $configPath) {
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json -AsHashtable
                return $config
            }
            
            return @{}
            
        } catch {
            $this.LogError("Failed to get app config: $_")
            return @{}
        }
    }
    
    [string[]]GetAppShims([string]$packageId) {
        try {
            $shimsPath = Join-Path $this.ScoopPath 'shims'
            $appPath = Join-Path $this.ScoopAppsPath "$packageId\current"
            
            $shims = @()
            
            if (Test-Path $shimsPath) {
                $shimFiles = Get-ChildItem -Path $shimsPath -File | 
                             Where-Object { $_.Target -like "*$packageId*" }
                
                foreach ($shim in $shimFiles) {
                    $shims += $shim.Name
                }
            }
            
            return $shims
            
        } catch {
            $this.LogError("Failed to get app shims: $_")
            return @()
        }
    }
    
    [void]ExportInstalled([string]$outputPath) {
        try {
            $this.LogInfo("Exporting installed packages to: $outputPath")
            
            $packages = $this.ListInstalled()
            
            $exportData = @{
                ExportDate = Get-Date
                ScoopVersion = $this.ScoopVersion
                Packages = @()
                Buckets = $this.ListBuckets()
            }
            
            foreach ($package in $packages) {
                $exportData.Packages += @{
                    Name = $package.Name
                    Version = $package.Version.ToString()
                    Global = $package.CustomProperties.ContainsKey('Global') -and $package.CustomProperties['Global']
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
            
            # First, add buckets
            if ($importData.Buckets) {
                foreach ($bucket in $importData.Buckets) {
                    $this.AddBucket($bucket.Name, $bucket.Source)
                }
            }
            
            # Then install packages
            $successCount = 0
            $failCount = 0
            
            foreach ($package in $importData.Packages) {
                $installOptions = @{
                    Global = $package.Global
                }
                
                $version = if ($options.IgnoreVersions) { '' } else { $package.Version }
                
                if ($this.Install($package.Name, $version, $installOptions)) {
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

#region Scoop Helper Functions

function New-ScoopManager {
    <#
    .SYNOPSIS
        Creates a new Scoop package manager instance
    
    .EXAMPLE
        $scoop = New-ScoopManager
        $packages = $scoop.Search('python')
    #>
    [CmdletBinding()]
    param()
    
    return [ScoopManager]::new()
}

function Install-ScoopPackage {
    <#
    .SYNOPSIS
        Install a package using Scoop
    
    .PARAMETER PackageId
        The package ID to install
    
    .PARAMETER Global
        Install globally for all users
    
    .PARAMETER SkipHashCheck
        Skip hash verification
    
    .PARAMETER NoCache
        Don't use the download cache
    
    .PARAMETER Independent
        Don't install dependencies
    
    .PARAMETER Architecture
        Specify architecture (32bit, 64bit, arm64)
    
    .EXAMPLE
        Install-ScoopPackage -PackageId 'git'
    
    .EXAMPLE
        Install-ScoopPackage -PackageId 'nodejs-lts' -Global
    
    .EXAMPLE
        Install-ScoopPackage -PackageId 'python' -Architecture '64bit'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [switch]$Global,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipHashCheck,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoCache,
        
        [Parameter(Mandatory = $false)]
        [switch]$Independent,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('32bit', '64bit', 'arm64')]
        [string]$Architecture
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return $false
    }
    
    $options = @{
        Global = $Global.IsPresent
        SkipHashCheck = $SkipHashCheck.IsPresent
        NoCache = $NoCache.IsPresent
        Independent = $Independent.IsPresent
    }
    
    if ($Architecture) { $options.Architecture = $Architecture }
    
    return $scoop.Install($PackageId, '', $options)
}

function Uninstall-ScoopPackage {
    <#
    .SYNOPSIS
        Uninstall a package using Scoop
    
    .PARAMETER PackageId
        The package ID to uninstall
    
    .PARAMETER Global
        Uninstall global installation
    
    .PARAMETER Purge
        Remove all versions and persistent data
    
    .EXAMPLE
        Uninstall-ScoopPackage -PackageId 'git'
    
    .EXAMPLE
        Uninstall-ScoopPackage -PackageId 'nodejs' -Purge
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [switch]$Global,
        
        [Parameter(Mandatory = $false)]
        [switch]$Purge
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return $false
    }
    
    $options = @{
        Global = $Global.IsPresent
        Purge = $Purge.IsPresent
    }
    
    return $scoop.Uninstall($PackageId, $options)
}

function Update-ScoopPackage {
    <#
    .SYNOPSIS
        Update a package using Scoop
    
    .PARAMETER PackageId
        The package ID to update
    
    .PARAMETER All
        Update all packages
    
    .PARAMETER Global
        Update global installations
    
    .PARAMETER Force
        Force update even if not outdated
    
    .PARAMETER Quiet
        Minimize output
    
    .EXAMPLE
        Update-ScoopPackage -PackageId 'git'
    
    .EXAMPLE
        Update-ScoopPackage -All -Global
    #>
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
        [string]$PackageId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All,
        
        [Parameter(Mandatory = $false)]
        [switch]$Global,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipHashCheck,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoCache,
        
        [Parameter(Mandatory = $false)]
        [switch]$Quiet
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return $false
    }
    
    $options = @{
        Global = $Global.IsPresent
        Force = $Force.IsPresent
        SkipHashCheck = $SkipHashCheck.IsPresent
        NoCache = $NoCache.IsPresent
        Quiet = $Quiet.IsPresent
    }
    
    if ($All) {
        return $scoop.UpdateAll($options)
    } else {
        return $scoop.Update($PackageId, '', $options)
    }
}

function Search-ScoopPackage {
    <#
    .SYNOPSIS
        Search for packages using Scoop
    
    .PARAMETER Query
        Search query string
    
    .EXAMPLE
        Search-ScoopPackage -Query 'python'
    
    .EXAMPLE
        $packages = Search-ScoopPackage -Query 'nodejs'
        $packages | Format-Table Name, Version, @{L='Bucket';E={$_.CustomProperties.Bucket}}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return @()
    }
    
    return $scoop.Search($Query)
}

function Get-ScoopPackageInfo {
    <#
    .SYNOPSIS
        Get detailed information about a Scoop package
    
    .PARAMETER PackageId
        The package ID to query
    
    .EXAMPLE
        Get-ScoopPackageInfo -PackageId 'git'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return $null
    }
    
    return $scoop.GetPackageInfo($PackageId)
}

function Get-ScoopInstalledPackages {
    <#
    .SYNOPSIS
        List all packages installed via Scoop
    
    .EXAMPLE
        Get-ScoopInstalledPackages
    
    .EXAMPLE
        $installed = Get-ScoopInstalledPackages
        $installed | Where-Object { $_.CustomProperties.Global }
    #>
    [CmdletBinding()]
    param()
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return @()
    }
    
    return $scoop.ListInstalled()
}

function Get-ScoopOutdatedPackages {
    <#
    .SYNOPSIS
        List all packages that have updates available
    
    .EXAMPLE
        Get-ScoopOutdatedPackages
    
    .EXAMPLE
        $outdated = Get-ScoopOutdatedPackages
        $outdated | ForEach-Object {
            Write-Host "$($_.Name): $($_.Version) -> $($_.CustomProperties.AvailableVersion)"
        }
    #>
    [CmdletBinding()]
    param()
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return @()
    }
    
    return $scoop.GetOutdated()
}

function Add-ScoopBucket {
    <#
    .SYNOPSIS
        Add a Scoop bucket
    
    .PARAMETER Name
        Name of the bucket
    
    .PARAMETER Url
        URL of the bucket repository
    
    .EXAMPLE
        Add-ScoopBucket -Name 'extras'
    
    .EXAMPLE
        Add-ScoopBucket -Name 'my-bucket' -Url 'https://github.com/user/scoop-bucket'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Url
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return $false
    }
    
    return $scoop.AddBucket($Name, $Url)
}

function Remove-ScoopBucket {
    <#
    .SYNOPSIS
        Remove a Scoop bucket
    
    .PARAMETER Name
        Name of the bucket to remove
    
    .EXAMPLE
        Remove-ScoopBucket -Name 'extras'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return $false
    }
    
    return $scoop.RemoveBucket($Name)
}

function Get-ScoopBuckets {
    <#
    .SYNOPSIS
        List all Scoop buckets
    
    .EXAMPLE
        Get-ScoopBuckets
    #>
    [CmdletBinding()]
    param()
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return @()
    }
    
    return $scoop.ListBuckets()
}

function Update-ScoopBuckets {
    <#
    .SYNOPSIS
        Update all Scoop buckets
    
    .EXAMPLE
        Update-ScoopBuckets
    #>
    [CmdletBinding()]
    param()
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return $false
    }
    
    return $scoop.UpdateBuckets()
}

function Clear-ScoopCache {
    <#
    .SYNOPSIS
        Clear Scoop download cache
    
    .PARAMETER App
        Specific app to clear cache for
    
    .EXAMPLE
        Clear-ScoopCache
    
    .EXAMPLE
        Clear-ScoopCache -App 'git'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$App
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return
    }
    
    $options = @{}
    if ($App) { $options.App = $App }
    
    $scoop.CleanupCache($options)
}

function Get-ScoopCacheSize {
    <#
    .SYNOPSIS
        Get the size of the Scoop cache
    
    .EXAMPLE
        Get-ScoopCacheSize
        
    .EXAMPLE
        $size = Get-ScoopCacheSize
        Write-Host "Cache size: $([math]::Round($size / 1GB, 2)) GB"
    #>
    [CmdletBinding()]
    param()
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return 0
    }
    
    return $scoop.GetCacheSize()
}

function Reset-ScoopApp {
    <#
    .SYNOPSIS
        Reset a Scoop app (re-create shims and shortcuts)
    
    .PARAMETER PackageId
        The package ID to reset
    
    .EXAMPLE
        Reset-ScoopApp -PackageId 'git'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return $false
    }
    
    return $scoop.ResetApp($PackageId)
}

function Export-ScoopPackages {
    <#
    .SYNOPSIS
        Export installed Scoop packages to a JSON file
    
    .PARAMETER OutputPath
        Path to the output JSON file
    
    .EXAMPLE
        Export-ScoopPackages -OutputPath 'C:\Backup\scoop-packages.json'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return
    }
    
    $scoop.ExportInstalled($OutputPath)
}

function Import-ScoopPackages {
    <#
    .SYNOPSIS
        Import and install packages from a Scoop export file
    
    .PARAMETER InputPath
        Path to the input JSON file
    
    .PARAMETER IgnoreVersions
        Install latest versions instead of specified versions
    
    .EXAMPLE
        Import-ScoopPackages -InputPath 'C:\Backup\scoop-packages.json'
    
    .EXAMPLE
        Import-ScoopPackages -InputPath 'packages.json' -IgnoreVersions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreVersions
    )
    
    $scoop = New-ScoopManager
    
    if (-not $scoop.IsAvailable) {
        Write-Error "Scoop is not available"
        return $false
    }
    
    $options = @{
        IgnoreVersions = $IgnoreVersions.IsPresent
    }
    
    return $scoop.ImportFromFile($InputPath, $options)
}

#endregion

#region Module Initialization

Write-Host "Scoop integration module loaded!" -ForegroundColor Green

# Test Scoop availability
$testScoop = New-ScoopManager
if ($testScoop.IsAvailable) {
    Write-Host "  Scoop Version: v$($testScoop.ScoopVersion)" -ForegroundColor White
    Write-Host "  Buckets: $($testScoop.Buckets.Count) configured" -ForegroundColor White
    $cacheSize = $testScoop.GetCacheSize()
    Write-Host "  Cache Size: $([math]::Round($cacheSize / 1MB, 2)) MB" -ForegroundColor White
} else {
    Write-Host "  Scoop is not available on this system" -ForegroundColor Yellow
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-ScoopManager'
    'Install-ScoopPackage'
    'Uninstall-ScoopPackage'
    'Update-ScoopPackage'
    'Search-ScoopPackage'
    'Get-ScoopPackageInfo'
    'Get-ScoopInstalledPackages'
    'Get-ScoopOutdatedPackages'
    'Add-ScoopBucket'
    'Remove-ScoopBucket'
    'Get-ScoopBuckets'
    'Update-ScoopBuckets'
    'Clear-ScoopCache'
    'Get-ScoopCacheSize'
    'Reset-ScoopApp'
    'Export-ScoopPackages'
    'Import-ScoopPackages'
)

#endregion
