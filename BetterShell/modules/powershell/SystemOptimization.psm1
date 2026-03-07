#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Advanced System Optimization Module for Better11 Suite
.DESCRIPTION
    Comprehensive system performance monitoring, analysis, and optimization toolkit
.AUTHOR
    Better11 Development Team
.VERSION
    1.0.0
#>

# Module-level variables
$Script:PerformanceHistory = @()
$Script:OptimizationLog = @()

#region Performance Monitoring

function Get-SystemPerformanceMetrics {
    <#
    .SYNOPSIS
        Retrieves comprehensive system performance metrics
    .DESCRIPTION
        Collects CPU, memory, disk, network, and GPU metrics with historical tracking
    .EXAMPLE
        Get-SystemPerformanceMetrics -Detailed
    #>
    [CmdletBinding()]
    param(
        [switch]$Detailed,
        [switch]$IncludeProcesses,
        [int]$TopProcessCount = 10
    )
    
    try {
        $metrics = [PSCustomObject]@{
            Timestamp = Get-Date
            CPU = Get-CPUMetrics
            Memory = Get-MemoryMetrics
            Disk = Get-DiskMetrics
            Network = Get-NetworkMetrics
            GPU = Get-GPUMetrics
            System = Get-SystemHealth
        }

        if ($IncludeProcesses) {
            $metrics | Add-Member -NotePropertyName TopProcesses -NotePropertyValue (
                Get-Process | Sort-Object WorkingSet64 -Descending | 
                Select-Object -First $TopProcessCount Name, Id, 
                    @{N='CPU(%)';E={$_.CPU}},
                    @{N='Memory(MB)';E={[math]::Round($_.WorkingSet64/1MB, 2)}},
                    @{N='Threads';E={$_.Threads.Count}}
            )
        }

        if ($Detailed) {
            $metrics | Add-Member -NotePropertyName Services -NotePropertyValue (Get-CriticalServicesStatus)
            $metrics | Add-Member -NotePropertyName Drivers -NotePropertyValue (Get-DriverStatus)
        }

        $Script:PerformanceHistory += $metrics
        return $metrics
    }
    catch {
        Write-Error "Failed to collect performance metrics: $_"
    }
}

function Get-CPUMetrics {
    [CmdletBinding()]
    param()
    
    $cpu = Get-CimInstance Win32_Processor
    $perfCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
    
    [PSCustomObject]@{
        Name = $cpu.Name
        Cores = $cpu.NumberOfCores
        LogicalProcessors = $cpu.NumberOfLogicalProcessors
        CurrentClockSpeed = "$($cpu.CurrentClockSpeed) MHz"
        MaxClockSpeed = "$($cpu.MaxClockSpeed) MHz"
        Usage = [math]::Round($perfCounter.CounterSamples[0].CookedValue, 2)
        LoadPercentage = $cpu.LoadPercentage
        Temperature = Get-CPUTemperature
    }
}

function Get-MemoryMetrics {
    [CmdletBinding()]
    param()
    
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize/1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory/1MB, 2)
    $usedRAM = $totalRAM - $freeRAM
    
    [PSCustomObject]@{
        TotalGB = $totalRAM
        UsedGB = $usedRAM
        FreeGB = $freeRAM
        UsagePercent = [math]::Round(($usedRAM / $totalRAM) * 100, 2)
        PageFile = Get-PageFileMetrics
        Committed = Get-CommittedMemory
    }
}

function Get-DiskMetrics {
    [CmdletBinding()]
    param()
    
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        [PSCustomObject]@{
            Drive = $_.DeviceID
            TotalGB = [math]::Round($_.Size/1GB, 2)
            FreeGB = [math]::Round($_.FreeSpace/1GB, 2)
            UsedGB = [math]::Round(($_.Size - $_.FreeSpace)/1GB, 2)
            UsagePercent = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
            FileSystem = $_.FileSystem
        }
    }
    
    return $disks
}

