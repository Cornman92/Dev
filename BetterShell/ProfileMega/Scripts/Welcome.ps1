#Requires -Version 7.0
# Welcome message (dot-sourced by root module when not QuietMode)

if (-not $Global:ProfileConfig.QuietMode) {
    $loadTime = ((Get-Date) - $Global:ProfileLoadStart).TotalMilliseconds

    Clear-Host
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           ProfileMega v$($Global:ProfileVersion) - PowerShell Profile Module        ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Features:" -ForegroundColor Green
    if ($Global:AgentOrchestrator) {
        $agentCount = $Global:AgentOrchestrator.Agents.Count
        Write-Host "    Agents ($agentCount)  Workflows  Plugins  Utilities" -ForegroundColor Cyan
    }
    Write-Host "    Load time: $([math]::Round($loadTime, 0)) ms" -ForegroundColor Gray
    $threshold = $Global:ProfileConfig.LoadTimeTipThresholdMs
    if ($null -ne $threshold -and $loadTime -gt $threshold) {
        Write-Host "    Tip: Use ProfileMode = Lite or disable agents to speed up (profile-help)." -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  Quick: profile-help | qh | Get-AgentStatus" -ForegroundColor Magenta
    Write-Host ""
}
