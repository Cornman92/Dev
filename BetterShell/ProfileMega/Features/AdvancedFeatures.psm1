#Requires -Version 7.0

#region SYSTEM MONITOR AGENT

class SystemMonitorAgent : Agent {
    [hashtable]$Metrics
    [System.Collections.ArrayList]$Alerts
    [hashtable]$Thresholds
    
    SystemMonitorAgent([EventBus]$eventBus) : base("SystemMonitorAgent", $eventBus) {
        $this.Metrics = @{
            CPU = @()
            Memory = @()
            Disk = @()
            Network = @()
        }
        $this.Alerts = [System.Collections.ArrayList]::new()
        $this.Thresholds = @{
            CPU = 80
            Memory = 85
            Disk = 90
            Temperature = 80
        }
    }
    
    [void]SetDefaultConfig() {
        $this.Config = @{
            Enabled = $true
            AutoStart = $true
            MonitorInterval = 30
            AlertOnThreshold = $true
            LogMetrics = $true
            RetentionDays = 7
        }
    }
    
    [object]ExecuteTask([AgentTask]$task) {
        switch ($task.Type) {
            "monitor.system" { return $this.MonitorSystem() }
            "get.metrics" { return $this.GetMetrics($task.Parameters.Duration) }
            "set.threshold" { return $this.SetThreshold($task.Parameters) }
            "check.health" { return $this.CheckSystemHealth() }
            "optimize.system" { return $this.OptimizeSystem() }
            default { throw "Unknown task: $($task.Type)" }
        }
    }
    
    [hashtable]MonitorSystem() {
        $metrics = @{
            Timestamp = Get-Date
            CPU = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
            Memory = [math]::Round((Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue, 2)
            MemoryPercent = [math]::Round(((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize) * 100, 2)
            Disk = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -gt 0} | ForEach-Object {
                @{
                    Drive = $_.Name
                    Used = [math]::Round($_.Used / 1GB, 2)
                    Free = [math]::Round($_.Free / 1GB, 2)
                    PercentFree = [math]::Round(($_.Free / ($_.Used + $_.Free)) * 100, 2)
                }
            }
            Processes = (Get-Process | Measure-Object).Count
            Handles = (Get-Process | Measure-Object -Property Handles -Sum).Sum
        }
        
        # Check thresholds
        if ($metrics.CPU -gt $this.Thresholds.CPU) {
            $this.CreateAlert("CPU", $metrics.CPU, $this.Thresholds.CPU)
        }
        if ($metrics.MemoryPercent -lt (100 - $this.Thresholds.Memory)) {
            $this.CreateAlert("Memory", 100 - $metrics.MemoryPercent, $this.Thresholds.Memory)
        }
        
        # Store metrics
        $this.Metrics.CPU += $metrics
        $this.Metrics.Memory += $metrics
        
        return $metrics
    }
    
    [void]CreateAlert([string]$type, [double]$value, [double]$threshold) {
        $alert = @{
            Type = $type
            Value = $value
            Threshold = $threshold
            Timestamp = Get-Date
            Severity = if ($value -gt $threshold * 1.2) { "Critical" } else { "Warning" }
        }
        
        $this.Alerts.Add($alert) | Out-Null
        
        $message = [AgentMessage]::new("system.alert", $this.Name, $alert)
        $message.Priority = [EventPriority]::High
        $this.EventBus.Publish($message)
    }
    
    [hashtable]CheckSystemHealth() {
        $health = @{
            Status = "Healthy"
            Issues = @()
            Recommendations = @()
        }
        
        # Check disk space
        $lowDisk = Get-PSDrive -PSProvider FileSystem | 
            Where-Object {$_.Free -gt 0 -and ($_.Free / ($_.Used + $_.Free)) * 100 -lt 10}
        
        if ($lowDisk) {
            $health.Status = "Warning"
            $health.Issues += "Low disk space on: $($lowDisk.Name -join ', ')"
            $health.Recommendations += "Clean up unnecessary files or increase storage"
        }
        
        # Check running services
        $stoppedServices = Get-Service | Where-Object {$_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic'}
        if ($stoppedServices) {
            $health.Issues += "Stopped automatic services: $($stoppedServices.Count)"
        }
        
        return $health
    }
    
    [hashtable]OptimizeSystem() {
        $results = @{
            Actions = @()
            Freed = 0
        }
        
        # Clear temp files
        $tempPaths = @(
            $env:TEMP,
            "$env:LOCALAPPDATA\Temp",
            "C:\Windows\Temp"
        )
        
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                $before = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum / 1MB
                
                Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | 
                    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                
                $after = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum / 1MB
                
                $freed = $before - $after
                $results.Freed += $freed
                $results.Actions += "Cleaned $path : $([math]::Round($freed, 2)) MB"
            }
        }
        
        return $results
    }
    
