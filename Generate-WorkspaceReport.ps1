#Requires -Version 5.1
<#
.SYNOPSIS
    Regenerates workspace_report.json for D:\Dev (project types, file stats, Git status).

.DESCRIPTION
    Scans direct subdirectories of the workspace root, counts script/source files,
    detects Git repos, and outputs a JSON array compatible with the dashboard
    and existing workspace_report.json format.

.PARAMETER WorkspaceRoot
    Root directory to scan (default: D:\Dev).

.PARAMETER OutputPath
    Path for the output JSON file (default: D:\Dev\workspace_report.json).

.EXAMPLE
    .\Generate-WorkspaceReport.ps1
    .\Generate-WorkspaceReport.ps1 -OutputPath D:\Dev\reports\workspace.json
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $WorkspaceRoot = 'D:\Dev',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = 'D:\Dev\workspace_report.json'
)

$ErrorActionPreference = 'Stop'

# Directories to skip (top-level only)
$skipDirs = @(
    'node_modules', '.git', '.cursor', '.claude', 'dist', 'bin', 'obj',
    'vendor', '__pycache__', '.venv', 'logs', 'archive1', 'Complete-Artifacts-Archive'
)

function Get-FileStats {
    param([string]$DirPath)
    $ps = 0; $cs = 0; $ts = 0; $js = 0; $md = 0
    try {
        $files = Get-ChildItem -Path $DirPath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\(node_modules|\.git|dist|bin|obj)\\' }
        foreach ($f in $files) {
            switch -Regex ($f.Extension) {
                '\.ps1$' { $ps++ }
                '\.cs$'  { $cs++ }
                '\.tsx?$' { $ts++ }
                '\.jsx?$' { $js++ }
                '\.md$'  { $md++ }
            }
        }
    } catch { }
    "PS:$ps CS:$cs TS:$ts JS:$js MD:$md"
}

function Get-ProjectType {
    param([string]$DirPath, [string]$Stats)
    if ($Stats -match 'CS:\d+' -and [int]($Stats -replace '.*CS:(\d+).*','$1') -gt 10) {
        $count = ($Stats -replace '.*CS:(\d+).*','$1')
        return ".NET ($count files)"
    }
    if ($Stats -match 'PS:\d+' -and [int]($Stats -replace '.*PS:(\d+).*','$1') -gt 5) {
        $count = ($Stats -replace '.*PS:(\d+).*','$1')
        return "PowerShell ($count files)"
    }
    if ($Stats -match 'TS:\d+|JS:\d+') {
        $ts = if ($Stats -match 'TS:(\d+)') { [int]$Matches[1] } else { 0 }
        $js = if ($Stats -match 'JS:(\d+)') { [int]$Matches[1] } else { 0 }
        return "Node/Web ($ts TS, $js JS)"
    }
    return "Mixed/Other"
}

if (-not (Test-Path -LiteralPath $WorkspaceRoot)) {
    Write-Error "Workspace root not found: $WorkspaceRoot"
}

$report = @()
$dirs = Get-ChildItem -Path $WorkspaceRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin $skipDirs }

foreach ($dir in $dirs) {
    $fullPath = $dir.FullName
    $stats = Get-FileStats -DirPath $fullPath
    $type = Get-ProjectType -DirPath $fullPath -Stats $stats
    $isGit = Test-Path -Path (Join-Path $fullPath '.git') -PathType Container

    $report += [PSCustomObject]@{
        Name     = $dir.Name
        Type     = $type
        IsGitRepo = $isGit
        Stats    = $stats
    }
}

$report = $report | Sort-Object Name
$json = $report | ConvertTo-Json -Depth 3 -Compress
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($OutputPath, $json, $utf8NoBom)
Write-Host "Wrote $OutputPath ($($report.Count) entries)." -ForegroundColor Green
