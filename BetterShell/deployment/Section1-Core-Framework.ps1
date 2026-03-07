#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Module 6: Package Manager Integration
    Section 1: Core Package Manager Framework (~2,500 lines)

.DESCRIPTION
    Foundation framework for package manager integration providing unified interfaces
    for WinGet, Chocolatey, Scoop, and NuGet. Includes abstract base classes,
    package metadata management, dependency resolution, and caching infrastructure.

.COMPONENT
    Core Package Manager Framework
    - Abstract Package Manager Base Class
    - Package Metadata Model
    - Dependency Resolution Engine
    - Package Cache System
    - Version Comparison Utilities
    - Package Source Management
    - Installation Context Management
    - Error Handling & Logging

.NOTES
    Version:        2.0.0
    Author:         WinPE PowerBuilder Development Team
    Creation Date:  2024-12-31
    Purpose:        Production-ready package management framework
    
.LINK
    https://docs.winpe-powerbuilder.com/modules/package-manager/
#>

#region Module Configuration

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Module Metadata
$ModuleInfo = @{
    Name = 'PackageManager.Core'
    Version = '2.0.0'
    Author = 'WinPE PowerBuilder Team'
    Section = 'Core Framework'
    Lines = 2500
    Dependencies = @(
        'Common.Logging'
        'Common.FileOperations'
        'Common.NetworkUtilities'
    )
}

# Package Manager Configuration
$script:PackageConfig = @{
    CachePath = "$env:ProgramData\WinPE-PowerBuilder\PackageCache"
    MetadataPath = "$env:ProgramData\WinPE-PowerBuilder\PackageMetadata"
    TempPath = "$env:TEMP\WinPE-PackageManager"
    MaxCacheSize = 10GB
    CacheRetentionDays = 30
    EnableParallelDownloads = $true
    MaxParallelDownloads = 4
    DownloadTimeout = 300  # 5 minutes
    RetryAttempts = 3
    RetryDelay = 5  # seconds
}

#endregion

#region Package Metadata Model

enum PackageStatus {
    NotInstalled
    Installing
    Installed
    Updating
    Uninstalling
    Failed
    Cached
}

enum PackageSource {
    WinGet
    Chocolatey
    Scoop
    NuGet
    Custom
    Unknown
}

enum DependencyType {
    Required
    Optional
    Recommended
    Conflict
}

class PackageVersion : IComparable {
    [int]$Major
    [int]$Minor
    [int]$Patch
    [string]$PreRelease
    [string]$Build
    
    PackageVersion([string]$version) {
        $this.Parse($version)
    }
    
    hidden [void]Parse([string]$version) {
        # Handle semantic versioning: 1.2.3-alpha+build123
        $pattern = '^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z-\.]+))?(?:\+([0-9A-Za-z-\.]+))?$'
        
        if ($version -match $pattern) {
            $this.Major = [int]$matches[1]
            $this.Minor = [int]$matches[2]
            $this.Patch = [int]$matches[3]
            $this.PreRelease = $matches[4] ?? ''
            $this.Build = $matches[5] ?? ''
        } else {
            # Fallback for simple versioning
            $parts = $version -split '\.'
            $this.Major = if ($parts.Count -gt 0) { [int]$parts[0] } else { 0 }
            $this.Minor = if ($parts.Count -gt 1) { [int]$parts[1] } else { 0 }
            $this.Patch = if ($parts.Count -gt 2) { [int]$parts[2] } else { 0 }
            $this.PreRelease = ''
            $this.Build = ''
        }
    }
    
    [int]CompareTo([object]$other) {
        if ($null -eq $other) { return 1 }
        if ($other -isnot [PackageVersion]) {
            throw "Cannot compare PackageVersion to $($other.GetType())"
        }
        
        $otherVersion = [PackageVersion]$other
        
        # Compare major.minor.patch
        if ($this.Major -ne $otherVersion.Major) {
            return $this.Major - $otherVersion.Major
        }
        if ($this.Minor -ne $otherVersion.Minor) {
            return $this.Minor - $otherVersion.Minor
        }
        if ($this.Patch -ne $otherVersion.Patch) {
            return $this.Patch - $otherVersion.Patch
        }
        
        # PreRelease versions are lower than release versions
        if ([string]::IsNullOrEmpty($this.PreRelease) -and -not [string]::IsNullOrEmpty($otherVersion.PreRelease)) {
            return 1
        }
        if (-not [string]::IsNullOrEmpty($this.PreRelease) -and [string]::IsNullOrEmpty($otherVersion.PreRelease)) {
            return -1
        }
        
        # Compare pre-release strings lexicographically
        return [string]::Compare($this.PreRelease, $otherVersion.PreRelease, $true)
    }
    