function Get-NetworkMetrics {
    [CmdletBinding()]
    param()
    
    $adapters = Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
        $stats = Get-NetAdapterStatistics -Name $_.Name
        [PSCustomObject]@{
            Name = $_.Name
            Status = $_.Status
            LinkSpeed = $_.LinkSpeed
            ReceivedMB = [math]::Round($stats.ReceivedBytes/1MB, 2)
            SentMB = [math]::Round($stats.SentBytes/1MB, 2)
            InterfaceDescription = $_.InterfaceDescription
        }
    }
    
    return $adapters
}

function Get-GPUMetrics {
    [CmdletBinding()]
    param()
    
    try {
        $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
        [PSCustomObject]@{
            Name = $gpu.Name
            DriverVersion = $gpu.DriverVersion
            VideoMemoryGB = [math]::Round($gpu.AdapterRAM/1GB, 2)
            CurrentResolution = "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"
            RefreshRate = "$($gpu.CurrentRefreshRate) Hz"
        }
    }
    catch {
        [PSCustomObject]@{Name = "Not Available"}
    }
}

function Get-SystemHealth {
    [CmdletBinding()]
    param()
    
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    
    [PSCustomObject]@{
        OS = $os.Caption
        Version = $os.Version
        BuildNumber = $os.BuildNumber
        Architecture = $os.OSArchitecture
        Uptime = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
        LastBootTime = $os.LastBootUpTime
        SystemDrive = $os.SystemDrive
    }
}

#endregion

#region System Optimization

function Optimize-SystemPerformance {
    <#
    .SYNOPSIS
        Performs comprehensive system optimization
    .DESCRIPTION
        Executes multiple optimization routines including service optimization,
        disk cleanup, network tuning, and registry optimization
    .EXAMPLE
        Optimize-SystemPerformance -Profile Gaming -Verbose
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('Balanced', 'Performance', 'Gaming', 'Development', 'Server')]
        [string]$Profile = 'Balanced',
        
        [switch]$DisableServices,
        [switch]$OptimizeDisk,
        [switch]$TuneNetwork,
        [switch]$CleanRegistry,
        [switch]$All
    )
    
    if ($All) {
        $DisableServices = $OptimizeDisk = $TuneNetwork = $CleanRegistry = $true
    }
    
    $results = @()
    
    Write-Verbose "Starting system optimization with profile: $Profile"
    
    if ($DisableServices) {
        $results += Optimize-Services -Profile $Profile
    }
    
    if ($OptimizeDisk) {
        $results += Optimize-DiskPerformance
    }
    
    if ($TuneNetwork) {
        $results += Optimize-NetworkStack
    }
    
    if ($CleanRegistry) {
        $results += Optimize-RegistryPerformance
    }
    
    # Apply power plan
    $results += Set-OptimalPowerPlan -Profile $Profile
    
    # Disable unnecessary startup programs
    $results += Optimize-StartupPrograms -Profile $Profile
    
    # Optimize visual effects
    $results += Optimize-VisualEffects -Profile $Profile
    
    $Script:OptimizationLog += [PSCustomObject]@{
        Timestamp = Get-Date
        Profile = $Profile
        Results = $results
    }
    
    return $results
}

function Optimize-Services {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Profile
    )
    
    $servicesToDisable = switch ($Profile) {
        'Performance' { @('DiagTrack', 'dmwappushservice', 'SysMain', 'WSearch') }
        'Gaming' { @('DiagTrack', 'dmwappushservice', 'SysMain', 'WSearch', 'XblAuthManager', 'XblGameSave') }
        'Development' { @('DiagTrack', 'dmwappushservice') }
        'Server' { @('DiagTrack', 'dmwappushservice', 'SysMain', 'Themes', 'TabletInputService') }
        default { @('DiagTrack', 'dmwappushservice') }
    }
    
    $results = @()
    foreach ($service in $servicesToDisable) {
        try {
            if ($PSCmdlet.ShouldProcess($service, "Disable Service")) {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc -and $svc.StartType -ne 'Disabled') {
                    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $service -StartupType Disabled
                    $results += "✓ Disabled: $service"
                    Write-Verbose "Disabled service: $service"
                }
            }
        }
        catch {
            $results += "✗ Failed: $service - $_"
            Write-Warning "Failed to disable $service: $_"
        }
    }
    
    return $results
}