    [hashtable]GetMetrics([int]$duration) {
        $since = (Get-Date).AddMinutes(-$duration)
        
        return @{
            CPU = $this.Metrics.CPU | Where-Object {$_.Timestamp -gt $since}
            Memory = $this.Metrics.Memory | Where-Object {$_.Timestamp -gt $since}
            Disk = $this.Metrics.Disk | Where-Object {$_.Timestamp -gt $since}
        }
    }
    
    [void]SetThreshold([hashtable]$params) {
        foreach ($key in $params.Keys) {
            if ($this.Thresholds.ContainsKey($key)) {
                $this.Thresholds[$key] = $params[$key]
            }
        }
    }
}

#endregion

#region PLUGIN SYSTEM

class PluginManager {
    [hashtable]$Plugins
    [string]$PluginPath
    [System.Collections.ArrayList]$LoadedPlugins
    
    PluginManager() {
        $this.Plugins = @{}
        $this.PluginPath = Join-Path $env:APPDATA "PowerShellAgents\Plugins"
        $this.LoadedPlugins = [System.Collections.ArrayList]::new()
        
        if (-not (Test-Path $this.PluginPath)) {
            New-Item -ItemType Directory -Path $this.PluginPath -Force | Out-Null
        }
    }
    
    [void]RegisterPlugin([string]$name, [scriptblock]$code) {
        $this.Plugins[$name] = @{
            Name = $name
            Code = $code
            Loaded = Get-Date
            Version = "1.0.0"
            Enabled = $true
        }
    }
    
    [void]LoadPlugin([string]$path) {
        if (Test-Path $path) {
            $content = Get-Content $path -Raw
            $pluginName = [System.IO.Path]::GetFileNameWithoutExtension($path)
            
            try {
                $code = [scriptblock]::Create($content)
                $this.RegisterPlugin($pluginName, $code)
                $this.LoadedPlugins.Add($pluginName) | Out-Null
                
                Write-Host "✅ Plugin loaded: $pluginName" -ForegroundColor Green
            } catch {
                Write-Error "Failed to load plugin $pluginName : $_"
            }
        }
    }
    
    [void]LoadAllPlugins() {
        $pluginFiles = Get-ChildItem -Path $this.PluginPath -Filter "*.ps1"
        
        foreach ($file in $pluginFiles) {
            $this.LoadPlugin($file.FullName)
        }
    }
    
    [object]InvokePlugin([string]$name, [hashtable]$params) {
        if ($this.Plugins.ContainsKey($name)) {
            $plugin = $this.Plugins[$name]
            
            if ($plugin.Enabled) {
                return & $plugin.Code $params
            } else {
                throw "Plugin is disabled: $name"
            }
        } else {
            throw "Plugin not found: $name"
        }
    }
    
    [array]ListPlugins() {
        return $this.Plugins.Keys | ForEach-Object {
            @{
                Name = $_
                Version = $this.Plugins[$_].Version
                Enabled = $this.Plugins[$_].Enabled
                Loaded = $this.Plugins[$_].Loaded
            }
        }
    }
    
    [void]EnablePlugin([string]$name) {
        if ($this.Plugins.ContainsKey($name)) {
            $this.Plugins[$name].Enabled = $true
        }
    }
    
    [void]DisablePlugin([string]$name) {
        if ($this.Plugins.ContainsKey($name)) {
            $this.Plugins[$name].Enabled = $false
        }
    }
    
    [void]UnloadPlugin([string]$name) {
        if ($this.Plugins.ContainsKey($name)) {
            $this.Plugins.Remove($name)
            $this.LoadedPlugins.Remove($name)
        }
    }
}

#endregion

#region WORKFLOW ENGINE

class WorkflowEngine {
    [hashtable]$Workflows
    [hashtable]$Templates
    [System.Collections.ArrayList]$ExecutionHistory
    