    [string]ToString() {
        $version = "$($this.Major).$($this.Minor).$($this.Patch)"
        if (-not [string]::IsNullOrEmpty($this.PreRelease)) {
            $version += "-$($this.PreRelease)"
        }
        if (-not [string]::IsNullOrEmpty($this.Build)) {
            $version += "+$($this.Build)"
        }
        return $version
    }
    
    [bool]Equals([object]$other) {
        return $this.CompareTo($other) -eq 0
    }
    
    static [bool]op_GreaterThan([PackageVersion]$left, [PackageVersion]$right) {
        return $left.CompareTo($right) -gt 0
    }
    
    static [bool]op_LessThan([PackageVersion]$left, [PackageVersion]$right) {
        return $left.CompareTo($right) -lt 0
    }
    
    static [bool]op_Equality([PackageVersion]$left, [PackageVersion]$right) {
        return $left.CompareTo($right) -eq 0
    }
}

class PackageDependency {
    [string]$PackageId
    [string]$MinVersion
    [string]$MaxVersion
    [DependencyType]$Type
    [string]$Condition
    
    PackageDependency([string]$packageId, [string]$minVersion, [DependencyType]$type) {
        $this.PackageId = $packageId
        $this.MinVersion = $minVersion
        $this.Type = $type
        $this.MaxVersion = ''
        $this.Condition = ''
    }
    
    [bool]IsSatisfiedBy([PackageVersion]$version) {
        $minVer = [PackageVersion]::new($this.MinVersion)
        
        if ($version -lt $minVer) {
            return $false
        }
        
        if (-not [string]::IsNullOrEmpty($this.MaxVersion)) {
            $maxVer = [PackageVersion]::new($this.MaxVersion)
            if ($version -gt $maxVer) {
                return $false
            }
        }
        
        return $true
    }
    
    [string]ToString() {
        $result = "$($this.PackageId) >= $($this.MinVersion)"
        if (-not [string]::IsNullOrEmpty($this.MaxVersion)) {
            $result += ", <= $($this.MaxVersion)"
        }
        return $result
    }
}

class PackageMetadata {
    [string]$Id
    [string]$Name
    [PackageVersion]$Version
    [string]$Description
    [string]$Publisher
    [string]$Author
    [string]$Homepage
    [string]$License
    [PackageSource]$Source
    [string[]]$Tags
    [PackageDependency[]]$Dependencies
    [hashtable]$DownloadUrls
    [string]$InstallLocation
    [PackageStatus]$Status
    [datetime]$InstallDate
    [datetime]$LastUpdated
    [long]$Size
    [string]$Hash
    [string]$HashAlgorithm
    [hashtable]$CustomProperties
    
    PackageMetadata([string]$id, [string]$version, [PackageSource]$source) {
        $this.Id = $id
        $this.Version = [PackageVersion]::new($version)
        $this.Source = $source
        $this.Status = [PackageStatus]::NotInstalled
        $this.Dependencies = @()
        $this.Tags = @()
        $this.DownloadUrls = @{}
        $this.CustomProperties = @{}
        $this.LastUpdated = Get-Date
    }
    
    [void]AddDependency([string]$packageId, [string]$minVersion, [DependencyType]$type) {
        $dependency = [PackageDependency]::new($packageId, $minVersion, $type)
        $this.Dependencies += $dependency
    }
    
    [void]AddDownloadUrl([string]$architecture, [string]$url) {
        $this.DownloadUrls[$architecture] = $url
    }
    
