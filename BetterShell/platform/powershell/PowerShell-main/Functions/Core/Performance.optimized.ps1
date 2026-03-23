# Performance.optimized.ps1
# Advanced performance monitoring and optimization for PowerShell
# Optimized for minimal overhead and maximum efficiency

#region Configuration
$script:PerformanceConfig = @{
    EnablePerformanceCounters = $true
    EnableMemoryOptimization = $true
    EnableGarbageCollection = $true
    GCTimerInterval = 300 # seconds
    MemoryThresholdMB = 500 # MB
    MaxHistoryCount = 1000
    PerformanceHistory = [System.Collections.Queue]::new(1000)
    LastGCRun = [DateTime]::UtcNow
}

# Performance counter cache
$script:perfCounters = @{}
#endregion

#region Private Functions
function Get-PerformanceCounterValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CategoryName,
        
        [Parameter(Mandatory)]
        [string]$CounterName,
        
        [string]$InstanceName = '',
        
        [string]$MachineName = '.'
    )
    
    $cacheKey = "$MachineName\$CategoryName($InstanceName)\$CounterName"
    
    try {
        if (-not $script:perfCounters.ContainsKey($cacheKey)) {
            $counter = [System.Diagnostics.PerformanceCounter]::new(
                $CategoryName,
                $CounterName,
                $InstanceName,
                $MachineName
            )
            
            # First value is always 0, so we read twice
            $null = $counter.NextValue()
            $script:perfCounters[$cacheKey] = $counter
        }
        
        $value = $script:perfCounters[$cacheKey].NextValue()
        return $value
    }
    catch {
        Write-Warning "Failed to read performance counter '$cacheKey': $_"
        return $null
    }
}

function Optimize-Memory {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    $currentProcess = [System.Diagnostics.Process]::GetCurrentProcess()
    $memoryMB = $currentProcess.WorkingSet64 / 1MB
    
    if ($Force -or ($memoryMB -gt $script:PerformanceConfig.MemoryThresholdMB)) {
        Write-Verbose "Optimizing memory usage (Current: $($memoryMB.ToString('N2')) MB)"
        
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
        
        $script:PerformanceConfig.LastGCRun = [DateTime]::UtcNow
        $afterMB = $currentProcess.WorkingSet64 / 1MB
        
        return [PSCustomObject]@{
            BeforeMB = [math]::Round($memoryMB, 2)
            AfterMB = [math]::Round($afterMB, 2)
            ReclaimedMB = [math]::Round(($memoryMB - $afterMB), 2)
            Timestamp = [DateTime]::UtcNow
        }
    }
    
    return $null
}

function Update-PerformanceHistory {
    [CmdletBinding()]
    param()
    
    $cpuUsage = Get-PerformanceCounterValue -CategoryName 'Processor' -CounterName '% Processor Time' -InstanceName '_Total'
    $memoryUsage = Get-PerformanceCounterValue -CategoryName 'Memory' -CounterName 'Available MBytes'
    $process = [System.Diagnostics.Process]::GetCurrentProcess()
    
    $perfData = [PSCustomObject]@{
        Timestamp = [DateTime]::UtcNow
        CpuUsage = [math]::Round($cpuUsage, 2)
        AvailableMemoryMB = [math]::Round($memoryUsage, 2)
        ProcessMemoryMB = [math]::Round(($process.WorkingSet64 / 1MB), 2)
        ThreadCount = $process.Threads.Count
        HandleCount = $process.HandleCount
    }
    
    $script:PerformanceConfig.PerformanceHistory.Enqueue($perfData)
    
    # Trim history if needed
    while ($script:PerformanceConfig.PerformanceHistory.Count -gt $script:PerformanceConfig.MaxHistoryCount) {
        $null = $script:PerformanceConfig.PerformanceHistory.Dequeue()
    }
    
    # Run garbage collection periodically if enabled
    if ($script:PerformanceConfig.EnableGarbageCollection) {
        $timeSinceLastGC = ([DateTime]::UtcNow - $script:PerformanceConfig.LastGCRun).TotalSeconds
        if ($timeSinceLastGC -ge $script:PerformanceConfig.GCTimerInterval) {
            $null = Optimize-Memory -Force
        }
    }
    
    return $perfData
}
#endregion

#region Public Functions
function Get-PerformanceMetrics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [int]$Last = 100,
        
        [ValidateSet('All', 'Cpu', 'Memory', 'Process')]
        [string]$Type = 'All',
        
        [switch]$Raw
    )
    
    $metrics = $script:PerformanceConfig.PerformanceHistory.ToArray() | 
        Select-Object -Last $Last
    
    if (-not $Raw) {
        $metrics = switch ($Type) {
            'Cpu' { $metrics | Select-Object Timestamp, CpuUsage }
            'Memory' { $metrics | Select-Object Timestamp, AvailableMemoryMB, ProcessMemoryMB }
            'Process' { $metrics | Select-Object Timestamp, ProcessMemoryMB, ThreadCount, HandleCount }
            default { $metrics }
        }
    }
    
    return $metrics
}

