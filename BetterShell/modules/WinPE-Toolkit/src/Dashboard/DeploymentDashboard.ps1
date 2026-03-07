# Deployment Dashboard - HTML reporting dashboard

[CmdletBinding()]
param(
    [Parameter()]
    [string] $RunId,

    [Parameter()]
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force

function New-DeploymentDashboard {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter()]
        [string] $OutputPath
    )

    $root = Get-DeployRoot
    $logsRoot = Join-Path $root 'logs'

    if (-not $OutputPath) {
        $OutputPath = Join-Path $logsRoot "$RunId\dashboard.html"
    }

    $runDir = Join-Path $logsRoot $RunId
    if (-not (Test-Path $runDir)) {
        throw "Run directory not found: $runDir"
    }

    $eventsPath = Join-Path $runDir 'events.jsonl'
    if (-not (Test-Path $eventsPath)) {
        throw "Events file not found: $eventsPath"
    }

    # Load events
    $events = Get-Content -Path $eventsPath | ForEach-Object {
        $_ | ConvertFrom-Json
    }

    # Generate dashboard HTML
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deployment Dashboard - $RunId</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
            color: #333;
            line-height: 1.6;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header h1 { font-size: 2rem; margin-bottom: 0.5rem; }
        .header p { opacity: 0.9; }
        .container {
            max-width: 1200px;
            margin: 2rem auto;
            padding: 0 1rem;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }
        .stat-card {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            font-size: 0.9rem;
            color: #666;
            margin-bottom: 0.5rem;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .stat-card .value {
            font-size: 2rem;
            font-weight: bold;
            color: #667eea;
        }
        .events-table {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th {
            background: #667eea;
            color: white;
            padding: 1rem;
            text-align: left;
            font-weight: 600;
        }
        td {
            padding: 0.75rem 1rem;
            border-bottom: 1px solid #eee;
        }
        tr:hover { background: #f9f9f9; }
        .level-Info { color: #2196F3; }
        .level-Warning { color: #FF9800; }
        .level-Error { color: #F44336; }
        .level-Critical { color: #D32F2F; font-weight: bold; }
        .level-Debug { color: #9E9E9E; }
        .footer {
            text-align: center;
            padding: 2rem;
            color: #666;
            margin-top: 2rem;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Deployment Dashboard</h1>
        <p>Run ID: $RunId | Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="container">
        <div class="stats">
            <div class="stat-card">
                <h3>Total Events</h3>
                <div class="value">$($events.Count)</div>
            </div>
            <div class="stat-card">
                <h3>Info</h3>
                <div class="value">$(($events | Where-Object { $_.level -eq 'Info' }).Count)</div>
            </div>
            <div class="stat-card">
                <h3>Warnings</h3>
                <div class="value">$(($events | Where-Object { $_.level -eq 'Warning' }).Count)</div>
            </div>
            <div class="stat-card">
                <h3>Errors</h3>
                <div class="value">$(($events | Where-Object { $_.level -eq 'Error' }).Count)</div>
            </div>
        </div>
        <div class="events-table">
            <table>
                <thead>
                    <tr>
                        <th>Timestamp</th>
                        <th>Level</th>
                        <th>Message</th>
                        <th>Details</th>
                    </tr>
                </thead>
                <tbody>
"@

    foreach ($event in $events) {
        $dataJson = if ($event.data) { ($event.data | ConvertTo-Json -Compress) } else { '' }
        $html += @"
                    <tr>
                        <td>$($event.timestamp)</td>
                        <td class="level-$($event.level)">$($event.level)</td>
                        <td>$($event.message)</td>
                        <td><pre style="font-size: 0.8rem; max-width: 300px; overflow: auto;">$dataJson</pre></td>
                    </tr>
"@
    }

    $html += @"
                </tbody>
            </table>
        </div>
    </div>
    <div class="footer">
        <p>Better11 Deployment Toolkit - Dashboard v1.0</p>
    </div>
</body>
</html>
"@

    $html | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Dashboard generated: $OutputPath" -ForegroundColor Green
    return $OutputPath
}

if ($RunId) {
    New-DeploymentDashboard -RunId $RunId -OutputPath $OutputPath
}
else {
    Write-Host "Usage: .\DeploymentDashboard.ps1 -RunId <run-id>" -ForegroundColor Yellow
}