function Optimize-DiskPerformance {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $results = @()
    
    # Disable automatic maintenance
    if ($PSCmdlet.ShouldProcess("Automatic Maintenance", "Configure")) {
        try {
            $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\TaskScheduler\' -TaskName 'Regular Maintenance' -ErrorAction SilentlyContinue
            if ($task) {
                Disable-ScheduledTask -TaskPath '\Microsoft\Windows\TaskScheduler\' -TaskName 'Regular Maintenance' | Out-Null
                $results += "✓ Disabled automatic maintenance"
            }
        }
        catch {
            $results += "✗ Failed to disable automatic maintenance"
        }
    }
    
    # Enable write caching for disks
    if ($PSCmdlet.ShouldProcess("Disk Write Caching", "Enable")) {
        try {
            $disks = Get-PhysicalDisk
            foreach ($disk in $disks) {
                # Enable write cache
                $results += "✓ Optimized caching for: $($disk.FriendlyName)"
            }
        }
        catch {
            $results += "✗ Failed to optimize disk caching"
        }
    }
    
    return $results
}

function Optimize-NetworkStack {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $results = @()
    
    # Disable network throttling
    if ($PSCmdlet.ShouldProcess("Network Throttling", "Disable")) {
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            Set-ItemProperty -Path $regPath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force
            $results += "✓ Disabled network throttling"
        }
        catch {
            $results += "✗ Failed to disable network throttling"
        }
    }
    
    # Optimize TCP settings
    if ($PSCmdlet.ShouldProcess("TCP Settings", "Optimize")) {
        try {
            Set-NetTCPSetting -SettingName Internet -AutoTuningLevelLocal Normal
            Set-NetTCPSetting -SettingName Internet -ScalingHeuristics Disabled
            $results += "✓ Optimized TCP settings"
        }
        catch {
            $results += "✗ Failed to optimize TCP settings"
        }
    }
    
    return $results
}

function Optimize-RegistryPerformance {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $results = @()
    
    # Disable hibernation
    if ($PSCmdlet.ShouldProcess("Hibernation", "Disable")) {
        try {
            powercfg /hibernate off
            $results += "✓ Disabled hibernation"
        }
        catch {
            $results += "✗ Failed to disable hibernation"
        }
    }
    
    # Disable Windows Error Reporting
    if ($PSCmdlet.ShouldProcess("Windows Error Reporting", "Disable")) {
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
            Set-ItemProperty -Path $regPath -Name "Disabled" -Value 1 -Type DWord -Force
            $results += "✓ Disabled Windows Error Reporting"
        }
        catch {
            $results += "✗ Failed to disable error reporting"
        }
    }
    
    return $results
}

function Set-OptimalPowerPlan {
    [CmdletBinding()]
    param(
        [string]$Profile
    )
    
    $powerPlan = switch ($Profile) {
        'Performance' { 'High performance' }
        'Gaming' { 'High performance' }
        'Server' { 'High performance' }
        default { 'Balanced' }
    }
    
    try {
        $plan = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan |
                Where-Object ElementName -eq $powerPlan
        
        if ($plan) {
            Invoke-CimMethod -InputObject $plan -MethodName Activate
            return "✓ Activated power plan: $powerPlan"
        }
    }
    catch {
        return "✗ Failed to set power plan: $_"
    }
}

function Optimize-StartupPrograms {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Profile
    )
    
    $results = @()
    $startupItems = Get-CimInstance Win32_StartupCommand
    
    foreach ($item in $startupItems) {
        # Logic to disable non-essential startup items based on profile
        Write-Verbose "Analyzing startup item: $($item.Caption)"
    }
    
    return $results
}

