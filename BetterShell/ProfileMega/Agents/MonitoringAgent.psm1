#Requires -Version 7.0

# MONITORING AGENT - System health, diagnostics, and alerting

class MonitoringAgent : Agent {
    [hashtable]$HealthChecks
    [hashtable]$Metrics
    [System.Collections.ArrayList]$Alerts
    [hashtable]$Thresholds
    
    MonitoringAgent([EventBus]$eventBus) : base("MonitoringAgent", $eventBus) {
        $this.HealthChecks = @{}
        $this.Metrics = @{
            CPU = @()
            Memory = @()
            Disk = @()
            Network = @()
        }
        $this.Alerts = [System.Collections.ArrayList]::new()
        $this.Thresholds = @{
            CPUPercent = 80
            MemoryPercent = 85
            DiskPercent = 90
            ResponseTime = 5000
        }
    }
    
    [void]SetDefaultConfig() {
        $this.Config = @{
            Enabled = $true
            AutoStart = $true
            MonitorInterval = 30
            EnableAlerts = $true
            AlertOnHighCPU = $true
            AlertOnHighMemory = $true
            AlertOnLowDisk = $true
            AlertOnSlowResponse = $true
        }
    }
    
    [object]ExecuteTask([AgentTask]$task) {
        switch ($task.Type) {
            "health.check" { return $this.RunHealthCheck() }
            "metrics.collect" { return $this.CollectMetrics() }
            "alerts.get" { return $this.GetRecentAlerts(10) }
            "diagnostics.run" { return $this.RunDiagnostics() }
            "processes.analyze" { return $this.AnalyzeProcesses() }
            "services.check" { return $this.CheckCriticalServices() }
            default { throw "Unknown task type: $($task.Type)" }
        }
    }
    
    [hashtable]RunHealthCheck() {
        $health = @{
            Status = "Healthy"
            Timestamp = Get-Date
            Checks = @{}
            Issues = @()
        }
        
        # CPU check
        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
        $health.Checks.CPU = @{
            Current = [math]::Round($cpu, 2)
            Threshold = $this.Thresholds.CPUPercent
            Status = if ($cpu -gt $this.Thresholds.CPUPercent) { "Warning" } else { "OK" }
        }
        if ($cpu -gt $this.Thresholds.CPUPercent) {
            $health.Issues += "High CPU usage: $([math]::Round($cpu, 2))%"
            $health.Status = "Degraded"
        }
        
        # Memory check
        $os = Get-CimInstance Win32_OperatingSystem
        $memPercent = (($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100
        $health.Checks.Memory = @{
            Current = [math]::Round($memPercent, 2)
            Threshold = $this.Thresholds.MemoryPercent
            Status = if ($memPercent -gt $this.Thresholds.MemoryPercent) { "Warning" } else { "OK" }
        }
        if ($memPercent -gt $this.Thresholds.MemoryPercent) {
            $health.Issues += "High memory usage: $([math]::Round($memPercent, 2))%"
            $health.Status = "Degraded"
        }
        
        # Disk check
        $disks = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -and $_.Free }
        foreach ($disk in $disks) {
            $diskPercent = ($disk.Used / ($disk.Used + $disk.Free)) * 100
            $health.Checks."Disk_$($disk.Name)" = @{
                Current = [math]::Round($diskPercent, 2)
                Threshold = $this.Thresholds.DiskPercent
                Status = if ($diskPercent -gt $this.Thresholds.DiskPercent) { "Warning" } else { "OK" }
            }
            if ($diskPercent -gt $this.Thresholds.DiskPercent) {
                $health.Issues += "Low disk space on $($disk.Name): $([math]::Round($diskPercent, 2))%"
                $health.Status = "Degraded"
            }
        }
        
        return $health
    }
    
    [hashtable]CollectMetrics() {
        $metrics = @{
            Timestamp = Get-Date
            CPU = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
            Memory = [math]::Round((Get-Process -Id $PID).WorkingSet64 / 1MB, 2)
            DiskIO = (Get-Counter '\PhysicalDisk(_Total)\Disk Bytes/sec').CounterSamples.CookedValue
            NetworkIO = (Get-Counter '\Network Interface(*)\Bytes Total/sec').CounterSamples.CookedValue | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        }
        
        $this.Metrics.CPU += $metrics.CPU
        $this.Metrics.Memory += $metrics.Memory
        
        # Keep last 100 samples
        if ($this.Metrics.CPU.Count -gt 100) {
            $this.Metrics.CPU = $this.Metrics.CPU[-100..-1]
        }
        
        return $metrics
    }
    
    [hashtable]RunDiagnostics() {
        return @{
            EventLogs = $this.CheckEventLogs()
            FailedServices = $this.GetFailedServices()
            LongRunningProcesses = $this.GetLongRunningProcesses()
            HighMemoryProcesses = $this.GetHighMemoryProcesses(5)
            DiskFragmentation = $this.CheckDiskFragmentation()
        }
    }
    
    [array]CheckEventLogs() {
        $errors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2} -MaxEvents 10 -ErrorAction SilentlyContinue
        return $errors | ForEach-Object {
            @{
                TimeCreated = $_.TimeCreated
                Message = $_.Message
                Source = $_.ProviderName
            }
        }
    }
    
    [array]GetFailedServices() {
        return Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' } |
            Select-Object Name, DisplayName, Status
    }
    
    [array]GetLongRunningProcesses() {
        return Get-Process | Where-Object { $_.StartTime } |
            Where-Object { ((Get-Date) - $_.StartTime).TotalHours -gt 24 } |
            Select-Object ProcessName, Id, StartTime, @{N='Uptime';E={(Get-Date) - $_.StartTime}}
    }
    
    [array]GetHighMemoryProcesses([int]$count) {
        return Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First $count |
            ForEach-Object {
                @{
                    Name = $_.ProcessName
                    PID = $_.Id
                    MemoryMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
                    CPU = $_.CPU
                }
            }
    }
    
    [hashtable]CheckDiskFragmentation() {
        # Simplified check
        return @{
            Supported = $false
            Message = "Use defrag.exe for detailed analysis"
        }
    }
    
    [hashtable]AnalyzeProcesses() {
        $processes = Get-Process
        return @{
            TotalProcesses = $processes.Count
            TotalThreads = ($processes | Measure-Object -Property Threads -Sum).Sum
            TotalHandles = ($processes | Measure-Object -Property HandleCount -Sum).Sum
            TotalMemoryMB = [math]::Round(($processes | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB, 2)
            TopByMemory = $this.GetHighMemoryProcesses(5)
        }
    }
    
    [array]CheckCriticalServices() {
        $critical = @('wuauserv', 'BITS', 'Winmgmt', 'EventLog', 'Dhcp', 'Dnscache')
        return $critical | ForEach-Object {
            $svc = Get-Service $_ -ErrorAction SilentlyContinue
            @{
                Name = $_
                Status = if ($svc) { $svc.Status } else { "Not Found" }
                Running = if ($svc) { $svc.Status -eq 'Running' } else { $false }
            }
        }
    }
    
    [array]GetRecentAlerts([int]$count) {
        return $this.Alerts | Select-Object -Last $count
    }
}

Export-ModuleMember -Function @()
