#Requires -Version 7.0

<#
.SYNOPSIS
    BetterShell Watcher — File system monitoring with intelligent event processing.
.DESCRIPTION
    Provides file system watchers with debouncing, pattern filtering, event aggregation,
    and action pipelines for automated responses to file changes.
#>

using namespace System.IO
using namespace System.Collections.Concurrent
using namespace System.Collections.Generic

$script:ActiveWatchers = [ConcurrentDictionary[string, FileSystemWatcher]]::new()
$script:WatcherConfigs = [ConcurrentDictionary[string, hashtable]]::new()
$script:EventBuffer = [ConcurrentDictionary[string, List[hashtable]]]::new()

function New-B11FileWatcher {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,

        [Parameter()]
        [string]$Filter = '*.*',

        [Parameter()]
        [switch]$IncludeSubdirectories,

        [Parameter()]
        [System.IO.NotifyFilters]$NotifyFilter = ([NotifyFilters]::FileName -bor [NotifyFilters]::LastWrite -bor [NotifyFilters]::DirectoryName),

        [Parameter()]
        [int]$DebounceMilliseconds = 300,

        [Parameter()]
        [string[]]$ExcludePattern = @(),

        [Parameter()]
        [string]$Name
    )

    $watcherName = if ($Name) { $Name } else { "watcher_$(Get-Random -Maximum 99999)" }

    $watcher = [FileSystemWatcher]::new($Path, $Filter)
    $watcher.IncludeSubdirectories = $IncludeSubdirectories.IsPresent
    $watcher.NotifyFilter = $NotifyFilter
    $watcher.EnableRaisingEvents = $false

    $config = @{
        Name                   = $watcherName
        Path                   = $Path
        Filter                 = $Filter
        IncludeSubdirectories  = $IncludeSubdirectories.IsPresent
        DebounceMs             = $DebounceMilliseconds
        ExcludePatterns        = $ExcludePattern
        Actions                = [List[scriptblock]]::new()
        CreatedAt              = [datetime]::UtcNow
        EventCount             = 0
        IsRunning              = $false
    }

    $null = $script:ActiveWatchers.TryAdd($watcherName, $watcher)
    $null = $script:WatcherConfigs.TryAdd($watcherName, $config)
    $null = $script:EventBuffer.TryAdd($watcherName, [List[hashtable]]::new())

    [PSCustomObject]@{
        PSTypeName = 'B11.FileWatcher'
        Name       = $watcherName
        Path       = $Path
        Filter     = $Filter
        Status     = 'Created'
    }
}

function Start-B11FileWatcher {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if (-not $script:ActiveWatchers.ContainsKey($Name)) {
        Write-Error "Watcher '$Name' not found." -ErrorAction Stop
        return
    }

    if ($PSCmdlet.ShouldProcess($Name, "Start file watcher")) {

    $watcher = $script:ActiveWatchers[$Name]
    $config = $script:WatcherConfigs[$Name]

    $eventAction = {
        $evt = $Event.SourceEventArgs
        $watchName = $Event.MessageData.WatcherName
        $cfg = $Event.MessageData.Config
        $buffer = $Event.MessageData.Buffer

        # Check exclusion patterns
        foreach ($pattern in $cfg.ExcludePatterns) {
            if ($evt.Name -like $pattern) { return }
        }

        $entry = @{
            ChangeType = $evt.ChangeType.ToString()
            FullPath   = $evt.FullPath
            Name       = $evt.Name
            Timestamp  = [datetime]::UtcNow
        }

        $buffer.Add($entry)
        $cfg.EventCount++

        foreach ($action in $cfg.Actions) {
            try {
                & $action $entry
            } catch {
                Write-Warning "Watcher action failed: $_"
            }
        }
    }

    $messageData = @{
        WatcherName = $Name
        Config      = $config
        Buffer      = $script:EventBuffer[$Name]
    }

    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $eventAction -MessageData $messageData -SourceIdentifier "${Name}_Changed" | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $eventAction -MessageData $messageData -SourceIdentifier "${Name}_Created" | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $eventAction -MessageData $messageData -SourceIdentifier "${Name}_Deleted" | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $eventAction -MessageData $messageData -SourceIdentifier "${Name}_Renamed" | Out-Null

    $watcher.EnableRaisingEvents = $true
    $config.IsRunning = $true

    [PSCustomObject]@{
        PSTypeName = 'B11.FileWatcher'
        Name       = $Name
        Path       = $config.Path
        Status     = 'Running'
    }
    }
}

