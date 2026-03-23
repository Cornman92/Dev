<#
.SYNOPSIS
    Better11.Core - Core functionality for the Better11 Suite

.DESCRIPTION
    Provides core functionality for the Better11 Suite including configuration management,
    logging integration, module initialization, and common utilities used across all
    Better11 modules. Integrates with Core-AutoSuite for shared functionality.

.NOTES
    Version: 1.0.0
    Author: Windows Automation Workspace
    Copyright: (c) 2024 Windows Automation Workspace. All rights reserved.
#>

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:ModuleName = 'Better11.Core'
$script:ConfigPath = Join-Path $PSScriptRoot '..\..\Config\project.json'
$script:Logger = $null
#endregion

#region Module Initialization
# Try to import Core-AutoSuite if available
$coreAutoSuitePath = Join-Path $PSScriptRoot '..\..\Windows-Automation-Station\workflows\Core\Core-AutoSuite.psm1'
if (Test-Path $coreAutoSuitePath) {
    try {
        Import-Module $coreAutoSuitePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Could not import Core-AutoSuite: $_"
    }
}
#endregion

#region Configuration Management

function Get-Better11Config {
    <#
    .SYNOPSIS
        Gets Better11 configuration from project.json
    
    .DESCRIPTION
        Loads and returns the Better11 configuration from the project.json file.
        Returns default configuration if file is not found.
    
    .PARAMETER ConfigPath
        Path to the project.json configuration file. Defaults to standard location.
    
    .EXAMPLE
        Get-Better11Config
    
    .EXAMPLE
        Get-Better11Config -ConfigPath "C:\Custom\config.json"
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [string]$ConfigPath = $script:ConfigPath
    )
    
    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Warning "Configuration file not found at $ConfigPath. Using defaults."
            return Get-Better11DefaultConfig
        }
        
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        $configHashtable = @{
            Name              = $config.name
            Version           = $config.version
            Profile           = $config.profile
            Options           = @{
                BuildISO       = $config.options.buildISO
                WhatIf         = $config.options.whatIf
                OfflineOnly    = $config.options.offlineOnly
                MaxConcurrency = $config.options.maxConcurrency
            }
            ISOSettings       = @{
                Label      = $config.iso.label
                SourcePath = $config.iso.sourcePath
                OutputIso  = $config.iso.outputIso
            }
            AppsCatalog       = $config.appsCatalog
            InstallerMetadata = $config.installerMetadata
        }
        
        return $configHashtable
    }
    catch {
        Write-Error "Failed to load Better11 configuration: $_"
        return Get-Better11DefaultConfig
    }
}

function Get-Better11DefaultConfig {
    <#
    .SYNOPSIS
        Returns default Better11 configuration
    
    .DESCRIPTION
        Returns a hashtable with default Better11 configuration values.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    return @{
        Name              = 'Better11 Suite'
        Version           = '0.1.0'
        Profile           = 'gamer'
        Options           = @{
            BuildISO       = $false
            WhatIf         = $false
            OfflineOnly    = $false
            MaxConcurrency = 3
        }
        ISOSettings       = @{
            Label      = 'BETTER11'
            SourcePath = 'C:\Better11\Staging'
            OutputIso  = 'C:\Better11\Output\Better11.iso'
        }
        AppsCatalog       = '.\Manifests\apps.json'
        InstallerMetadata = '.\Config\installer_metadata.json'
    }
}

function Set-Better11Config {
    <#
    .SYNOPSIS
        Updates Better11 configuration in project.json
    
    .DESCRIPTION
        Updates specific configuration values in the project.json file.
    
    .PARAMETER ConfigPath
        Path to the project.json configuration file.
    
    .PARAMETER Property
        Name of the property to update (supports nested properties like 'Options.BuildISO').
    
    .PARAMETER Value
        Value to set for the property.
    
    .EXAMPLE
        Set-Better11Config -Property 'Options.BuildISO' -Value $true
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath = $script:ConfigPath,
        
        [Parameter(Mandatory)]
        [string]$Property,
        
        [Parameter(Mandatory)]
        [object]$Value
    )
    
    try {
        if (-not (Test-Path $ConfigPath)) {
            throw "Configuration file not found at $ConfigPath"
        }
        
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        
        # Handle nested properties
        $propertyParts = $Property.Split('.')
        $target = $config
        
        for ($i = 0; $i -lt $propertyParts.Length - 1; $i++) {
            $prop = $propertyParts[$i]
            if (-not $target.$prop) {
                $target | Add-Member -MemberType NoteProperty -Name $prop -Value @{}
            }
            $target = $target.$prop
        }
        
        $target.$($propertyParts[-1]) = $Value
        
        $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
        Write-Verbose "Updated configuration property $Property to $Value"
    }
    catch {
        Write-Error "Failed to update Better11 configuration: $_"
        throw
    }
}