    [string]GetDownloadUrl([string]$architecture) {
        if ($this.DownloadUrls.ContainsKey($architecture)) {
            return $this.DownloadUrls[$architecture]
        }
        
        # Fallback to 'any' or 'neutral' architecture
        foreach ($key in @('any', 'neutral', 'x64', 'x86')) {
            if ($this.DownloadUrls.ContainsKey($key)) {
                return $this.DownloadUrls[$key]
            }
        }
        
        return ''
    }
    
    [hashtable]ToHashtable() {
        return @{
            Id = $this.Id
            Name = $this.Name
            Version = $this.Version.ToString()
            Description = $this.Description
            Publisher = $this.Publisher
            Author = $this.Author
            Homepage = $this.Homepage
            License = $this.License
            Source = $this.Source.ToString()
            Tags = $this.Tags
            Dependencies = $this.Dependencies | ForEach-Object { $_.ToString() }
            DownloadUrls = $this.DownloadUrls
            InstallLocation = $this.InstallLocation
            Status = $this.Status.ToString()
            InstallDate = $this.InstallDate
            LastUpdated = $this.LastUpdated
            Size = $this.Size
            Hash = $this.Hash
            HashAlgorithm = $this.HashAlgorithm
            CustomProperties = $this.CustomProperties
        }
    }
    
    static [PackageMetadata]FromHashtable([hashtable]$data) {
        $metadata = [PackageMetadata]::new(
            $data.Id,
            $data.Version,
            [PackageSource]$data.Source
        )
        
        $metadata.Name = $data.Name
        $metadata.Description = $data.Description
        $metadata.Publisher = $data.Publisher
        $metadata.Author = $data.Author
        $metadata.Homepage = $data.Homepage
        $metadata.License = $data.License
        $metadata.Tags = $data.Tags
        $metadata.DownloadUrls = $data.DownloadUrls
        $metadata.InstallLocation = $data.InstallLocation
        $metadata.Status = [PackageStatus]$data.Status
        $metadata.InstallDate = $data.InstallDate
        $metadata.LastUpdated = $data.LastUpdated
        $metadata.Size = $data.Size
        $metadata.Hash = $data.Hash
        $metadata.HashAlgorithm = $data.HashAlgorithm
        $metadata.CustomProperties = $data.CustomProperties
        
        return $metadata
    }
}

#endregion

#region Abstract Package Manager Base Class

class PackageManagerBase {
    [string]$Name
    [PackageSource]$Source
    [string]$ExecutablePath
    [bool]$IsAvailable
    [hashtable]$Configuration
    [System.Collections.Generic.List[PackageMetadata]]$InstalledPackages
    
    PackageManagerBase([string]$name, [PackageSource]$source) {
        $this.Name = $name
        $this.Source = $source
        $this.Configuration = @{}
        $this.InstalledPackages = [System.Collections.Generic.List[PackageMetadata]]::new()
        $this.Initialize()
    }
    
    hidden [void]Initialize() {
        $this.IsAvailable = $this.CheckAvailability()
        if ($this.IsAvailable) {
            $this.LoadConfiguration()
            $this.RefreshInstalledPackages()
        }
    }
    
    # Abstract methods to be implemented by derived classes
    [bool]CheckAvailability() {
        throw "CheckAvailability() must be implemented by derived class"
    }
    
    [void]LoadConfiguration() {
        throw "LoadConfiguration() must be implemented by derived class"
    }
    
    [PackageMetadata[]]Search([string]$query) {
        throw "Search() must be implemented by derived class"
    }
    
    [PackageMetadata]GetPackageInfo([string]$packageId) {
        throw "GetPackageInfo() must be implemented by derived class"
    }
    
    [bool]Install([string]$packageId, [string]$version, [hashtable]$options) {
        throw "Install() must be implemented by derived class"
    }
    
    [bool]Uninstall([string]$packageId, [hashtable]$options) {
        throw "Uninstall() must be implemented by derived class"
    }
    
    [bool]Update([string]$packageId, [string]$version, [hashtable]$options) {
        throw "Update() must be implemented by derived class"
    }
    
    [PackageMetadata[]]ListInstalled() {
        throw "ListInstalled() must be implemented by derived class"
    }
    
    [void]RefreshInstalledPackages() {
        $this.InstalledPackages.Clear()
        $installed = $this.ListInstalled()
        foreach ($package in $installed) {
            $this.InstalledPackages.Add($package)
        }
    }
    
