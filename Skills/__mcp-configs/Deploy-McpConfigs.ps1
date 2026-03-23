#Requires -Version 5.1
<#
.SYNOPSIS
    Deploys MCP server configurations and enables all Claude DXT extensions; optionally deploys Cursor MCP config.
.DESCRIPTION
    Applies optimized MCP server configurations for Claude Desktop App including
    GitHub, Brave Search, and all custom MCP servers. Enables and configures all
    DXT extensions (Filesystem, Socket, Desktop Commander, Context7, Windows-MCP).
    With -IncludeCursor, also deploys the same logical set of servers (windows-mcp,
    filesystem-mcp, desktopcommander-mcp, GitHub, Notion) to Cursor's global
    mcp.json at %USERPROFILE%\.cursor\mcp.json, merging with existing servers if present.
.NOTES
    Run this script after adding your API keys to the config files.
    Restart Claude Desktop App and/or Cursor after running this script.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ConfigSource = "$PSScriptRoot",

    [Parameter()]
    [string]$GitHubPAT,

    [Parameter()]
    [string]$BraveApiKey,

    [Parameter()]
    [string]$SocketApiKey,

    [Parameter()]
    [string]$NotionToken,

    [Parameter()]
    [switch]$IncludeCursor,

    [Parameter()]
    [switch]$SkipRestart
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$claudeAppData = Join-Path $env:APPDATA 'Claude'
$extensionSettings = Join-Path $claudeAppData 'Claude Extensions Settings'
$desktopConfig = Join-Path $claudeAppData 'claude_desktop_config.json'

Write-Host '=== MCP Configuration Deployment ===' -ForegroundColor Cyan
Write-Host "Config Source: $ConfigSource" -ForegroundColor Gray
Write-Host "Claude AppData: $claudeAppData" -ForegroundColor Gray

# Validate Claude is installed
if (-not (Test-Path $claudeAppData)) {
    throw "Claude Desktop App data directory not found at: $claudeAppData"
}

# Step 1: Deploy claude_desktop_config.json with MCP servers
Write-Host "`n[1/4] Deploying MCP server configuration..." -ForegroundColor Yellow
$sourceConfig = Join-Path $ConfigSource 'claude_desktop_config.json'
if (Test-Path $sourceConfig) {
    $configContent = Get-Content $sourceConfig -Raw | ConvertFrom-Json

    # Inject API keys if provided
    if ($GitHubPAT) {
        $configContent.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = $GitHubPAT
        Write-Host '  GitHub PAT injected' -ForegroundColor Green
    }
    if ($BraveApiKey) {
        $configContent.mcpServers.'brave-search'.env.BRAVE_API_KEY = $BraveApiKey
        Write-Host '  Brave API key injected' -ForegroundColor Green
    }

    # Validate custom MCP server paths exist
    foreach ($serverName in @('powershell-mcp', 'winget-mcp', 'system-info-mcp',
                              'code-analysis-mcp', 'dotnet-cli-mcp', 'nuget-mcp',
                              'project-scaffolder-mcp')) {
        $serverPath = $configContent.mcpServers.$serverName.args[0]
        if ($serverPath -and -not (Test-Path $serverPath)) {
            Write-Warning "  MCP server path not found: $serverPath (run 'npm run build' in the server project)"
        }
        else {
            Write-Host "  $serverName path validated" -ForegroundColor Green
        }
    }

    if ($PSCmdlet.ShouldProcess($desktopConfig, 'Write MCP configuration')) {
        $configContent | ConvertTo-Json -Depth 10 | Set-Content $desktopConfig -Encoding UTF8
        Write-Host '  claude_desktop_config.json deployed' -ForegroundColor Green
    }
}
else {
    Write-Warning "Source config not found: $sourceConfig"
}

# Step 2: Enable and configure DXT extensions
Write-Host "`n[2/4] Configuring DXT extensions..." -ForegroundColor Yellow
if (-not (Test-Path $extensionSettings)) {
    New-Item -Path $extensionSettings -ItemType Directory -Force | Out-Null
}