#endregion

#region Logging Integration

function Initialize-Better11Logger {
    <#
    .SYNOPSIS
        Initializes the Better11 logger
    
    .DESCRIPTION
        Initializes a logger for Better11 operations. Uses Core-AutoSuite logger if available,
        otherwise falls back to Logging module.
    
    .PARAMETER LogPath
        Path to the log file. If not specified, uses default location.
    
    .PARAMETER LogLevel
        Log level (INFO, WARN, ERROR, DEBUG). Defaults to INFO.
    
    .EXAMPLE
        Initialize-Better11Logger -LogPath "C:\Logs\better11.log"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$LogPath,
        
        [Parameter()]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$LogLevel = 'INFO'
    )
    
    try {
        # Use Core-AutoSuite logger if available
        if (Get-Command 'AutoSuiteLogger' -ErrorAction SilentlyContinue) {
            if (-not $LogPath) {
                $LogPath = Join-Path $PSScriptRoot '..\..\Output' "better11_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date)
            }
            $script:Logger = [AutoSuiteLogger]::new($LogPath, $LogLevel)
            Write-Verbose "Initialized Core-AutoSuite logger at $LogPath"
            return $script:Logger
        }
        
        # Fallback to Logging module
        $loggingModule = Join-Path $PSScriptRoot '..\Logging\Logging.psm1'
        if (Test-Path $loggingModule) {
            Import-Module $loggingModule -ErrorAction SilentlyContinue
            if (Get-Command 'Start-Better11Log' -ErrorAction SilentlyContinue) {
                if (-not $LogPath) {
                    $LogPath = Start-Better11Log
                }
                else {
                    Start-Better11Log -Path $LogPath
                }
                Write-Verbose "Initialized Logging at $LogPath"
                return $true
            }
        }
        
        # Last resort: simple file logging
        if (-not $LogPath) {
            $LogPath = Join-Path $PSScriptRoot '..\..\Output' "better11_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date)
        }
        $dir = Split-Path -Parent $LogPath
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Write-Verbose "Using simple file logging at $LogPath"
        return $true
    }
    catch {
        Write-Warning "Failed to initialize logger: $_"
        return $false
    }
}

function Write-Better11Log {
    <#
    .SYNOPSIS
        Writes a log entry
    
    .DESCRIPTION
        Writes a log entry using the initialized logger.
    
    .PARAMETER Level
        Log level (INFO, WARN, ERROR, DEBUG)
    
    .PARAMETER Message
        Log message
    
    .PARAMETER Context
        Additional context information as hashtable
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    try {
        # Use Core-AutoSuite logger if available
        if ($script:Logger -and ($script:Logger -is [AutoSuiteLogger])) {
            $script:Logger.Write($Level, $Message, $Context)
            return
        }
        
        # Use Logging module if available
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level $Level -Message $Message
            return
        }
        
        # Simple file logging fallback
        $logPath = Join-Path $PSScriptRoot '..\..\Output' "better11.log"
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logEntry = "[$timestamp][$Level] $Message"
        if ($Context.Count -gt 0) {
            $logEntry += " | Context: $($Context | ConvertTo-Json -Compress)"
        }
        Add-Content -Path $logPath -Value $logEntry
        
        # Also write to console
        switch ($Level) {
            'INFO' { Write-Host $Message -ForegroundColor White }
            'WARN' { Write-Warning $Message }
            'ERROR' { Write-Error $Message }
            'DEBUG' { Write-Debug $Message }
        }
    }
    catch {
        Write-Warning "Failed to write log entry: $_"
    }
}

#endregion

#region Module Utilities