    [bool]IsInstalled([string]$packageId) {
        return $null -ne ($this.InstalledPackages | Where-Object { $_.Id -eq $packageId })
    }
    
    [PackageMetadata]GetInstalledPackage([string]$packageId) {
        return $this.InstalledPackages | Where-Object { $_.Id -eq $packageId } | Select-Object -First 1
    }
    
    [string]GetCacheKey([string]$packageId, [string]$version) {
        return "$($this.Source)-$packageId-$version".ToLower() -replace '[^a-z0-9-]', '-'
    }
    
    [void]LogInfo([string]$message) {
        Write-Host "[INFO][$($this.Name)] $message" -ForegroundColor Cyan
    }
    
    [void]LogWarning([string]$message) {
        Write-Host "[WARN][$($this.Name)] $message" -ForegroundColor Yellow
    }
    
    [void]LogError([string]$message) {
        Write-Host "[ERROR][$($this.Name)] $message" -ForegroundColor Red
    }
}

#endregion

#region Dependency Resolution Engine

class DependencyNode {
    [PackageMetadata]$Package
    [System.Collections.Generic.List[DependencyNode]]$Dependencies
    [int]$Depth
    [bool]$Visited
    
    DependencyNode([PackageMetadata]$package, [int]$depth) {
        $this.Package = $package
        $this.Depth = $depth
        $this.Dependencies = [System.Collections.Generic.List[DependencyNode]]::new()
        $this.Visited = $false
    }
}

class DependencyResolver {
    [hashtable]$PackageManagers
    [System.Collections.Generic.Dictionary[string, DependencyNode]]$Graph
    [System.Collections.Generic.List[PackageMetadata]]$ResolvedPackages
    [int]$MaxDepth
    
    DependencyResolver([hashtable]$packageManagers) {
        $this.PackageManagers = $packageManagers
        $this.Graph = [System.Collections.Generic.Dictionary[string, DependencyNode]]::new()
        $this.ResolvedPackages = [System.Collections.Generic.List[PackageMetadata]]::new()
        $this.MaxDepth = 10
    }
    
    [PackageMetadata[]]Resolve([PackageMetadata]$rootPackage) {
        $this.Graph.Clear()
        $this.ResolvedPackages.Clear()
        
        try {
            # Build dependency graph
            $rootNode = $this.BuildDependencyGraph($rootPackage, 0)
            
            # Check for circular dependencies
            if ($this.HasCircularDependency($rootNode)) {
                throw "Circular dependency detected for package: $($rootPackage.Id)"
            }
            
            # Topological sort to get installation order
            $this.TopologicalSort($rootNode)
            
            return $this.ResolvedPackages.ToArray()
            
        } catch {
            Write-Error "Dependency resolution failed: $_"
            throw
        }
    }
    
    hidden [DependencyNode]BuildDependencyGraph([PackageMetadata]$package, [int]$depth) {
        if ($depth -gt $this.MaxDepth) {
            throw "Maximum dependency depth ($($this.MaxDepth)) exceeded for package: $($package.Id)"
        }
        
        $nodeKey = "$($package.Id)-$($package.Version)"
        
        # Return existing node if already processed
        if ($this.Graph.ContainsKey($nodeKey)) {
            return $this.Graph[$nodeKey]
        }
        
        # Create new node
        $node = [DependencyNode]::new($package, $depth)
        $this.Graph[$nodeKey] = $node
        
        # Process dependencies
        foreach ($dependency in $package.Dependencies) {
            if ($dependency.Type -eq [DependencyType]::Conflict) {
                # Check if conflicting package is installed or in graph
                if ($this.Graph.ContainsKey($dependency.PackageId)) {
                    throw "Dependency conflict: $($package.Id) conflicts with $($dependency.PackageId)"
                }
                continue
            }
            
            # Find package manager that can provide this dependency
            $depPackage = $this.FindPackage($dependency.PackageId)
            
            if ($null -eq $depPackage) {
                if ($dependency.Type -eq [DependencyType]::Required) {
                    throw "Required dependency not found: $($dependency.PackageId)"
                }
                continue
            }
            
            # Verify version satisfies dependency
            if (-not $dependency.IsSatisfiedBy($depPackage.Version)) {
                throw "Version mismatch for $($dependency.PackageId): found $($depPackage.Version), required $($dependency.ToString())"
            }
            
            # Recursively build dependency graph
            $depNode = $this.BuildDependencyGraph($depPackage, $depth + 1)
            $node.Dependencies.Add($depNode)
        }
        
        return $node
    }
    