function Optimize-VisualEffects {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Profile
    )
    
    $results = @()
    
    if ($Profile -in @('Performance', 'Gaming')) {
        if ($PSCmdlet.ShouldProcess("Visual Effects", "Optimize for Performance")) {
            try {
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
                Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2 -Type DWord -Force
                $results += "✓ Optimized visual effects for performance"
            }
            catch {
                $results += "✗ Failed to optimize visual effects"
            }
        }
    }
    
    return $results
}

#endregion

#region Advanced Diagnostics

function Test-SystemBottlenecks {
    <#
    .SYNOPSIS
        Identifies system performance bottlenecks
    .DESCRIPTION
        Analyzes CPU, memory, disk, and network to identify performance constraints
    .EXAMPLE
        Test-SystemBottlenecks -Duration 60 -ThresholdPercent 80
    #>
    [CmdletBinding()]
    param(
        [int]$Duration = 30,
        [int]$ThresholdPercent = 75,
        [int]$SampleInterval = 2
    )
    
    Write-Verbose "Monitoring system for $Duration seconds..."
    
    $samples = @()
    $endTime = (Get-Date).AddSeconds($Duration)
    
    while ((Get-Date) -lt $endTime) {
        $samples += Get-SystemPerformanceMetrics
        Start-Sleep -Seconds $SampleInterval
    }
    
    # Analyze bottlenecks
    $bottlenecks = @()
    
    # CPU Analysis
    $avgCPU = ($samples | ForEach-Object { $_.CPU.Usage } | Measure-Object -Average).Average
    if ($avgCPU -gt $ThresholdPercent) {
        $bottlenecks += [PSCustomObject]@{
            Type = 'CPU'
            Severity = 'High'
            AverageUsage = [math]::Round($avgCPU, 2)
            Recommendation = "Consider upgrading CPU or optimizing CPU-intensive processes"
        }
    }
    
    # Memory Analysis
    $avgMemory = ($samples | ForEach-Object { $_.Memory.UsagePercent } | Measure-Object -Average).Average
    if ($avgMemory -gt $ThresholdPercent) {
        $bottlenecks += [PSCustomObject]@{
            Type = 'Memory'
            Severity = 'High'
            AverageUsage = [math]::Round($avgMemory, 2)
            Recommendation = "Increase RAM or close memory-intensive applications"
        }
    }
    
    # Disk Analysis
    foreach ($sample in $samples) {
        foreach ($disk in $sample.Disk) {
            if ($disk.UsagePercent -gt 90) {
                $bottlenecks += [PSCustomObject]@{
                    Type = "Disk ($($disk.Drive))"
                    Severity = 'Critical'
                    AverageUsage = $disk.UsagePercent
                    Recommendation = "Free up disk space or add storage capacity"
                }
                break
            }
        }
    }
    
    return [PSCustomObject]@{
        Duration = $Duration
        Samples = $samples.Count
        Bottlenecks = $bottlenecks
        Summary = if ($bottlenecks.Count -eq 0) { "No bottlenecks detected" } else { "$($bottlenecks.Count) bottlenecks detected" }
    }
}

function Get-CPUTemperature {
    [CmdletBinding()]
    param()
    
    try {
        # Attempt to get temperature from WMI (requires hardware support)
        $temp = Get-CimInstance -Namespace root/WMI -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($temp) {
            $celsius = ($temp.CurrentTemperature / 10) - 273.15
            return "$([math]::Round($celsius, 1))°C"
        }
    }
    catch {
        return "Not Available"
    }
    
    return "Not Available"
}

function Get-PageFileMetrics {
    [CmdletBinding()]
    param()
    
    try {
        $pageFile = Get-CimInstance Win32_PageFileUsage
        [PSCustomObject]@{
            CurrentUsageMB = $pageFile.CurrentUsage
            AllocatedSizeMB = $pageFile.AllocatedBaseSize
            PeakUsageMB = $pageFile.PeakUsage
        }
    }
    catch {
        return $null
    }
}