function Test-Better11Prerequisites {
    <#
    .SYNOPSIS
        Tests if Better11 prerequisites are met
    
    .DESCRIPTION
        Checks for required tools, modules, and system requirements for Better11 operations.
    
    .PARAMETER IncludeOptional
        Also check for optional prerequisites
    
    .EXAMPLE
        Test-Better11Prerequisites
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [switch]$IncludeOptional
    )
    
    $results = @{
        Passed = $true
        Checks = @()
    }
    
    # Check PowerShell version (7.0+)
    $psVersion = $PSVersionTable.PSVersion
    $psCheck = @{
        Name     = 'PowerShell Version'
        Required = '7.0+'
        Actual   = $psVersion.ToString()
        Pass     = $psVersion.Major -ge 7
    }
    $results.Checks += $psCheck
    if (-not $psCheck.Pass) { $results.Passed = $false }
    
    # Check for winget
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    $wingetCheck = @{
        Name     = 'Winget'
        Required = 'Installed'
        Actual   = if ($winget) { $winget.Path } else { 'Not found' }
        Pass     = [bool]$winget
    }
    $results.Checks += $wingetCheck
    if (-not $wingetCheck.Pass) { $results.Passed = $false }
    
    # Check for DISM
    $dism = Get-Command dism.exe -ErrorAction SilentlyContinue
    $dismCheck = @{
        Name     = 'DISM'
        Required = 'Installed'
        Actual   = if ($dism) { $dism.Path } else { 'Not found' }
        Pass     = [bool]$dism
    }
    $results.Checks += $dismCheck
    if (-not $dismCheck.Pass) { $results.Passed = $false }
    
    # Check for Chocolatey (optional)
    if ($IncludeOptional) {
        $choco = Get-Command choco -ErrorAction SilentlyContinue
        $chocoCheck = @{
            Name     = 'Chocolatey'
            Required = 'Optional'
            Actual   = if ($choco) { $choco.Path } else { 'Not found' }
            Pass     = [bool]$choco
        }
        $results.Checks += $chocoCheck
    }
    
    return $results
}

function Get-Better11ModulePath {
    <#
    .SYNOPSIS
        Gets the path to a specific Better11 module
    
    .DESCRIPTION
        Returns the full path to a Better11 module by name.
    
    .PARAMETER ModuleName
        Name of the Better11 module (e.g., 'Install', 'Drivers', 'Retry')
    
    .EXAMPLE
        Get-Better11ModulePath -ModuleName 'Install'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Core', 'Install', 'Drivers', 'Retry', 'Tweaks')]
        [string]$ModuleName
    )
    
    $moduleFile = "Better11.$ModuleName.psm1"
    $modulePath = Join-Path $PSScriptRoot $moduleFile
    
    if (Test-Path $modulePath) {
        return $modulePath
    }
    else {
        Write-Warning "Module Better11.$ModuleName not found at $modulePath"
        return $null
    }
}

function Import-Better11Module {
    <#
    .SYNOPSIS
        Imports a Better11 module
    
    .DESCRIPTION
        Imports a specific Better11 module by name.
    
    .PARAMETER ModuleName
        Name of the Better11 module to import
    
    .PARAMETER Force
        Force re-import even if already loaded
    
    .EXAMPLE
        Import-Better11Module -ModuleName 'Install'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Core', 'Install', 'Drivers', 'Retry', 'Tweaks')]
        [string]$ModuleName,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        $modulePath = Get-Better11ModulePath -ModuleName $ModuleName
        if (-not $modulePath) {
            throw "Module Better11.$ModuleName not found"
        }
        
        Import-Module $modulePath -Force:$Force -ErrorAction Stop
        Write-Verbose "Successfully imported Better11.$ModuleName"
    }
    catch {
        Write-Error "Failed to import Better11.$ModuleName : $_"
        throw
    }
}

#endregion

#region Error Handling