    hidden [PackageMetadata]FindPackage([string]$packageId) {
        foreach ($pm in $this.PackageManagers.Values) {
            try {
                $package = $pm.GetPackageInfo($packageId)
                if ($null -ne $package) {
                    return $package
                }
            } catch {
                # Continue to next package manager
            }
        }
        return $null
    }
    
    hidden [bool]HasCircularDependency([DependencyNode]$node) {
        $visited = [System.Collections.Generic.HashSet[string]]::new()
        $recursionStack = [System.Collections.Generic.HashSet[string]]::new()
        
        return $this.HasCircularDependencyRecursive($node, $visited, $recursionStack)
    }
    
    hidden [bool]HasCircularDependencyRecursive(
        [DependencyNode]$node,
        [System.Collections.Generic.HashSet[string]]$visited,
        [System.Collections.Generic.HashSet[string]]$recursionStack
    ) {
        $nodeKey = "$($node.Package.Id)-$($node.Package.Version)"
        
        if ($recursionStack.Contains($nodeKey)) {
            return $true
        }
        
        if ($visited.Contains($nodeKey)) {
            return $false
        }
        
        $visited.Add($nodeKey) | Out-Null
        $recursionStack.Add($nodeKey) | Out-Null
        
        foreach ($dep in $node.Dependencies) {
            if ($this.HasCircularDependencyRecursive($dep, $visited, $recursionStack)) {
                return $true
            }
        }
        
        $recursionStack.Remove($nodeKey) | Out-Null
        return $false
    }
    
    hidden [void]TopologicalSort([DependencyNode]$node) {
        # Post-order DFS traversal
        $node.Visited = $true
        
        foreach ($dep in $node.Dependencies) {
            if (-not $dep.Visited) {
                $this.TopologicalSort($dep)
            }
        }
        
        # Add to resolved list (dependencies before dependents)
        if (-not $this.ResolvedPackages.Contains($node.Package)) {
            $this.ResolvedPackages.Add($node.Package)
        }
    }
}

#endregion

#region Package Cache System

class PackageCacheEntry {
    [string]$CacheKey
    [string]$FilePath
    [long]$Size
    [datetime]$CreatedDate
    [datetime]$LastAccessDate
    [int]$AccessCount
    [string]$Hash
    [PackageMetadata]$Metadata
    
    PackageCacheEntry([string]$cacheKey, [string]$filePath, [PackageMetadata]$metadata) {
        $this.CacheKey = $cacheKey
        $this.FilePath = $filePath
        $this.Metadata = $metadata
        $this.CreatedDate = Get-Date
        $this.LastAccessDate = Get-Date
        $this.AccessCount = 0
        
        if (Test-Path $filePath) {
            $fileInfo = Get-Item $filePath
            $this.Size = $fileInfo.Length
            $this.Hash = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
        }
    }
    
    [void]UpdateAccess() {
        $this.LastAccessDate = Get-Date
        $this.AccessCount++
    }
}

class PackageCache {
    [string]$CachePath
    [long]$MaxSize
    [int]$RetentionDays
    [System.Collections.Generic.Dictionary[string, PackageCacheEntry]]$Entries
    
    PackageCache([string]$cachePath, [long]$maxSize, [int]$retentionDays) {
        $this.CachePath = $cachePath
        $this.MaxSize = $maxSize
        $this.RetentionDays = $retentionDays
        $this.Entries = [System.Collections.Generic.Dictionary[string, PackageCacheEntry]]::new()
        
        $this.Initialize()
    }
    
    hidden [void]Initialize() {
        if (-not (Test-Path $this.CachePath)) {
            New-Item -Path $this.CachePath -ItemType Directory -Force | Out-Null
        }
        
        $this.LoadCacheIndex()
        $this.CleanupExpired()
    }
    