    WorkflowEngine() {
        $this.Workflows = @{}
        $this.Templates = @{}
        $this.ExecutionHistory = [System.Collections.ArrayList]::new()
        
        $this.InitializeTemplates()
    }
    
    [void]InitializeTemplates() {
        # Deploy workflow
        $this.Templates["Deploy"] = @{
            Name = "Deploy Application"
            Steps = @(
                @{Action = "Test"; Command = "npm test"},
                @{Action = "Build"; Command = "npm run build"},
                @{Action = "Deploy"; Command = "npm run deploy"}
            )
        }
        
        # Backup workflow
        $this.Templates["Backup"] = @{
            Name = "Backup Files"
            Steps = @(
                @{Action = "CreateArchive"; Command = "Compress-Archive"},
                @{Action = "Upload"; Command = "Copy-Item"}
            )
        }
    }
    
    [void]CreateWorkflow([string]$name, [array]$steps) {
        $this.Workflows[$name] = @{
            Name = $name
            Steps = $steps
            Created = Get-Date
            Executions = 0
            LastRun = $null
        }
    }
    
    [hashtable]ExecuteWorkflow([string]$name) {
        if (-not $this.Workflows.ContainsKey($name)) {
            throw "Workflow not found: $name"
        }
        
        $workflow = $this.Workflows[$name]
        $results = @{
            WorkflowName = $name
            Started = Get-Date
            Steps = @()
            Success = $true
        }
        
        foreach ($step in $workflow.Steps) {
            $stepResult = @{
                Step = $step.Action
                Started = Get-Date
            }
            
            try {
                $output = Invoke-Expression $step.Command
                $stepResult.Success = $true
                $stepResult.Output = $output
            } catch {
                $stepResult.Success = $false
                $stepResult.Error = $_.Exception.Message
                $results.Success = $false
                break
            }
            
            $stepResult.Completed = Get-Date
            $stepResult.Duration = ($stepResult.Completed - $stepResult.Started).TotalSeconds
            $results.Steps += $stepResult
        }
        
        $results.Completed = Get-Date
        $results.TotalDuration = ($results.Completed - $results.Started).TotalSeconds
        
        $workflow.Executions++
        $workflow.LastRun = Get-Date
        
        $this.ExecutionHistory.Add($results) | Out-Null
        
        return $results
    }
    
    [void]CreateFromTemplate([string]$templateName, [string]$workflowName) {
        if ($this.Templates.ContainsKey($templateName)) {
            $template = $this.Templates[$templateName]
            $this.CreateWorkflow($workflowName, $template.Steps)
        }
    }
}

#endregion

#region DATABASE AGENT

class DatabaseAgent : Agent {
    [hashtable]$Connections
    [hashtable]$QueryCache
    
    DatabaseAgent([EventBus]$eventBus) : base("DatabaseAgent", $eventBus) {
        $this.Connections = @{}
        $this.QueryCache = @{}
    }
    
    [void]SetDefaultConfig() {
        $this.Config = @{
            Enabled = $true
            AutoStart = $true
            CacheQueries = $true
            CacheTTL = 300
            MaxConnections = 10
        }
    }
    
    [object]ExecuteTask([AgentTask]$task) {
        switch ($task.Type) {
            "connect" { return $this.Connect($task.Parameters) }
            "query" { return $this.ExecuteQuery($task.Parameters) }
            "disconnect" { return $this.Disconnect($task.Parameters.Name) }
            default { throw "Unknown task: $($task.Type)" }
        }
    }
    