function Invoke-Better11Action {
    <#
    .SYNOPSIS
        Executes an action with Better11 error handling and logging
    
    .DESCRIPTION
        Wraps an action with standardized error handling, logging, and optional retry logic.
        Integrates with Core-AutoSuite if available.
    
    .PARAMETER Name
        Name of the action for logging purposes
    
    .PARAMETER Action
        ScriptBlock to execute
    
    .PARAMETER RetryCount
        Number of retry attempts on failure
    
    .PARAMETER RetryDelaySeconds
        Delay between retries in seconds
    
    .EXAMPLE
        Invoke-Better11Action -Name 'Install Package' -Action { Install-Package -Name 'Test' }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [scriptblock]$Action,
        
        [Parameter()]
        [int]$RetryCount = 0,
        
        [Parameter()]
        [int]$RetryDelaySeconds = 5
    )
    
    # Use Core-AutoSuite if available
    if ($script:Logger -and ($script:Logger -is [AutoSuiteLogger]) -and (Get-Command 'Invoke-AutoSuiteAction' -ErrorAction SilentlyContinue)) {
        return Invoke-AutoSuiteAction -Name $Name -Action $Action -Logger $script:Logger -RetryCount $RetryCount -RetryDelaySeconds $RetryDelaySeconds
    }
    
    # Fallback implementation
    $attempt = 0
    
    while ($attempt -le $RetryCount) {
        try {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Write-Better11Log -Level 'INFO' -Message "BEGIN: $Name (Attempt $($attempt + 1))"
            
            $result = & $Action
            
            $stopwatch.Stop()
            Write-Better11Log -Level 'INFO' -Message "END: $Name (success in $($stopwatch.Elapsed.TotalSeconds.ToString('F2'))s)"
            
            return $result
        }
        catch {
            $attempt++
            
            if ($attempt -le $RetryCount) {
                Write-Better11Log -Level 'WARN' -Message "FAILED: $Name (Attempt $attempt) - Retrying in $RetryDelaySeconds seconds: $($_.Exception.Message)"
                Start-Sleep -Seconds $RetryDelaySeconds
            }
            else {
                Write-Better11Log -Level 'ERROR' -Message "FAILED: $Name after $attempt attempts: $($_.Exception.Message)"
                throw
            }
        }
    }
}

#endregion

#region Validation & Helpers

function Test-Better11AdminRights {
    <#
    .SYNOPSIS
        Tests if the current session has administrator rights
    
    .DESCRIPTION
        Checks if the current PowerShell session is running with administrator privileges.
    
    .EXAMPLE
        if (Test-Better11AdminRights) { Write-Host "Running as admin" }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Better11AdminRights {
    <#
    .SYNOPSIS
        Asserts that the current session has administrator rights
    
    .DESCRIPTION
        Throws an error if the current session does not have administrator privileges.
    
    .EXAMPLE
        Assert-Better11AdminRights
    #>
    [CmdletBinding()]
    param()
    
    if (-not (Test-Better11AdminRights)) {
        throw "This operation requires administrator privileges. Please run PowerShell as Administrator."
    }
}

function Get-Better11SystemInfo {
    <#
    .SYNOPSIS
        Gets comprehensive system information
    
    .DESCRIPTION
        Retrieves detailed system information including OS version, hardware, and capabilities.
    
    .EXAMPLE
        Get-Better11SystemInfo
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem
        $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        
        return @{
            OSName            = $os.Caption
            OSVersion         = $os.Version
            OSBuild           = $os.BuildNumber
            Architecture      = $os.OSArchitecture
            ComputerName      = $computer.Name
            Manufacturer      = $computer.Manufacturer
            Model             = $computer.Model
            Processor         = $processor.Name
            TotalMemoryGB     = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
            FreeMemoryGB      = [math]::Round($os.FreePhysicalMemory * 1KB / 1GB, 2)
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            IsAdmin           = Test-Better11AdminRights
            Uptime            = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
        }
    }
    catch {
        Write-Error "Failed to get system information: $_"
        throw
    }
}

function Test-Better11NetworkConnectivity {
    <#
    .SYNOPSIS
        Tests network connectivity
    
    .DESCRIPTION
        Tests connectivity to specified hosts or default internet hosts.
    
    .PARAMETER Hosts
        Array of hostnames or IPs to test. Defaults to common internet hosts.
    
    .PARAMETER TimeoutSeconds
        Timeout in seconds for each test
    
    .EXAMPLE
        Test-Better11NetworkConnectivity
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [string[]]$Hosts = @('8.8.8.8', '1.1.1.1', 'google.com'),
        
        [Parameter()]
        [int]$TimeoutSeconds = 5
    )
    
    $results = @{
        Online      = $false
        Hosts       = @()
        TotalTested = $Hosts.Count
        Successful  = 0
    }
    
    foreach ($hostname in $Hosts) {
        try {
            $ping = Test-Connection -ComputerName $hostname -Count 1 -TimeoutSeconds $TimeoutSeconds -ErrorAction Stop
            $results.Hosts += @{
                Host    = $hostname
                Online  = $true
                Latency = $ping.ResponseTime
            }
            $results.Successful++
            $results.Online = $true
        }
        catch {
            $results.Hosts += @{
                Host   = $hostname
                Online = $false
                Error  = $_.Exception.Message
            }
        }
    }
    
    return $results
}