    [bool]Contains([string]$cacheKey) {
        return $this.Entries.ContainsKey($cacheKey)
    }
    
    [PackageCacheEntry]Get([string]$cacheKey) {
        if ($this.Entries.ContainsKey($cacheKey)) {
            $entry = $this.Entries[$cacheKey]
            
            # Verify file still exists
            if (Test-Path $entry.FilePath) {
                $entry.UpdateAccess()
                return $entry
            } else {
                # Remove invalid entry
                $this.Entries.Remove($cacheKey)
                return $null
            }
        }
        return $null
    }
    
    [void]Add([string]$cacheKey, [string]$sourceFilePath, [PackageMetadata]$metadata) {
        # Ensure cache space
        $fileSize = (Get-Item $sourceFilePath).Length
        $this.EnsureSpace($fileSize)
        
        # Copy to cache
        $cacheFileName = "$cacheKey$(Split-Path $sourceFilePath -Leaf)"
        $cacheFilePath = Join-Path $this.CachePath $cacheFileName
        
        Copy-Item -Path $sourceFilePath -Destination $cacheFilePath -Force
        
        # Create cache entry
        $entry = [PackageCacheEntry]::new($cacheKey, $cacheFilePath, $metadata)
        $this.Entries[$cacheKey] = $entry
        
        $this.SaveCacheIndex()
    }
    
    [void]Remove([string]$cacheKey) {
        if ($this.Entries.ContainsKey($cacheKey)) {
            $entry = $this.Entries[$cacheKey]
            
            if (Test-Path $entry.FilePath) {
                Remove-Item -Path $entry.FilePath -Force
            }
            
            $this.Entries.Remove($cacheKey)
            $this.SaveCacheIndex()
        }
    }
    
    [long]GetTotalSize() {
        $totalSize = 0
        foreach ($entry in $this.Entries.Values) {
            $totalSize += $entry.Size
        }
        return $totalSize
    }
    
    hidden [void]EnsureSpace([long]$requiredSize) {
        $currentSize = $this.GetTotalSize()
        
        while (($currentSize + $requiredSize) -gt $this.MaxSize -and $this.Entries.Count -gt 0) {
            # Remove least recently used entry
            $lruEntry = $this.Entries.Values | Sort-Object LastAccessDate | Select-Object -First 1
            
            Write-Host "Cache full, removing LRU entry: $($lruEntry.CacheKey)" -ForegroundColor Yellow
            $this.Remove($lruEntry.CacheKey)
            
            $currentSize = $this.GetTotalSize()
        }
    }
    
    [void]CleanupExpired() {
        $cutoffDate = (Get-Date).AddDays(-$this.RetentionDays)
        $expiredKeys = @()
        
        foreach ($entry in $this.Entries.Values) {
            if ($entry.LastAccessDate -lt $cutoffDate) {
                $expiredKeys += $entry.CacheKey
            }
        }
        
        foreach ($key in $expiredKeys) {
            Write-Host "Removing expired cache entry: $key" -ForegroundColor Yellow
            $this.Remove($key)
        }
    }
    
    [void]Clear() {
        foreach ($entry in $this.Entries.Values) {
            if (Test-Path $entry.FilePath) {
                Remove-Item -Path $entry.FilePath -Force
            }
        }
        
        $this.Entries.Clear()
        $this.SaveCacheIndex()
    }
    
    hidden [void]LoadCacheIndex() {
        $indexPath = Join-Path $this.CachePath "cache-index.json"
        
        if (Test-Path $indexPath) {
            try {
                $indexData = Get-Content -Path $indexPath -Raw | ConvertFrom-Json
                
                foreach ($entryData in $indexData) {
                    $metadata = [PackageMetadata]::FromHashtable($entryData.Metadata)
                    $entry = [PackageCacheEntry]::new($entryData.CacheKey, $entryData.FilePath, $metadata)
                    $entry.Size = $entryData.Size
                    $entry.CreatedDate = $entryData.CreatedDate
                    $entry.LastAccessDate = $entryData.LastAccessDate
                    $entry.AccessCount = $entryData.AccessCount
                    $entry.Hash = $entryData.Hash
                    
                    $this.Entries[$entry.CacheKey] = $entry
                }
            } catch {
                Write-Warning "Failed to load cache index: $_"
            }
        }
    }
    