    [hashtable]Connect([hashtable]$params) {
        $connName = $params.Name
        $connString = $params.ConnectionString
        $type = $params.Type
        
        try {
            switch ($type) {
                "SQLite" {
                    $conn = New-Object System.Data.SQLite.SQLiteConnection($connString)
                    $conn.Open()
                }
                "PostgreSQL" {
                    $conn = New-Object Npgsql.NpgsqlConnection($connString)
                    $conn.Open()
                }
                "MySQL" {
                    $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connString)
                    $conn.Open()
                }
                default {
                    throw "Unsupported database type: $type"
                }
            }
            
            $this.Connections[$connName] = @{
                Connection = $conn
                Type = $type
                Created = Get-Date
            }
            
            return @{Success = $true; Name = $connName}
        } catch {
            return @{Success = $false; Error = $_.Exception.Message}
        }
    }
    
    [object]ExecuteQuery([hashtable]$params) {
        $connName = $params.Connection
        $query = $params.Query
        
        if (-not $this.Connections.ContainsKey($connName)) {
            throw "Connection not found: $connName"
        }
        
        # Check cache
        $cacheKey = "$connName`:$query"
        if ($this.Config.CacheQueries -and $this.QueryCache.ContainsKey($cacheKey)) {
            $cached = $this.QueryCache[$cacheKey]
            if (((Get-Date) - $cached.Timestamp).TotalSeconds -lt $this.Config.CacheTTL) {
                return $cached.Result
            }
        }
        
        $conn = $this.Connections[$connName].Connection
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $query
        
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null
        
        $result = $dataset.Tables[0] | ConvertTo-Json | ConvertFrom-Json
        
        # Cache result
        if ($this.Config.CacheQueries) {
            $this.QueryCache[$cacheKey] = @{
                Result = $result
                Timestamp = Get-Date
            }
        }
        
        return $result
    }
    
    [void]Disconnect([string]$name) {
        if ($this.Connections.ContainsKey($name)) {
            $this.Connections[$name].Connection.Close()
            $this.Connections.Remove($name)
        }
    }
}

#endregion

#region NOTIFICATION SYSTEM

class NotificationManager {
    [System.Collections.ArrayList]$Notifications
    [hashtable]$Channels
    
    NotificationManager() {
        $this.Notifications = [System.Collections.ArrayList]::new()
        $this.Channels = @{
            Toast = $true
            Console = $true
            Log = $true
        }
    }
    
    [void]Send([string]$title, [string]$message, [string]$severity) {
        $notification = @{
            Title = $title
            Message = $message
            Severity = $severity
            Timestamp = Get-Date
        }
        
        $this.Notifications.Add($notification) | Out-Null
        
        # Console notification
        if ($this.Channels.Console) {
            $color = switch ($severity) {
                "Info" { "Cyan" }
                "Warning" { "Yellow" }
                "Error" { "Red" }
                "Success" { "Green" }
                default { "White" }
            }
            Write-Host "[$severity] $title : $message" -ForegroundColor $color
        }
        
        # Windows toast notification
        if ($this.Channels.Toast -and (Get-Module -ListAvailable BurntToast)) {
            Import-Module BurntToast
            New-BurntToastNotification -Text $title, $message
        }
    }
    
    [array]GetRecent([int]$count) {
        return $this.Notifications | Select-Object -Last $count
    }
    
    [void]Clear() {
        $this.Notifications.Clear()
    }
}

#endregion

#region CACHE MANAGER

class CacheManager {
    [hashtable]$Cache
    [int]$MaxSize
    [int]$DefaultTTL
    
    CacheManager() {
        $this.Cache = @{}
        $this.MaxSize = 1000
        $this.DefaultTTL = 300  # 5 minutes
    }
    
    [void]Set([string]$key, [object]$value, [int]$ttl) {
        if ($this.Cache.Count -ge $this.MaxSize) {
            $this.Evict()
        }
        
        $this.Cache[$key] = @{
            Value = $value
            Expires = (Get-Date).AddSeconds($ttl)
            Hits = 0
            Created = Get-Date
        }
    }
    
    [object]Get([string]$key) {
        if ($this.Cache.ContainsKey($key)) {
            $item = $this.Cache[$key]
            
            if ((Get-Date) -lt $item.Expires) {
                $item.Hits++
                $item.LastAccess = Get-Date
                return $item.Value
            } else {
                $this.Cache.Remove($key)
            }
        }
        
        return $null
    }
    
    [bool]Has([string]$key) {
        if ($this.Cache.ContainsKey($key)) {
            return (Get-Date) -lt $this.Cache[$key].Expires
        }
        return $false
    }
    
    [void]Remove([string]$key) {
        $this.Cache.Remove($key)
    }
    
    [void]Clear() {
        $this.Cache.Clear()
    }
    
