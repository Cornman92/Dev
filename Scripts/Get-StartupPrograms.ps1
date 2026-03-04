<#
.SYNOPSIS
    Lists programs configured to run at Windows startup.

.DESCRIPTION
    Queries startup items from the registry (HKLM and HKCU Run keys),
    the Startup folders, and scheduled tasks set to trigger at logon.
    Helps identify what runs at boot for performance troubleshooting.

.PARAMETER IncludeDisabled
    Include startup items that are currently disabled.

.PARAMETER OutputPath
    Optional CSV file to export results.

.EXAMPLE
    .\Get-StartupPrograms.ps1
    Lists all enabled startup programs.

.EXAMPLE
    .\Get-StartupPrograms.ps1 -IncludeDisabled -OutputPath "C:\Dev\Artifacts\startup.csv"
    Exports all startup programs (including disabled) to CSV.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$IncludeDisabled,

    [Parameter()]
    [string]$OutputPath
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Startup Programs" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$startupItems = [System.Collections.Generic.List[PSCustomObject]]::new()

# ---- Registry Run Keys ----
$runKeys = @(
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run';         Scope = 'Machine'; Status = 'Enabled' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce';     Scope = 'Machine'; Status = 'Enabled' }
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run';         Scope = 'User';    Status = 'Enabled' }
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce';     Scope = 'User';    Status = 'Enabled' }
    @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Scope = 'Machine (32-bit)'; Status = 'Enabled' }
)

foreach ($key in $runKeys) {
    if (-not (Test-Path $key.Path)) { continue }

    $properties = Get-ItemProperty -Path $key.Path -ErrorAction SilentlyContinue
    if (-not $properties) { continue }

    $properties.PSObject.Properties | Where-Object {
        $_.Name -notmatch '^PS(Path|ParentPath|ChildName|Provider|Drive)$'
    } | ForEach-Object {
        $startupItems.Add([PSCustomObject]@{
            Name    = $_.Name
            Command = $_.Value
            Source  = "Registry ($($key.Scope))"
            Scope   = $key.Scope
            Status  = $key.Status
        })
    }
}

# ---- Startup Folders ----
$startupFolders = @(
    @{ Path = [Environment]::GetFolderPath('Startup');        Scope = 'User' }
    @{ Path = [Environment]::GetFolderPath('CommonStartup');  Scope = 'Machine' }
)

foreach ($folder in $startupFolders) {
    if (-not (Test-Path $folder.Path)) { continue }

    Get-ChildItem -Path $folder.Path -File -ErrorAction SilentlyContinue | ForEach-Object {
        $startupItems.Add([PSCustomObject]@{
            Name    = $_.BaseName
            Command = $_.FullName
            Source  = "Startup Folder ($($folder.Scope))"
            Scope   = $folder.Scope
            Status  = 'Enabled'
        })
    }
}

# ---- Scheduled Tasks (Logon Triggers) ----
$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' }
}

foreach ($task in $tasks) {
    $state = $task.State.ToString()
    if (-not $IncludeDisabled -and $state -eq 'Disabled') { continue }

    $action = ($task.Actions | Select-Object -First 1).Execute
    $startupItems.Add([PSCustomObject]@{
        Name    = $task.TaskName
        Command = $action
        Source  = "Scheduled Task"
        Scope   = if ($task.TaskPath -match '\\Microsoft\\') { 'System' } else { 'Custom' }
        Status  = $state
    })
}

# ---- Display ----
$sortedItems = $startupItems | Sort-Object Source, Name

Write-Host "Found $($sortedItems.Count) startup items:" -ForegroundColor White
Write-Host ""

$sortedItems | ForEach-Object {
    $color = switch ($_.Status) {
        'Enabled' { 'Green' }
        'Ready'   { 'Green' }
        'Disabled'{ 'Gray' }
        default   { 'White' }
    }
    Write-Host ("  [{0,-8}] {1,-35} {2}" -f $_.Status, $_.Name, $_.Source) -ForegroundColor $color
}

if ($OutputPath) {
    $outputDir = Split-Path -Parent $OutputPath
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    $sortedItems | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host ""
    Write-Host "Exported to: $OutputPath" -ForegroundColor Green
}

Write-Host ""