# Filesystem - enable with allowed directories
$fsSettings = @{
    isEnabled  = $true
    userConfig = @{
        allowed_directories = @(
            'C:\Users\saymo\OneDrive\Dev'
            'C:\Users\saymo\OneDrive\Dev\Better11'
            'C:\Users\saymo\OneDrive\Dev\Skills'
            'C:\Users\saymo\Desktop'
            'C:\Users\saymo\Downloads'
            'C:\Users\saymo\Documents'
        )
    }
}
$fsSettingsPath = Join-Path $extensionSettings 'ant.dir.ant.anthropic.filesystem.json'
$fsSettings | ConvertTo-Json -Depth 5 | Set-Content $fsSettingsPath -Encoding UTF8
Write-Host '  Filesystem: ENABLED with project directories' -ForegroundColor Green

# Socket - enable with API key
$socketSettings = @{ isEnabled = $true }
if ($SocketApiKey) {
    $socketSettings.userConfig = @{ SOCKET_API_KEY = $SocketApiKey }
    Write-Host '  Socket: ENABLED with API key' -ForegroundColor Green
}
else {
    $socketSettings.userConfig = @{ SOCKET_API_KEY = '<YOUR_SOCKET_API_KEY_HERE>' }
    Write-Warning '  Socket: ENABLED but needs API key (edit settings manually)'
}
$socketPath = Join-Path $extensionSettings 'ant.dir.gh.socketdev.socket-mcp.json'
$socketSettings | ConvertTo-Json -Depth 5 | Set-Content $socketPath -Encoding UTF8

# Ensure remaining extensions stay enabled
$alwaysEnabled = @(
    'ant.dir.cursortouch.windows-mcp'
    'ant.dir.gh.wonderwhy-er.desktopcommandermcp'
    'context7'
)
foreach ($extId in $alwaysEnabled) {
    $extPath = Join-Path $extensionSettings "$extId.json"
    @{ isEnabled = $true } | ConvertTo-Json | Set-Content $extPath -Encoding UTF8
    $displayName = $extId -replace 'ant\.dir\.(cursortouch\.)?|ant\.dir\.gh\.wonderwhy-er\.|', ''
    Write-Host "  $displayName`: ENABLED" -ForegroundColor Green
}

# Step 3: Optimize Desktop Commander config
Write-Host "`n[3/4] Optimizing Desktop Commander..." -ForegroundColor Yellow
Write-Host '  NOTE: Use set_config_value in Claude chat to set:' -ForegroundColor Gray
Write-Host '    fileWriteLineLimit = 100' -ForegroundColor Gray
Write-Host '    fileReadLineLimit = 2000' -ForegroundColor Gray
Write-Host '    allowedDirectories = []  (full access)' -ForegroundColor Gray

# Step 4: Restart Claude if requested
Write-Host "`n[4/4] Finalizing..." -ForegroundColor Yellow
if (-not $SkipRestart) {
    $claudeProcess = Get-Process -Name 'Claude' -ErrorAction SilentlyContinue
    if ($claudeProcess) {
        Write-Host '  Claude Desktop is running. Restart required for changes to take effect.' -ForegroundColor Yellow
        $restart = Read-Host '  Restart now? (y/N)'
        if ($restart -eq 'y') {
            Write-Host '  Stopping Claude...' -ForegroundColor Gray
            $claudeProcess | Stop-Process -Force
            Start-Sleep -Seconds 2
            $claudeExe = (Get-Process -Name 'Claude' -ErrorAction SilentlyContinue).Path
            if (-not $claudeExe) {
                $claudeExe = Get-ChildItem "$env:LOCALAPPDATA\Programs\Claude\Claude.exe" -ErrorAction SilentlyContinue |
                    Select-Object -First 1 -ExpandProperty FullName
            }
            if ($claudeExe) {
                Start-Process $claudeExe
                Write-Host '  Claude restarted' -ForegroundColor Green
            }
            else {
                Write-Host '  Please restart Claude manually' -ForegroundColor Yellow
            }
        }
    }
    else {
        Write-Host '  Claude is not running. Start it to load new configuration.' -ForegroundColor Yellow
    }
}