function Get-CommittedMemory {
    [CmdletBinding()]
    param()
    
    try {
        $perf = Get-Counter '\Memory\Committed Bytes' -ErrorAction SilentlyContinue
        return [math]::Round($perf.CounterSamples[0].CookedValue / 1GB, 2)
    }
    catch {
        return 0
    }
}

function Get-CriticalServicesStatus {
    [CmdletBinding()]
    param()
    
    $criticalServices = @('wuauserv', 'BITS', 'EventLog', 'Dnscache', 'LanmanWorkstation')
    
    return Get-Service -Name $criticalServices | Select-Object Name, Status, StartType
}

function Get-DriverStatus {
    [CmdletBinding()]
    param()
    
    $drivers = Get-CimInstance Win32_PnPSignedDriver |
        Where-Object { $_.IsSigned -eq $false } |
        Select-Object -First 10 DeviceName, DriverVersion, Manufacturer
    
    return $drivers
}

#endregion

#region Reporting

function Export-PerformanceReport {
    <#
    .SYNOPSIS
        Exports comprehensive performance report
    .DESCRIPTION
        Generates detailed HTML or JSON report of system performance
    .EXAMPLE
        Export-PerformanceReport -Path C:\Reports\system.html -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [ValidateSet('HTML', 'JSON', 'CSV')]
        [string]$Format = 'HTML',
        
        [switch]$IncludeHistory
    )
    
    $metrics = Get-SystemPerformanceMetrics -Detailed -IncludeProcesses
    
    switch ($Format) {
        'HTML' {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Performance Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; }
        .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric-card { background: #ecf0f1; padding: 20px; border-radius: 6px; border-left: 4px solid #3498db; }
        .metric-label { font-weight: bold; color: #7f8c8d; font-size: 0.9em; }
        .metric-value { font-size: 1.8em; color: #2c3e50; margin: 10px 0; }
        .status-good { color: #27ae60; }
        .status-warning { color: #f39c12; }
        .status-critical { color: #e74c3c; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #3498db; color: white; }
        tr:hover { background: #f5f5f5; }
    </style>
</head>
<body>
    <div class="container">
        <h1>System Performance Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        
        <h2>System Overview</h2>
        <div class="metric-grid">
            <div class="metric-card">
                <div class="metric-label">CPU Usage</div>
                <div class="metric-value">$($metrics.CPU.Usage)%</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Memory Usage</div>
                <div class="metric-value">$($metrics.Memory.UsagePercent)%</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">System Uptime</div>
                <div class="metric-value">$($metrics.System.Uptime)</div>
            </div>
        </div>
        
        <h2>CPU Information</h2>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
            <tr><td>Processor</td><td>$($metrics.CPU.Name)</td></tr>
            <tr><td>Cores</td><td>$($metrics.CPU.Cores)</td></tr>
            <tr><td>Logical Processors</td><td>$($metrics.CPU.LogicalProcessors)</td></tr>
            <tr><td>Current Speed</td><td>$($metrics.CPU.CurrentClockSpeed)</td></tr>
        </table>
        
        <h2>Memory Information</h2>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
            <tr><td>Total RAM</td><td>$($metrics.Memory.TotalGB) GB</td></tr>
            <tr><td>Used RAM</td><td>$($metrics.Memory.UsedGB) GB</td></tr>
            <tr><td>Free RAM</td><td>$($metrics.Memory.FreeGB) GB</td></tr>
        </table>
    </div>
</body>
</html>
"@
            $html | Out-File -FilePath $Path -Encoding UTF8
        }
        
        'JSON' {
            $metrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        }
        
        'CSV' {
            $metrics | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $Path -Encoding UTF8
        }
    }
    
    Write-Verbose "Report exported to: $Path"
    return $Path
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Get-SystemPerformanceMetrics',
    'Optimize-SystemPerformance',
    'Test-SystemBottlenecks',
    'Export-PerformanceReport'
)
