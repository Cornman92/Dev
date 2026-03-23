#Requires -Version 7.0
<#
.SYNOPSIS
    Phase 1 Agent Framework - Base classes and orchestrator for PowerShell profile agents.
.DESCRIPTION
    Defines Agent, EventBus, AgentTask, AgentMessage, EventPriority, and AgentOrchestrator
    required by MonitoringAgent, SystemMonitorAgent, DatabaseAgent, and other profile agents.
#>

#region ENUMS AND MESSAGING

enum EventPriority {
    Low = 0
    Normal = 1
    High = 2
    Critical = 3
}

class AgentMessage {
    [string]$Type
    [string]$Source
    [object]$Payload
    [EventPriority]$Priority
    [datetime]$Timestamp

    AgentMessage([string]$type, [string]$source, [object]$payload) {
        $this.Type = $type
        $this.Source = $source
        $this.Payload = $payload
        $this.Priority = [EventPriority]::Normal
        $this.Timestamp = Get-Date
    }
}

class AgentTask {
    [string]$Type
    [hashtable]$Parameters
    [datetime]$Created

    AgentTask([string]$type, [hashtable]$parameters) {
        $this.Type = $type
        $this.Parameters = if ($parameters) { $parameters } else { @{} }
        $this.Created = Get-Date
    }
}

#endregion

#region EVENT BUS

class EventBus {
    [System.Collections.ArrayList]$Subscribers
    [System.Collections.Queue]$Queue

    EventBus() {
        $this.Subscribers = [System.Collections.ArrayList]::new()
        $this.Queue = [System.Collections.Queue]::new()
    }

    [void]Subscribe([string]$agentName, [scriptblock]$handler) {
        $this.Subscribers.Add(@{ Agent = $agentName; Handler = $handler }) | Out-Null
    }

    [void]Publish([AgentMessage]$message) {
        $this.Queue.Enqueue($message)
        foreach ($sub in $this.Subscribers) {
            try {
                & $sub.Handler $message
            } catch {
                Write-Warning "EventBus subscriber error: $_"
            }
        }
    }

    [AgentMessage]Dequeue() {
        if ($this.Queue.Count -gt 0) {
            return $this.Queue.Dequeue()
        }
        return $null
    }
}

#endregion

#region BASE AGENT

class Agent {
    [string]$Name
    [EventBus]$EventBus
    [string]$State
    [hashtable]$Config
    [System.Collections.Queue]$TaskQueue

    Agent([string]$name, [EventBus]$eventBus) {
        $this.Name = $name
        $this.EventBus = $eventBus
        $this.State = "Stopped"
        $this.Config = @{}
        $this.TaskQueue = [System.Collections.Queue]::new()
        $this.SetDefaultConfig()
    }

    [void]SetDefaultConfig() {
        $this.Config = @{ Enabled = $true; AutoStart = $false }
    }

    [object]ExecuteTask([AgentTask]$task) {
        return $null
    }

    [void]EnqueueTask([AgentTask]$task) {
        $this.TaskQueue.Enqueue($task)
    }

    [AgentTask]DequeueTask() {
        if ($this.TaskQueue.Count -gt 0) {
            return $this.TaskQueue.Dequeue()
        }
        return $null
    }

    [void]Start() {
        $this.State = "Running"
    }

    [void]Stop() {
        $this.State = "Stopped"
    }

    [void]ProcessQueue() {
        while ($task = $this.DequeueTask()) {
            try {
                $this.ExecuteTask($task) | Out-Null
            } catch {
                Write-Warning "$($this.Name) task failed: $_"
            }
        }
    }
}

#endregion

#region AGENT ORCHESTRATOR

class AgentOrchestrator {
    [EventBus]$EventBus
    [hashtable]$Agents

    AgentOrchestrator() {
        $this.EventBus = [EventBus]::new()
        $this.Agents = @{}
    }

    [void]RegisterAgent([Agent]$agent) {
        $this.Agents[$agent.Name] = $agent
        if ($agent.Config.AutoStart) {
            $agent.Start()
        }
    }

    [void]UnregisterAgent([string]$name) {
        if ($this.Agents.ContainsKey($name)) {
            $this.Agents[$name].Stop()
            $this.Agents.Remove($name)
        }
    }

    [void]StartAll() {
        foreach ($agent in $this.Agents.Values) {
            $agent.Start()
        }
    }

    [void]StopAll() {
        foreach ($agent in $this.Agents.Values) {
            $agent.Stop()
        }
    }

    [hashtable]GetStatus() {
        $status = @{
            Total = $this.Agents.Count
            Running = 0
            Stopped = 0
            Agents = @()
        }
        foreach ($agent in $this.Agents.Values) {
            if ($agent.State -eq "Running") { $status.Running++ } else { $status.Stopped++ }
            $status.Agents += @{ Name = $agent.Name; State = $agent.State }
        }
        return $status
    }
}

#endregion

#region PUBLIC FUNCTIONS

function Initialize-AgentFramework {
    [CmdletBinding()]
    param()
    if (-not $Global:AgentOrchestrator) {
        $Global:AgentOrchestrator = [AgentOrchestrator]::new()
        Write-Verbose "Agent framework initialized."
    }
}

function Stop-AgentFramework {
    [CmdletBinding()]
    param()
    if ($Global:AgentOrchestrator) {
        $Global:AgentOrchestrator.StopAll()
        Write-Verbose "Agent framework stopped."
    }
}

function Get-AgentStatus {
    [CmdletBinding()]
    param()
    if (-not $Global:AgentOrchestrator) {
        Write-Host "Agent framework not loaded." -ForegroundColor Yellow
        return
    }
    $status = $Global:AgentOrchestrator.GetStatus()
    Write-Host "Agents: $($status.Running) running, $($status.Stopped) stopped (total $($status.Total))" -ForegroundColor Cyan
    foreach ($a in $status.Agents) {
        $color = if ($a.State -eq "Running") { "Green" } else { "Gray" }
        Write-Host "  $($a.Name): $($a.State)" -ForegroundColor $color
    }
}

function Show-AgentDashboard {
    [CmdletBinding()]
    param()
    if (-not $Global:AgentOrchestrator) {
        Write-Host "Agent framework not loaded. Enable agents in profile config." -ForegroundColor Yellow
        return
    }
    Clear-Host
    Write-Host "`n  Agent Dashboard" -ForegroundColor Cyan
    Write-Host "  ===============`n" -ForegroundColor Cyan
    Get-AgentStatus
    Write-Host "`n  Commands: Get-AgentStatus, Stop-AgentFramework" -ForegroundColor DarkGray
    Write-Host ""
}

# Export for use by other modules (classes are global when dot-sourced)
Export-ModuleMember -Function Initialize-AgentFramework, Stop-AgentFramework, Get-AgentStatus, Show-AgentDashboard
