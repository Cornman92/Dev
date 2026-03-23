#Requires -Version 5.1
<#
.SYNOPSIS
    Runs all MCP integration tests from the workspace root and reports results.

.DESCRIPTION
    Executes each npm run test:mcp-* script in sequence. Exits with 0 if all pass,
    non-zero if any fail. Use from D:\Dev or set -WorkspaceRoot.

.PARAMETER WorkspaceRoot
    Workspace root containing package.json with test:mcp-* scripts (default: D:\Dev).

.EXAMPLE
    .\Invoke-AllMcpTests.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $WorkspaceRoot = 'D:\Dev'
)

$ErrorActionPreference = 'Stop'
Push-Location $WorkspaceRoot
try {
    $scripts = @(
        'test:mcp-time-utils',
        'test:mcp-code-analysis',
        'test:mcp-powershell',
        'test:mcp-system-info',
        'test:mcp-winget',
        'test:mcp-dotnet-cli',
        'test:mcp-nuget',
        'test:mcp-project-scaffolder'
    )
    $failed = @()
    foreach ($script in $scripts) {
        Write-Host "Running npm run $script ..." -ForegroundColor Cyan
        $p = Start-Process -FilePath 'npm' -ArgumentList 'run', $script -Wait -NoNewWindow -PassThru
        if ($p.ExitCode -ne 0) {
            $failed += $script
            Write-Host "  FAILED (exit $($p.ExitCode))" -ForegroundColor Red
        } else {
            Write-Host "  OK" -ForegroundColor Green
        }
    }
    if ($failed.Count -gt 0) {
        Write-Host "Failed: $($failed -join ', ')" -ForegroundColor Red
        exit 1
    }
    Write-Host "All MCP tests passed." -ForegroundColor Green
    exit 0
} finally {
    Pop-Location
}