# Step 5: Deploy Cursor MCP configuration (when -IncludeCursor)
if ($IncludeCursor) {
    Write-Host "`n[5/5] Deploying Cursor MCP configuration..." -ForegroundColor Yellow
    $cursorMcpPath = Join-Path $env:USERPROFILE '.cursor\mcp.json'
    $cursorConfigSource = Join-Path $ConfigSource 'cursor_mcp.json'
    if (-not (Test-Path $cursorConfigSource)) {
        Write-Warning "  Cursor config not found: $cursorConfigSource"
    }
    else {
        $cursorDir = Split-Path $cursorMcpPath -Parent
        if (-not (Test-Path $cursorDir)) {
            New-Item -Path $cursorDir -ItemType Directory -Force | Out-Null
            Write-Host "  Created $cursorDir" -ForegroundColor Green
        }
        $cursorConfig = Get-Content $cursorConfigSource -Raw | ConvertFrom-Json
        # Substitute %USERPROFILE% / <USER_HOME> in filesystem-mcp allowed directories
        $fsArgs = $cursorConfig.mcpServers.'filesystem-mcp'.args
        $newFsArgs = @()
        foreach ($arg in $fsArgs) {
            $newFsArgs += $arg -replace '<USER_HOME>', $env:USERPROFILE
        }
        $cursorConfig.mcpServers.'filesystem-mcp'.args = $newFsArgs
        if ($GitHubPAT) {
            $cursorConfig.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = $GitHubPAT
            Write-Host '  GitHub PAT injected for Cursor' -ForegroundColor Green
        }
        if ($NotionToken) {
            $cursorConfig.mcpServers.'notion-mcp'.env.NOTION_TOKEN = $NotionToken
            Write-Host '  Notion token injected for Cursor' -ForegroundColor Green
        }
        $cursorServerNames = @('windows-mcp', 'filesystem-mcp', 'desktopcommander-mcp', 'github', 'notion-mcp')
        if (Test-Path $cursorMcpPath) {
            $existing = Get-Content $cursorMcpPath -Raw | ConvertFrom-Json
            if (-not $existing.mcpServers) {
                $existing | Add-Member -MemberType NoteProperty -Name mcpServers -Value (New-Object PSObject) -Force
            }
            foreach ($name in $cursorServerNames) {
                $existing.mcpServers | Add-Member -MemberType NoteProperty -Name $name -Value $cursorConfig.mcpServers.$name -Force
            }
            $cursorConfig = $existing
            Write-Host '  Merged with existing Cursor mcp.json' -ForegroundColor Green
        }
        else {
            Write-Host '  Creating new Cursor mcp.json' -ForegroundColor Green
        }
        if ($PSCmdlet.ShouldProcess($cursorMcpPath, 'Write Cursor MCP configuration')) {
            $cursorConfig | ConvertTo-Json -Depth 10 | Set-Content $cursorMcpPath -Encoding UTF8
            Write-Host "  Cursor mcp.json deployed to $cursorMcpPath" -ForegroundColor Green
        }
        Write-Host '  Restart Cursor for MCP changes to take effect.' -ForegroundColor Gray
    }
}

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Cyan
$nextSteps = @"
NEXT STEPS:
  1. Replace API key placeholders in claude_desktop_config.json:
     - GITHUB_PERSONAL_ACCESS_TOKEN (https://github.com/settings/tokens)
     - BRAVE_API_KEY (https://api.search.brave.com/app/keys)
     - SOCKET_API_KEY (https://socket.dev/dashboard)
  2. Build any custom MCP servers that aren't compiled:
     cd <server-dir> && npm install && npm run build
  3. Restart Claude Desktop App
  4. Verify in Claude: ask 'list my MCP tools'
"@
if ($IncludeCursor) {
    $nextSteps += @"

CURSOR (with -IncludeCursor):
  - Cursor config: $env:USERPROFILE\.cursor\mcp.json
  - Set GITHUB_PERSONAL_ACCESS_TOKEN and NOTION_TOKEN in cursor_mcp.json or pass -GitHubPAT / -NotionToken to this script
  - Prerequisites: Node/npx; for windows-mcp: Python 3.12+ and uv (pip install uv)
  - Restart Cursor after deployment
"@
}
Write-Host $nextSteps -ForegroundColor White