function Stop-B11FileWatcher {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Stop file watcher')) {
        if ($script:ActiveWatchers.ContainsKey($Name)) {
            $script:ActiveWatchers[$Name].EnableRaisingEvents = $false
            $script:WatcherConfigs[$Name].IsRunning = $false
            @("${Name}_Changed", "${Name}_Created", "${Name}_Deleted", "${Name}_Renamed") | ForEach-Object {
                Unregister-Event -SourceIdentifier $_ -ErrorAction SilentlyContinue
            }
        }

        [PSCustomObject]@{
            PSTypeName = 'B11.FileWatcher'
            Name       = $Name
            Status     = 'Stopped'
        }
    }
}

function Remove-B11FileWatcher {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Remove file watcher')) {
        Stop-B11FileWatcher -Name $Name
        $w = $null
        $null = $script:ActiveWatchers.TryRemove($Name, [ref]$w)
        if ($w) { $w.Dispose() }
        $c = $null
        $null = $script:WatcherConfigs.TryRemove($Name, [ref]$c)
        $b = $null
        $null = $script:EventBuffer.TryRemove($Name, [ref]$b)
    }
}

function Get-B11FileWatcher {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string]$Name
    )

    if ($Name) {
        if ($script:WatcherConfigs.ContainsKey($Name)) {
            $config = $script:WatcherConfigs[$Name]
            [PSCustomObject]@{
                PSTypeName = 'B11.FileWatcher'
                Name       = $config.Name
                Path       = $config.Path
                Filter     = $config.Filter
                IsRunning  = $config.IsRunning
                EventCount = $config.EventCount
                CreatedAt  = $config.CreatedAt
            }
        }
    } else {
        foreach ($kvp in $script:WatcherConfigs) {
            $config = $kvp.Value
            [PSCustomObject]@{
                PSTypeName = 'B11.FileWatcher'
                Name       = $config.Name
                Path       = $config.Path
                Filter     = $config.Filter
                IsRunning  = $config.IsRunning
                EventCount = $config.EventCount
                CreatedAt  = $config.CreatedAt
            }
        }
    }
}

function Add-B11WatcherAction {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [scriptblock]$Action
    )

    if (-not $script:WatcherConfigs.ContainsKey($Name)) {
        Write-Error "Watcher '$Name' not found." -ErrorAction Stop
        return
    }

    $script:WatcherConfigs[$Name].Actions.Add($Action)
}

function Get-B11WatcherEvents {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [int]$Last = 50,

        [Parameter()]
        [string]$ChangeType
    )

    if (-not $script:EventBuffer.ContainsKey($Name)) {
        Write-Error "Watcher '$Name' not found." -ErrorAction Stop
        return
    }

    $events = $script:EventBuffer[$Name] | Select-Object -Last $Last
    if ($ChangeType) {
        $events = $events | Where-Object { $_.ChangeType -eq $ChangeType }
    }

    foreach ($evt in $events) {
        [PSCustomObject]@{
            PSTypeName = 'B11.WatcherEvent'
            ChangeType = $evt.ChangeType
            FullPath   = $evt.FullPath
            Name       = $evt.Name
            Timestamp  = $evt.Timestamp
        }
    }
}

function Clear-B11WatcherEvents {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Clear watcher event buffer')) {
        if ($script:EventBuffer.ContainsKey($Name)) {
            $script:EventBuffer[$Name].Clear()
        }
    }
}

function Watch-B11Path {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory, Position = 1)]
        [scriptblock]$Action,

        [Parameter()]
        [string]$Filter = '*.*',

        [Parameter()]
        [switch]$Recurse,

        [Parameter()]
        [int]$TimeoutSeconds = 0
    )

    $watcher = New-B11FileWatcher -Path $Path -Filter $Filter -IncludeSubdirectories:$Recurse -Name "quick_$(Get-Random)"
    Add-B11WatcherAction -Name $watcher.Name -Action $Action
    $started = Start-B11FileWatcher -Name $watcher.Name

    if ($TimeoutSeconds -gt 0) {
        Start-Sleep -Seconds $TimeoutSeconds
        Stop-B11FileWatcher -Name $watcher.Name
        Remove-B11FileWatcher -Name $watcher.Name
    }

    $started
}

function Get-B11WatcherStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string]$Name
    )

    $watchers = if ($Name) { @($script:WatcherConfigs[$Name]) } else { $script:WatcherConfigs.Values }

    foreach ($config in $watchers) {
        if (-not $config) { continue }
        $events = $script:EventBuffer[$config.Name]
        $grouped = $events | Group-Object -Property ChangeType

        [PSCustomObject]@{
            PSTypeName  = 'B11.WatcherStats'
            Name        = $config.Name
            TotalEvents = $config.EventCount
            IsRunning   = $config.IsRunning
            ByType      = ($grouped | ForEach-Object { @{ $_.Name = $_.Count } })
            Uptime      = if ($config.IsRunning) { [datetime]::UtcNow - $config.CreatedAt } else { [timespan]::Zero }
        }
    }
}