function Get-Better11ModuleHealth {
    <#
    .SYNOPSIS
        Gets health status of all Better11 modules
    
    .DESCRIPTION
        Checks the health and status of all Better11 modules.
    
    .EXAMPLE
        Get-Better11ModuleHealth
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param()
    
    $modules = @('Core', 'Install', 'Drivers', 'Retry', 'Tweaks')
    $health = @()
    
    foreach ($moduleName in $modules) {
        $moduleInfo = @{
            Name    = "Better11.$moduleName"
            Loaded  = $false
            Version = $null
            Path    = $null
            Status  = 'Unknown'
        }
        
        try {
            $modulePath = Get-Better11ModulePath -ModuleName $moduleName -ErrorAction SilentlyContinue
            if ($modulePath) {
                $moduleInfo.Path = $modulePath
                $moduleInfo.Status = 'Available'
                
                $loadedModule = Get-Module -Name "Better11.$moduleName" -ErrorAction SilentlyContinue
                if ($loadedModule) {
                    $moduleInfo.Loaded = $true
                    $moduleInfo.Version = $loadedModule.Version.ToString()
                    $moduleInfo.Status = 'Loaded'
                }
            }
            else {
                $moduleInfo.Status = 'Not Found'
            }
        }
        catch {
            $moduleInfo.Status = "Error: $_"
        }
        
        $health += [PSCustomObject]$moduleInfo
    }
    
    return $health
}

function Clear-Better11Cache {
    <#
    .SYNOPSIS
        Clears Better11 caches
    
    .DESCRIPTION
        Clears various caches used by Better11 modules.
    
    .PARAMETER CacheType
        Type of cache to clear (All, Config, Logs, Temp)
    
    .EXAMPLE
        Clear-Better11Cache -CacheType 'All'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ValidateSet('All', 'Config', 'Logs', 'Temp')]
        [string]$CacheType = 'All'
    )
    
    $cleared = @()
    
    if ($CacheType -eq 'All' -or $CacheType -eq 'Temp') {
        $tempPath = Join-Path $env:TEMP 'Better11'
        if (Test-Path $tempPath) {
            if ($PSCmdlet.ShouldProcess($tempPath, "Clear temp cache")) {
                Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
                $cleared += 'Temp'
            }
        }
    }
    
    if ($CacheType -eq 'All' -or $CacheType -eq 'Logs') {
        $logPath = Join-Path $PSScriptRoot '..\..\Output'
        if (Test-Path $logPath) {
            $oldLogs = Get-ChildItem -Path $logPath -Filter 'better11_*.log' -File | 
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
            if ($oldLogs) {
                if ($PSCmdlet.ShouldProcess("$($oldLogs.Count) log files", "Clear old logs")) {
                    $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
                    $cleared += "Logs ($($oldLogs.Count) files)"
                }
            }
        }
    }
    
    if ($cleared.Count -gt 0) {
        Write-Better11Log -Level 'INFO' -Message "Cleared caches: $($cleared -join ', ')"
    }
    
    return $cleared
}

#endregion

#region Performance Monitoring

function Start-Better11PerformanceMonitor {
    <#
    .SYNOPSIS
        Starts a performance monitor for an operation
    
    .DESCRIPTION
        Creates a performance monitoring object that tracks execution time, memory usage, and other metrics.
    
    .PARAMETER OperationName
        Name of the operation being monitored
    
    .EXAMPLE
        $monitor = Start-Better11PerformanceMonitor -OperationName 'Package Installation'
        # ... do work ...
        $metrics = Stop-Better11PerformanceMonitor -Monitor $monitor
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$OperationName
    )
    
    return @{
        OperationName = $OperationName
        StartTime     = Get-Date
        StartMemory   = [GC]::GetTotalMemory($false)
        ProcessorTime = (Get-Process -Id $PID).TotalProcessorTime
        Stopwatch     = [System.Diagnostics.Stopwatch]::StartNew()
    }
}