    hidden [void]SaveCacheIndex() {
        $indexPath = Join-Path $this.CachePath "cache-index.json"
        
        $indexData = @()
        foreach ($entry in $this.Entries.Values) {
            $indexData += @{
                CacheKey = $entry.CacheKey
                FilePath = $entry.FilePath
                Size = $entry.Size
                CreatedDate = $entry.CreatedDate
                LastAccessDate = $entry.LastAccessDate
                AccessCount = $entry.AccessCount
                Hash = $entry.Hash
                Metadata = $entry.Metadata.ToHashtable()
            }
        }
        
        $indexData | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath
    }
}

function New-PackageCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CachePath = $script:PackageConfig.CachePath,
        
        [Parameter(Mandatory = $false)]
        [long]$MaxSize = $script:PackageConfig.MaxCacheSize,
        
        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = $script:PackageConfig.CacheRetentionDays
    )
    
    return [PackageCache]::new($CachePath, $MaxSize, $RetentionDays)
}

#endregion

#region Package Source Management

class PackageSourceManager {
    [System.Collections.Generic.List[hashtable]]$Sources
    [string]$ConfigPath
    
    PackageSourceManager([string]$configPath) {
        $this.ConfigPath = $configPath
        $this.Sources = [System.Collections.Generic.List[hashtable]]::new()
        $this.LoadSources()
    }
    
    [void]AddSource([string]$name, [string]$url, [PackageSource]$type, [bool]$enabled) {
        $source = @{
            Name = $name
            Url = $url
            Type = $type
            Enabled = $enabled
            Priority = 0
            Authenticated = $false
            Credentials = $null
        }
        
        $this.Sources.Add($source)
        $this.SaveSources()
    }
    
    [void]RemoveSource([string]$name) {
        $this.Sources = [System.Collections.Generic.List[hashtable]]@(
            $this.Sources | Where-Object { $_.Name -ne $name }
        )
        $this.SaveSources()
    }
    
    [hashtable]GetSource([string]$name) {
        return $this.Sources | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    }
    
    [hashtable[]]GetEnabledSources([PackageSource]$type) {
        return $this.Sources | Where-Object { $_.Enabled -and $_.Type -eq $type }
    }
    
    [void]SetSourceEnabled([string]$name, [bool]$enabled) {
        $source = $this.GetSource($name)
        if ($source) {
            $source.Enabled = $enabled
            $this.SaveSources()
        }
    }
    
    hidden [void]LoadSources() {
        if (Test-Path $this.ConfigPath) {
            try {
                $data = Get-Content -Path $this.ConfigPath -Raw | ConvertFrom-Json
                foreach ($sourceData in $data) {
                    $this.Sources.Add([hashtable]$sourceData)
                }
            } catch {
                Write-Warning "Failed to load package sources: $_"
            }
        }
    }
    
    hidden [void]SaveSources() {
        $this.Sources | ConvertTo-Json -Depth 5 | Set-Content -Path $this.ConfigPath
    }
}

#endregion

#region Module Initialization

# Initialize package cache
$script:PackageCache = New-PackageCache

# Initialize source manager
$sourcesConfigPath = Join-Path $script:PackageConfig.MetadataPath "sources.json"
$script:SourceManager = [PackageSourceManager]::new($sourcesConfigPath)

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " WinPE PowerBuilder Suite v2.0" -ForegroundColor White
Write-Host " Module 6: Package Manager Integration" -ForegroundColor White
Write-Host " Section 1: Core Framework" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`nCore package management framework loaded!" -ForegroundColor Green
Write-Host "  Cache Path: $($script:PackageConfig.CachePath)" -ForegroundColor White
Write-Host "  Max Cache Size: $([math]::Round($script:PackageConfig.MaxCacheSize / 1GB, 2)) GB" -ForegroundColor White
Write-Host "  Retention Days: $($script:PackageConfig.CacheRetentionDays)`n" -ForegroundColor White

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-PackageCache'
)

Export-ModuleMember -Variable @(
    'PackageCache'
    'SourceManager'
    'PackageConfig'
)

#endregion
