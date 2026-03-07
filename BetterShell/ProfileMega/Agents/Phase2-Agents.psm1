#Requires -Version 7.0
# Phase 2 AI Agents - Registers specialized agents with the profile's AgentOrchestrator.
# Depends on AgentFramework.psm1 (Phase 1) being loaded and Initialize-AgentFramework already called.

#region REGISTER PHASE 2 AGENTS

function Register-Phase2Agents {
    [CmdletBinding()]
    param()
    if (-not $Global:AgentOrchestrator) {
        Write-Warning "AgentOrchestrator not initialized. Run Initialize-AgentFramework first."
        return
    }
    $agentDir = $PSScriptRoot
    # Register MonitoringAgent if the module exists and defines the class
    $monPath = Join-Path $agentDir "MonitoringAgent.psm1"
    if (Test-Path $monPath) {
        try {
            Import-Module $monPath -Force -Global
            $Global:AgentOrchestrator.RegisterAgent([MonitoringAgent]::new($Global:AgentOrchestrator.EventBus))
            Write-Verbose "Registered MonitoringAgent."
        } catch {
            Write-Warning "Could not register MonitoringAgent: $_"
        }
    }
}

#endregion

Export-ModuleMember -Function Register-Phase2Agents
Write-Host "✅ Phase 2 Agents Module Loaded" -ForegroundColor Green
