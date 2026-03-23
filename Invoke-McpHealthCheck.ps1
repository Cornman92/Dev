#Requires -Version 5.1
<#
.SYNOPSIS
    Checks status of MCP servers in the Dev workspace (for dashboard or CLI).

.DESCRIPTION
    For each *-mcp-server directory under the workspace root, verifies the
    project exists and optionally whether it has required files (e.g. package.json).
    Does not start servers; for full health use integration tests (npm run test:mcp-all).

.PARAMETER WorkspaceRoot
    Workspace root (default: D:\Dev).

.PARAMETER AsJson
    Output results as JSON (for dashboard API or automation).

.EXAMPLE
    .\Invoke-McpHealthCheck.ps1
    .\Invoke-McpHealthCheck.ps1 -AsJson
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $WorkspaceRoot = 'D:\Dev',

    [Parameter()]
    [switch] $AsJson
)

$ErrorActionPreference = 'Stop'

$mcpServers = @(
    'time-utils-mcp-server',
    'code-analysis-mcp-server',
    'powershell-mcp-server',
    'system-info-mcp-server',
    'winget-mcp-server',
    'dotnet-cli-mcp-server',
    'nuget-mcp-server',
    'project-scaffolder-mcp-server',
    'unified-mcp-server'
)

$results = @()
foreach ($name in $mcpServers) {
    $path = Join-Path $WorkspaceRoot $name
    $exists = Test-Path -LiteralPath $path -PathType Container
    $hasPackage = $false
    if ($exists) {
        $hasPackage = Test-Path -LiteralPath (Join-Path $path 'package.json') -PathType Leaf
    }
    $status = if ($exists -and $hasPackage) { 'Ready' } elseif ($exists) { 'NoPackageJson' } else { 'Missing' }
    $results += [PSCustomObject]@{ Name = $name; Status = $status; Path = $path }
}

if ($AsJson) {
    $results | ConvertTo-Json -Depth 3 -Compress
    return
}
$results | Format-Table -AutoSize
return $results