function Stop-Better11PerformanceMonitor {
    <#
    .SYNOPSIS
        Stops a performance monitor and returns metrics
    
    .DESCRIPTION
        Stops the performance monitor and calculates final metrics.
    
    .PARAMETER Monitor
        Performance monitor object from Start-Better11PerformanceMonitor
    
    .EXAMPLE
        $metrics = Stop-Better11PerformanceMonitor -Monitor $monitor
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor
    )
    
    $Monitor.Stopwatch.Stop()
    $endMemory = [GC]::GetTotalMemory($false)
    $endProcessorTime = (Get-Process -Id $PID).TotalProcessorTime
    
    $metrics = @{
        OperationName   = $Monitor.OperationName
        DurationMs      = $Monitor.Stopwatch.ElapsedMilliseconds
        DurationSeconds = $Monitor.Stopwatch.Elapsed.TotalSeconds
        MemoryUsedMB    = [math]::Round(($endMemory - $Monitor.StartMemory) / 1MB, 2)
        ProcessorTimeMs = ($endProcessorTime - $Monitor.ProcessorTime).TotalMilliseconds
        StartTime       = $Monitor.StartTime
        EndTime         = Get-Date
    }
    
    Write-Better11Log -Level 'DEBUG' -Message "Performance: $($Monitor.OperationName) completed in $($metrics.DurationSeconds)s, Memory: $($metrics.MemoryUsedMB)MB"
    
    return $metrics
}

function Get-Better11PerformanceReport {
    <#
    .SYNOPSIS
        Gets a performance report for Better11 operations
    
    .DESCRIPTION
        Retrieves performance metrics for recent Better11 operations.
    
    .EXAMPLE
        Get-Better11PerformanceReport
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param()
    
    # Return performance history if it exists
    if ($script:PerformanceHistory) {
        return $script:PerformanceHistory
    }
    else {
        Write-Verbose "No performance history available"
        return @()
    }
}

#endregion

#region Configuration Validation

function Test-Better11Config {
    <#
    .SYNOPSIS
        Validates Better11 configuration
    
    .DESCRIPTION
        Performs comprehensive validation of Better11 configuration to ensure all required settings are present and valid.
    
    .PARAMETER ConfigPath
        Path to configuration file to validate
    
    .PARAMETER ThrowOnError
        Throw an exception if validation fails
    
    .EXAMPLE
        Test-Better11Config -ConfigPath "C:\Better11\config.json"
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [string]$ConfigPath = $script:ConfigPath,
        
        [Parameter()]
        [switch]$ThrowOnError
    )
    
    $result = @{
        Valid    = $true
        Errors   = @()
        Warnings = @()
    }
    
    try {
        # Check if config file exists
        if (-not (Test-Path $ConfigPath)) {
            $result.Errors += "Configuration file not found: $ConfigPath"
            $result.Valid = $false
        }
        else {
            # Load and validate config
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            
            # Validate required fields
            if (-not $config.name) {
                $result.Errors += "Missing required field: name"
                $result.Valid = $false
            }
            
            if (-not $config.version) {
                $result.Errors += "Missing required field: version"
                $result.Valid = $false
            }
            
            # Validate options
            if ($config.options) {
                if ($null -eq $config.options.maxConcurrency -or $config.options.maxConcurrency -lt 1) {
                    $result.Warnings += "maxConcurrency should be at least 1"
                }
            }
            else {
                $result.Warnings += "No options section found in configuration"
            }
            
            # Validate ISO settings if buildISO is enabled
            if ($config.options.buildISO -and -not $config.iso) {
                $result.Errors += "buildISO is enabled but ISO settings are missing"
                $result.Valid = $false
            }
        }
    }
    catch {
        $result.Errors += "Failed to validate configuration: $_"
        $result.Valid = $false
    }
    
    if (-not $result.Valid -and $ThrowOnError) {
        throw "Configuration validation failed: $($result.Errors -join '; ')"
    }
    
    return $result
}