function Set-B11WatcherFilter {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [string[]]$ExcludePattern,

        [Parameter()]
        [string]$Filter
    )

    if (-not $script:WatcherConfigs.ContainsKey($Name)) {
        Write-Error "Watcher '$Name' not found." -ErrorAction Stop
        return
    }

    if ($ExcludePattern) {
        $script:WatcherConfigs[$Name].ExcludePatterns = $ExcludePattern
    }

    if ($Filter -and $script:ActiveWatchers.ContainsKey($Name)) {
        $script:ActiveWatchers[$Name].Filter = $Filter
        $script:WatcherConfigs[$Name].Filter = $Filter
    }
}

function Export-B11WatcherConfig {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [string]$Path
    )

    if (-not $script:WatcherConfigs.ContainsKey($Name)) {
        Write-Error "Watcher '$Name' not found." -ErrorAction Stop
        return
    }

    $config = $script:WatcherConfigs[$Name]
    $export = @{
        Name                  = $config.Name
        Path                  = $config.Path
        Filter                = $config.Filter
        IncludeSubdirectories = $config.IncludeSubdirectories
        DebounceMs            = $config.DebounceMs
        ExcludePatterns       = $config.ExcludePatterns
    }

    $export | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Encoding utf8
}

function Import-B11WatcherConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path
    )

    $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
    $params = @{
        Path                  = $config.Path
        Filter                = $config.Filter
        IncludeSubdirectories = [bool]$config.IncludeSubdirectories
        DebounceMilliseconds  = $config.DebounceMs
        ExcludePattern        = @($config.ExcludePatterns)
        Name                  = $config.Name
    }

    New-B11FileWatcher @params
}

function Test-B11WatcherHealth {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string]$Name
    )

    $watchers = if ($Name) {
        @{ $Name = $script:ActiveWatchers[$Name] }
    } else {
        $script:ActiveWatchers
    }

    foreach ($kvp in $watchers.GetEnumerator()) {
        $healthy = $true
        $issues = [List[string]]::new()

        $config = $script:WatcherConfigs[$kvp.Key]
        if (-not (Test-Path $config.Path)) {
            $healthy = $false
            $issues.Add("Watch path does not exist: $($config.Path)")
        }

        if ($config.IsRunning -and -not $kvp.Value.EnableRaisingEvents) {
            $healthy = $false
            $issues.Add("Watcher reports running but events are disabled")
        }

        [PSCustomObject]@{
            PSTypeName = 'B11.WatcherHealth'
            Name       = $kvp.Key
            IsHealthy  = $healthy
            Issues     = $issues
            IsRunning  = $config.IsRunning
            EventCount = $config.EventCount
        }
    }
}

function Restart-B11FileWatcher {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Restart file watcher')) {
        Stop-B11FileWatcher -Name $Name
        Start-Sleep -Milliseconds 100
        Start-B11FileWatcher -Name $Name
    }
}

function Get-B11WatcherEventSummary {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [int]$WindowMinutes = 60
    )

    if (-not $script:EventBuffer.ContainsKey($Name)) {
        Write-Error "Watcher '$Name' not found." -ErrorAction Stop
        return
    }

    $cutoff = [datetime]::UtcNow.AddMinutes(-$WindowMinutes)
    $events = $script:EventBuffer[$Name] | Where-Object { $_.Timestamp -ge $cutoff }

    $grouped = $events | Group-Object -Property ChangeType
    $extensions = $events | ForEach-Object { [System.IO.Path]::GetExtension($_.Name) } | Group-Object | Sort-Object Count -Descending | Select-Object -First 5

    [PSCustomObject]@{
        PSTypeName     = 'B11.WatcherEventSummary'
        Name           = $Name
        WindowMinutes  = $WindowMinutes
        TotalEvents    = $events.Count
        ByChangeType   = ($grouped | ForEach-Object { [PSCustomObject]@{ Type = $_.Name; Count = $_.Count } })
        TopExtensions  = ($extensions | ForEach-Object { [PSCustomObject]@{ Extension = $_.Name; Count = $_.Count } })
    }
}

Export-ModuleMember -Function @(
    'New-B11FileWatcher', 'Start-B11FileWatcher', 'Stop-B11FileWatcher',
    'Remove-B11FileWatcher', 'Get-B11FileWatcher', 'Add-B11WatcherAction',
    'Get-B11WatcherEvents', 'Clear-B11WatcherEvents', 'Watch-B11Path',
    'Get-B11WatcherStatistics', 'Set-B11WatcherFilter', 'Export-B11WatcherConfig',
    'Import-B11WatcherConfig', 'Test-B11WatcherHealth', 'Restart-B11FileWatcher',
    'Get-B11WatcherEventSummary', 'Set-B11WatcherFilter', 'Test-B11WatcherHealth'
)
