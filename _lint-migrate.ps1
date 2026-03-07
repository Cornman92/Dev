#Requires -Version 5.1
<#
.SYNOPSIS
    Runs PSScriptAnalyzer on a PowerShell script (default: Migrate-OneDriveDevToLocal.ps1).

.PARAMETER Path
    Path to the script(s) to lint. Default: D:\Dev\Migrate-OneDriveDevToLocal.ps1.
    Accepts multiple paths for batch lint.
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName)]
    [string[]] $Path = @('D:\Dev\Migrate-OneDriveDevToLocal.ps1')
)

$ErrorActionPreference = 'Stop'
$allResults = @()
foreach ($p in $Path) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
        Write-Warning "Skip (not found): $p"
        continue
    }
    $results = Invoke-ScriptAnalyzer -Path $p -Severity Error, Warning
    if ($results) {
        $results | ForEach-Object { $allResults += $_ }
        $results | Format-Table RuleName, Severity, Line, Message -AutoSize | Out-String -Width 220
    } else {
        Write-Host "PSScriptAnalyzer: CLEAN - 0 errors, 0 warnings [$p]" -ForegroundColor Green
    }
    $lines = (Get-Content -LiteralPath $p).Count
    Write-Host "Total lines: $lines [$p]"
}
if ($allResults.Count -gt 0) { exit 1 }
exit 0