function Repair-Better11Config {
    <#
    .SYNOPSIS
        Repairs Better11 configuration by applying defaults
    
    .DESCRIPTION
        Repairs a broken or incomplete configuration file by applying default values.
    
    .PARAMETER ConfigPath
        Path to configuration file to repair
    
    .PARAMETER BackupOriginal
        Create a backup of the original configuration
    
    .EXAMPLE
        Repair-Better11Config -ConfigPath "C:\Better11\config.json" -BackupOriginal
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$ConfigPath = $script:ConfigPath,
        
        [Parameter()]
        [switch]$BackupOriginal
    )
    
    if ($PSCmdlet.ShouldProcess($ConfigPath, "Repair configuration")) {
        try {
            # Backup if requested
            if ($BackupOriginal -and (Test-Path $ConfigPath)) {
                $backupPath = "$ConfigPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Copy-Item -Path $ConfigPath -Destination $backupPath -Force
                Write-Better11Log -Level 'INFO' -Message "Backed up configuration to $backupPath"
            }
            
            # Load existing config or use empty object
            $config = if (Test-Path $ConfigPath) {
                Get-Content $ConfigPath -Raw | ConvertFrom-Json
            }
            else {
                [PSCustomObject]@{}
            }
            
            # Apply defaults
            $defaults = Get-Better11DefaultConfig
            
            foreach ($key in $defaults.Keys) {
                if (-not $config.$key) {
                    $config | Add-Member -MemberType NoteProperty -Name $key -Value $defaults[$key] -Force
                }
            }
            
            # Save repaired config
            $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
            Write-Better11Log -Level 'INFO' -Message "Repaired configuration at $ConfigPath"
            
            return $true
        }
        catch {
            Write-Error "Failed to repair configuration: $_"
            throw
        }
    }
    
    return $false
}

#endregion

#region Module Dependency Management

function Test-Better11Dependencies {
    <#
    .SYNOPSIS
        Tests if all Better11 module dependencies are met
    
    .DESCRIPTION
        Checks if all required PowerShell modules and external dependencies are installed and available.
    
    .PARAMETER IncludeOptional
        Also check optional dependencies
    
    .EXAMPLE
        Test-Better11Dependencies
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [switch]$IncludeOptional
    )
    
    $result = @{
        AllMet   = $true
        Required = @()
        Optional = @()
    }
    
    # Check required Better11 modules
    $requiredModules = @('Core', 'Install', 'Drivers', 'Retry', 'Tweaks')
    foreach ($moduleName in $requiredModules) {
        $modulePath = Get-Better11ModulePath -ModuleName $moduleName -ErrorAction SilentlyContinue
        $dependency = @{
            Name      = "Better11.$moduleName"
            Type      = 'Module'
            Required  = $true
            Available = [bool]$modulePath
            Path      = $modulePath
        }
        $result.Required += $dependency
        if (-not $dependency.Available) {
            $result.AllMet = $false
        }
    }
    
    # Check external dependencies
    $externalDeps = @(
        @{ Name = 'winget'; Command = 'winget'; Required = $true }
        @{ Name = 'DISM'; Command = 'dism.exe'; Required = $true }
        @{ Name = 'Chocolatey'; Command = 'choco'; Required = $false }
        @{ Name = 'Scoop'; Command = 'scoop'; Required = $false }
    )
    
    foreach ($dep in $externalDeps) {
        $cmd = Get-Command $dep.Command -ErrorAction SilentlyContinue
        $dependency = @{
            Name      = $dep.Name
            Type      = 'External'
            Required  = $dep.Required
            Available = [bool]$cmd
            Path      = if ($cmd) { $cmd.Path } else { $null }
        }
        
        if ($dep.Required) {
            $result.Required += $dependency
            if (-not $dependency.Available) {
                $result.AllMet = $false
            }
        }
        elseif ($IncludeOptional) {
            $result.Optional += $dependency
        }
    }
    
    return $result
}

function Install-Better11Dependencies {
    <#
    .SYNOPSIS
        Installs missing Better11 dependencies
    
    .DESCRIPTION
        Attempts to install missing dependencies for Better11 modules.
    
    .PARAMETER Force
        Force installation even if dependencies appear to be present
    
    .EXAMPLE
        Install-Better11Dependencies
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    if ($PSCmdlet.ShouldProcess("Better11 Dependencies", "Install missing dependencies")) {
        Assert-Better11AdminRights
        
        $dependencies = Test-Better11Dependencies
        $installed = @()
        
        foreach ($dep in $dependencies.Required) {
            if (-not $dep.Available -or $Force) {
                Write-Better11Log -Level 'INFO' -Message "Installing dependency: $($dep.Name)"
                
                try {
                    switch ($dep.Name) {
                        'winget' {
                            # Install App Installer from Microsoft Store or GitHub
                            Write-Warning "Please install winget manually from Microsoft Store or https://github.com/microsoft/winget-cli"
                        }
                        'Chocolatey' {
                            # Install Chocolatey
                            Set-ExecutionPolicy Bypass -Scope Process -Force
                            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                            $installed += $dep.Name
                        }
                        default {
                            Write-Warning "Cannot automatically install $($dep.Name)"
                        }
                    }
                }
                catch {
                    Write-Error "Failed to install $($dep.Name): $_"
                }
            }
        }
        
        if ($installed.Count -gt 0) {
            Write-Better11Log -Level 'INFO' -Message "Installed dependencies: $($installed -join ', ')"
        }
        
        return $installed
    }
    
    return @()
}