    [void]Evict() {
        # Remove expired items first
        $expired = $this.Cache.Keys | Where-Object {
            (Get-Date) -gt $this.Cache[$_].Expires
        }
        
        foreach ($key in $expired) {
            $this.Cache.Remove($key)
        }
        
        # If still over limit, remove least recently used
        if ($this.Cache.Count -ge $this.MaxSize) {
            $lru = $this.Cache.GetEnumerator() | 
                Sort-Object {$_.Value.LastAccess} | 
                Select-Object -First ([math]::Floor($this.MaxSize * 0.1))
            
            foreach ($item in $lru) {
                $this.Cache.Remove($item.Key)
            }
        }
    }
    
    [hashtable]GetStats() {
        $totalHits = ($this.Cache.Values | Measure-Object -Property Hits -Sum).Sum
        
        return @{
            Count = $this.Cache.Count
            MaxSize = $this.MaxSize
            TotalHits = $totalHits
            HitRate = if ($this.Cache.Count -gt 0) { $totalHits / $this.Cache.Count } else { 0 }
        }
    }
}

#endregion

#region SCHEDULER

class TaskScheduler {
    [System.Collections.ArrayList]$Tasks
    [System.Timers.Timer]$Timer
    [bool]$Running
    
    TaskScheduler() {
        $this.Tasks = [System.Collections.ArrayList]::new()
        $this.Running = $false
    }
    
    [void]ScheduleTask([string]$name, [scriptblock]$action, [string]$schedule) {
        $task = @{
            Name = $name
            Action = $action
            Schedule = $schedule
            NextRun = $this.CalculateNextRun($schedule)
            LastRun = $null
            RunCount = 0
            Enabled = $true
        }
        
        $this.Tasks.Add($task) | Out-Null
    }
    
    [datetime]CalculateNextRun([string]$schedule) {
        $now = Get-Date
        
        switch -Regex ($schedule) {
            "^@hourly$|^every hour$" { return $now.AddHours(1) }
            "^@daily$|^every day$" { return $now.Date.AddDays(1) }
            "^@weekly$|^every week$" { return $now.Date.AddDays(7) }
            "^\d+m$" {
                $minutes = [int]($schedule -replace 'm$', '')
                return $now.AddMinutes($minutes)
            }
            "^\d+h$" {
                $hours = [int]($schedule -replace 'h$', '')
                return $now.AddHours($hours)
            }
            default { return $now.AddHours(1) }
        }
    }
    
    [void]Start() {
        $this.Running = $true
        
        $this.Timer = New-Object System.Timers.Timer
        $this.Timer.Interval = 60000  # Check every minute
        $this.Timer.AutoReset = $true
        
        Register-ObjectEvent -InputObject $this.Timer -EventName Elapsed -Action {
            $scheduler = $Event.MessageData
            $scheduler.CheckTasks()
        } -MessageData $this
        
        $this.Timer.Start()
    }
    
    [void]CheckTasks() {
        $now = Get-Date
        
        foreach ($task in $this.Tasks) {
            if ($task.Enabled -and $now -ge $task.NextRun) {
                try {
                    & $task.Action
                    $task.LastRun = $now
                    $task.RunCount++
                    $task.NextRun = $this.CalculateNextRun($task.Schedule)
                } catch {
                    Write-Error "Task failed: $($task.Name) - $_"
                }
            }
        }
    }
    
    [void]Stop() {
        if ($this.Timer) {
            $this.Timer.Stop()
            $this.Timer.Dispose()
        }
        $this.Running = $false
    }
    
    [array]ListTasks() {
        return $this.Tasks | ForEach-Object {
            @{
                Name = $_.Name
                Schedule = $_.Schedule
                NextRun = $_.NextRun
                LastRun = $_.LastRun
                RunCount = $_.RunCount
                Enabled = $_.Enabled
            }
        }
    }
}

#endregion

# Global instances
$Global:PluginManager = [PluginManager]::new()
$Global:WorkflowEngine = [WorkflowEngine]::new()
$Global:NotificationManager = [NotificationManager]::new()
$Global:CacheManager = [CacheManager]::new()
$Global:TaskScheduler = [TaskScheduler]::new()

# Register System Monitor Agent
if ($Global:AgentOrchestrator) {
    $Global:AgentOrchestrator.RegisterAgent([SystemMonitorAgent]::new($Global:AgentOrchestrator.EventBus))
    $Global:AgentOrchestrator.RegisterAgent([DatabaseAgent]::new($Global:AgentOrchestrator.EventBus))
}

Write-Host "✅ Advanced Features Loaded" -ForegroundColor Green
