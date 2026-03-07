#Requires -Version 5.1
<#
.SYNOPSIS
    Wrapper to run Generate-WorkspaceReport.ps1 (for Task Scheduler or cron). (FEATURES-AND-AUTOMATIONS-PLAN 4.1.1)

.DESCRIPTION
    Calls Generate-WorkspaceReport.ps1 and optionally logs to a timestamped file.
    Schedule this script daily (e.g. Windows Task Scheduler) so workspace_report.json stays fresh.

.PARAMETER WorkspaceRoot
    Passed to Generate-WorkspaceReport.ps1 (default: D:\Dev).

.PARAMETER LogDir
    If set, write a log file here (e.g. D:\Dev\logs\workspace-report).

.EXAMPLE
    .\Schedule-WorkspaceReport.ps1
    .\Schedule-WorkspaceReport.ps1 -LogDir D:\Dev\logs
#>

[CmdletBinding()]
param(
    [string] $WorkspaceRoot = 'D:\Dev',
    [string] $LogDir = ''
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$reportScript = Join-Path $scriptDir 'Generate-WorkspaceReport.ps1'

if (-not (Test-Path -LiteralPath $reportScript)) {
    Write-Error "Generate-WorkspaceReport.ps1 not found at $reportScript"
}

if ($LogDir) {
    $null = New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue
    $logFile = Join-Path $LogDir "workspace-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    & $reportScript -WorkspaceRoot $WorkspaceRoot -OutputPath (Join-Path $WorkspaceRoot 'workspace_report.json') 2>&1 | Tee-Object -FilePath $logFile
} else {
    & $reportScript -WorkspaceRoot $WorkspaceRoot -OutputPath (Join-Path $WorkspaceRoot 'workspace_report.json')
}