#endregion

#region Telemetry and Diagnostics

function Get-Better11DiagnosticInfo {
    <#
    .SYNOPSIS
        Gets comprehensive diagnostic information
    
    .DESCRIPTION
        Collects comprehensive diagnostic information for troubleshooting Better11 issues.
    
    .PARAMETER IncludePerformance
        Include performance metrics in the diagnostic report
    
    .EXAMPLE
        Get-Better11DiagnosticInfo -IncludePerformance
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [switch]$IncludePerformance
    )
    
    $diagnostic = @{
        Timestamp           = Get-Date
        SystemInfo          = Get-Better11SystemInfo
        Prerequisites       = Test-Better11Prerequisites -IncludeOptional
        Dependencies        = Test-Better11Dependencies -IncludeOptional
        ModuleHealth        = Get-Better11ModuleHealth
        NetworkConnectivity = Test-Better11NetworkConnectivity
        ConfigValidation    = Test-Better11Config
    }
    
    if ($IncludePerformance) {
        $diagnostic.Performance = Get-Better11PerformanceReport
    }
    
    return $diagnostic
}

function Export-Better11DiagnosticReport {
    <#
    .SYNOPSIS
        Exports a diagnostic report to a file
    
    .DESCRIPTION
        Exports comprehensive diagnostic information to a JSON file for troubleshooting.
    
    .PARAMETER OutputPath
        Path where the diagnostic report should be saved
    
    .PARAMETER IncludePerformance
        Include performance metrics in the report
    
    .EXAMPLE
        Export-Better11DiagnosticReport -OutputPath "C:\Better11\diagnostic_report.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$OutputPath = (Join-Path $PWD "better11_diagnostic_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"),
        
        [Parameter()]
        [switch]$IncludePerformance
    )
    
    try {
        $diagnosticInfo = Get-Better11DiagnosticInfo -IncludePerformance:$IncludePerformance
        $diagnosticInfo | ConvertTo-Json -Depth 10 | Set-Content $OutputPath
        Write-Better11Log -Level 'INFO' -Message "Diagnostic report exported to $OutputPath"
        return $OutputPath
    }
    catch {
        Write-Error "Failed to export diagnostic report: $_"
        throw
    }
}

#endregion

# Initialize logger on module import
Initialize-Better11Logger -LogLevel 'INFO' | Out-Null

# Export functions
Export-ModuleMember -Function @(
    # Configuration Management
    'Get-Better11Config',
    'Get-Better11DefaultConfig',
    'Set-Better11Config',
    'Test-Better11Config',
    'Repair-Better11Config',
    
    # Logging Integration
    'Initialize-Better11Logger',
    'Write-Better11Log',
    
    # Module Utilities
    'Test-Better11Prerequisites',
    'Get-Better11ModulePath',
    'Import-Better11Module',
    'Invoke-Better11Action',
    
    # Validation & Helpers
    'Test-Better11AdminRights',
    'Assert-Better11AdminRights',
    'Get-Better11SystemInfo',
    'Test-Better11NetworkConnectivity',
    'Get-Better11ModuleHealth',
    'Clear-Better11Cache',
    
    # Performance Monitoring
    'Start-Better11PerformanceMonitor',
    'Stop-Better11PerformanceMonitor',
    'Get-Better11PerformanceReport',
    
    # Dependency Management
    'Test-Better11Dependencies',
    'Install-Better11Dependencies',
    
    # Telemetry and Diagnostics
    'Get-Better11DiagnosticInfo',
    'Export-Better11DiagnosticReport'
)