function Start-PerformanceMonitor {
    [CmdletBinding()]
    param(
        [int]$IntervalSeconds = 5,
        
        [int]$DurationSeconds = 300,
        
        [string]$LogFile = '',
        
        [switch]$ShowUI
    )
    
    $endTime = [DateTime]::UtcNow.AddSeconds($DurationSeconds)
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $counter = 0
    
    if ($ShowUI) {
        Clear-Host
    }
    
    try {
        while ([DateTime]::UtcNow -lt $endTime) {
            $metrics = Update-PerformanceHistory
            $counter++
            
            if ($ShowUI) {
                $elapsed = [math]::Round($timer.Elapsed.TotalSeconds, 1)
                $avgCpu = ($script:PerformanceConfig.PerformanceHistory | 
                    Select-Object -Last 10 | 
                    Measure-Object -Property CpuUsage -Average).Average
                
                $avgCpu = [math]::Round($avgCpu, 1)
                $memUsage = [math]::Round($metrics.ProcessMemoryMB, 1)
                $availMem = [math]::Round($metrics.AvailableMemoryMB, 1)
                
                $status = @"
Performance Monitor - Running for ${elapsed}s (Sample #$counter)
--------------------------------------------------
CPU Usage:    $($metrics.CpuUsage)% (Avg: ${avgCpu}%)
Process Mem:  ${memUsage} MB
Available:    ${availMem} MB
Threads:      $($metrics.ThreadCount)
Handles:      $($metrics.HandleCount)
"@
                
                [System.Console]::SetCursorPosition(0, 0)
                Write-Host $status
            }
            
            if ($LogFile) {
                $metrics | Export-Csv -Path $LogFile -Append -NoTypeInformation
            }
            
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
    finally {
        $timer.Stop()
        if ($ShowUI) {
            Clear-Host
        }
    }
}

function Optimize-PowerShellProcess {
    [CmdletBinding()]
    param(
        [switch]$ForceGC,
        
        [switch]$ResetPerformanceCounters,
        
        [switch]$ClearHistory
    )
    
    $results = @{
        BeforeMemoryMB = [math]::Round(([System.Diagnostics.Process]::GetCurrentProcess().WorkingSet64 / 1MB), 2)
        Optimizations = @()
    }
    
    # Run garbage collection if requested
    if ($ForceGC) {
        $gcResult = Optimize-Memory -Force
        if ($gcResult) {
            $results.Optimizations += "Garbage collection reclaimed $($gcResult.ReclaimedMB) MB"
        }
    }
    
    # Reset performance counters if requested
    if ($ResetPerformanceCounters) {
        $script:perfCounters.Clear()
        $results.Optimizations += "Performance counters reset"
    }
    
    # Clear performance history if requested
    if ($ClearHistory) {
        $script:PerformanceConfig.PerformanceHistory.Clear()
        $results.Optimizations += "Performance history cleared"
    }
    
    $results.AfterMemoryMB = [math]::Round(([System.Diagnostics.Process]::GetCurrentProcess().WorkingSet64 / 1MB), 2)
    $results.MemoryReductionMB = $results.BeforeMemoryMB - $results.AfterMemoryMB
    
    return [PSCustomObject]$results
}
#endregion

# Export public functions
Export-ModuleMember -Function @(
    'Get-PerformanceMetrics',
    'Start-PerformanceMonitor',
    'Optimize-PowerShellProcess',
    'Optimize-Memory'
)

# Start background performance monitoring if enabled
if ($script:PerformanceConfig.EnablePerformanceCounters) {
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Get-Module Performance | Remove-Module -Force -ErrorAction SilentlyContinue
    } -SupportEvent
    
    # Initial performance update
    $null = Update-PerformanceHistory
    
    # Set up timer for periodic updates
    $timer = [System.Timers.Timer]::new(5000) # 5 seconds
    $action = {
        try {
            $null = Update-PerformanceHistory
        }
        catch {
            # Silently handle any errors to prevent breaking the timer
        }
    }
    
    $timerJob = Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action $action
    $timer.Start()
    
    # Clean up timer on module removal
    $MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
        $timer.Stop()
        $timer.Dispose()
        $timerJob | Unregister-Event
        $timerJob | Remove-Job -Force
    }
}

# Optimize memory on module load
if ($script:PerformanceConfig.EnableMemoryOptimization) {
    $null = Optimize-Memory -Force
}
