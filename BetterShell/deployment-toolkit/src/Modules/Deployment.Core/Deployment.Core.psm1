Set-StrictMode -Version Latest

# Module-level cache for performance
$script:DeployRootCache = $null
$script:HardwareProfileCache = $null
$script:DriverCatalogCache = $null
$script:AppCatalogCache = $null

function Get-DeployRoot {
    [CmdletBinding()]
    param()

    # Use cache if available
    if ($script:DeployRootCache) {
        return $script:DeployRootCache
    }

    # Default: assume repo root is three levels above this module file
    # Structure: root/src/Modules/ModuleName/ModuleName.psm1
    $modulePath = Split-Path -Parent $PSCommandPath
    $modulesRoot = Split-Path -Parent $modulePath
    $srcRoot = Split-Path -Parent $modulesRoot
    $root = Split-Path -Parent $srcRoot

    if (-not (Test-Path $root)) {
        throw "Deployment root path '$root' does not exist."
    }

    $resolved = (Resolve-Path $root).ProviderPath
    $script:DeployRootCache = $resolved
    return $resolved
}

function Get-DeployConfigPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $RelativePath
    )

    $root = Get-DeployRoot
    $full = Join-Path $root $RelativePath

    if (-not (Test-Path $full)) {
        throw "Configuration path '$full' does not exist."
    }

    return (Resolve-Path $full).ProviderPath
}

function Resolve-DeployPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    # Support environment variable substitution: %VAR% or ${VAR}
    $resolved = $Path

    # Replace %VAR% patterns
    $resolved = [regex]::Replace($resolved, '%([^%]+)%', {
        param($match)
        $varName = $match.Groups[1].Value
        $envValue = [Environment]::GetEnvironmentVariable($varName)
        if ($envValue) {
            return $envValue
        }
        return $match.Value
    })

    # Replace ${VAR} patterns
    $resolved = [regex]::Replace($resolved, '\$\{([^}]+)\}', {
        param($match)
        $varName = $match.Groups[1].Value
        $envValue = [Environment]::GetEnvironmentVariable($varName)
        if ($envValue) {
            return $envValue
        }
        return $match.Value
    })

    # If path starts with .\, resolve relative to deploy root
    if ($resolved -like '.\*' -or $resolved -like '.\*') {
        $root = Get-DeployRoot
        $resolved = Join-Path $root $resolved.TrimStart('.\')
    }

    return $resolved
}

function New-DeployRunContext {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $RunId
    )

    $root = Get-DeployRoot

    if (-not $RunId) {
        $RunId = [guid]::NewGuid().ToString()
    }

    $logsRoot = Join-Path $root 'logs'
    if (-not (Test-Path $logsRoot)) {
        New-Item -ItemType Directory -Path $logsRoot | Out-Null
    }

    $runDir = Join-Path $logsRoot $RunId
    if (-not (Test-Path $runDir)) {
        New-Item -ItemType Directory -Path $runDir | Out-Null
    }

    $ctx = [pscustomobject]@{
        RunId       = $RunId
        RootPath    = $root
        LogsRoot    = $logsRoot
        RunLogPath  = (Join-Path $runDir 'deployment.log')
        EventsPath  = (Join-Path $runDir 'events.jsonl')
        CreatedAt   = (Get-Date).ToUniversalTime()
        MachineName = $env:COMPUTERNAME
        IsWinPE     = (Test-Path 'X:\Windows\System32\winpe.jpg') -or
                      ($env:SystemDrive -eq 'X:')
    }

    Write-DeployEvent -RunContext $ctx -Level 'Info' -Message 'Created deployment run context.'

    return $ctx
}

function Write-DeployLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $line = "[{0}] {1}" -f $timestamp, $Message
    Add-Content -Path $RunContext.RunLogPath -Value $line -ErrorAction SilentlyContinue
}

function Write-DeployEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidateSet('Debug','Info','Warning','Error','Critical')]
        [string] $Level,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [Parameter()]
        [hashtable] $Data,

        [Parameter()]
        [string] $CorrelationId
    )

    process {
        if (-not $CorrelationId) {
            $CorrelationId = [guid]::NewGuid().ToString()
        }

        $evt = [ordered]@{
            timestamp     = (Get-Date).ToUniversalTime().ToString('o')
            runId         = $RunContext.RunId
            correlationId = $CorrelationId
            level         = $Level
            message       = $Message
            machine       = $RunContext.MachineName
            isWinPE       = $RunContext.IsWinPE
            data          = $Data
        }

        $json = $evt | ConvertTo-Json -Depth 6 -Compress
        Add-Content -Path $RunContext.EventsPath -Value $json -ErrorAction SilentlyContinue
        Write-Verbose "[$Level] $Message"
    }
}

function Write-DeployError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [Exception] $Exception,

        [Parameter()]
        [string] $Context = '',

        [Parameter()]
        [hashtable] $AdditionalData
    )

    process {
        $errorData = @{
            exceptionType = $Exception.GetType().FullName
            exceptionMessage = $Exception.Message
            exceptionCategory = $Exception.CategoryInfo.Category
            exceptionDetails = $Exception.ToString()
            context = $Context
        }

        if ($AdditionalData) {
            foreach ($key in $AdditionalData.Keys) {
                $errorData[$key] = $AdditionalData[$key]
            }
        }

        $RunContext | Write-DeployEvent -Level 'Error' -Message "Error in $Context : $($Exception.Message)" -Data $errorData
    }
}

function Export-DeployLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject] $RunContext,

        [Parameter()]
        [ValidateSet('CSV','HTML','JSON')]
        [string] $Format = 'CSV',

        [Parameter()]
        [string] $OutputPath
    )

    process {
        if (-not $OutputPath) {
            $runDir = Split-Path -Parent $RunContext.RunLogPath
            $OutputPath = Join-Path $runDir "events.$($Format.ToLower())"
        }

        if (-not (Test-Path $RunContext.EventsPath)) {
            throw "Events file not found: $($RunContext.EventsPath)"
        }

        $events = Get-Content -Path $RunContext.EventsPath | ForEach-Object {
            $_ | ConvertFrom-Json
        }

        switch ($Format) {
            'CSV' {
                $events | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
            'HTML' {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Deployment Events - $($RunContext.RunId)</title>
    <style>
        body { font-family: Consolas, monospace; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .Error { color: red; }
        .Warning { color: orange; }
        .Info { color: blue; }
    </style>
</head>
<body>
    <h1>Deployment Events - $($RunContext.RunId)</h1>
    <p>Machine: $($RunContext.MachineName) | Created: $($RunContext.CreatedAt)</p>
    <table>
        <tr>
            <th>Timestamp</th>
            <th>Level</th>
            <th>Message</th>
            <th>Data</th>
        </tr>
"@
                foreach ($evt in $events) {
                    $dataJson = if ($evt.data) { ($evt.data | ConvertTo-Json -Compress) } else { '' }
                    $html += "        <tr class=`"$($evt.level)`"><td>$($evt.timestamp)</td><td>$($evt.level)</td><td>$($evt.message)</td><td>$dataJson</td></tr>`r`n"
                }
                $html += "    </table></body></html>"
                Set-Content -Path $OutputPath -Value $html -Encoding UTF8
            }
            'JSON' {
                $events | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
            }
        }

        return $OutputPath
    }
}

function Rotate-DeployLogs {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int] $RetentionDays = 30,

        [Parameter()]
        [int] $MaxLogSizeMB = 100
    )

    $root = Get-DeployRoot
    $logsRoot = Join-Path $root 'logs'

    if (-not (Test-Path $logsRoot)) {
        return
    }

    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $logDirs = Get-ChildItem -Path $logsRoot -Directory

    foreach ($dir in $logDirs) {
        $dirDate = $dir.CreationTime

        if ($dirDate -lt $cutoffDate) {
            Write-Verbose "Removing old log directory: $($dir.Name) (created: $dirDate)"
            Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            continue
        }

        # Check log file sizes
        $logFile = Join-Path $dir.FullName 'deployment.log'
        if (Test-Path $logFile) {
            $fileSizeMB = (Get-Item $logFile).Length / 1MB
            if ($fileSizeMB -gt $MaxLogSizeMB) {
                Write-Verbose "Log file exceeds size limit: $($dir.Name) ($([math]::Round($fileSizeMB, 2)) MB)"
                # Archive or truncate - for now, just log a warning
            }
        }
    }
}

function Get-DeployConfigJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath
    )

    $path = Get-DeployConfigPath -RelativePath $RelativePath
    $raw  = Get-Content -Path $path -Raw -ErrorAction Stop
    $json = $null

    try {
        $json = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Failed to parse JSON configuration file '$path': $($_.Exception.Message)"
    }

    return $json
}

function Test-DeployAdmin {
    [CmdletBinding()]
    param()

    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Confirm-DestructiveAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $ActionDescription,

        [Parameter()]
        [switch] $Force
    )

    if ($Force) {
        $RunContext | Write-DeployEvent -Level 'Warning' -Message "Destructive action auto-confirmed (force): $ActionDescription"
        return $true
    }

    Write-Host ''
    Write-Host '*** WARNING: Destructive operation ***' -ForegroundColor Red
    Write-Host $ActionDescription -ForegroundColor Yellow
    Write-Host ''

    $answer = Read-Host 'Type YES to proceed'

    if ($answer -eq 'YES') {
        $RunContext | Write-DeployEvent -Level 'Warning' -Message "Destructive action confirmed: $ActionDescription"
        return $true
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Destructive action cancelled by user: $ActionDescription"
    return $false
}

function Invoke-DeployRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock] $ScriptBlock,

        [Parameter()]
        [int] $MaxAttempts = 3,

        [Parameter()]
        [int] $DelaySeconds = 2,

        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter()]
        [string] $OperationName = 'operation',

        [Parameter()]
        [switch] $ExponentialBackoff
    )

    if ($MaxAttempts -lt 1) {
        throw "MaxAttempts must be at least 1."
    }

    $attempt = 0
    $lastError = $null

    while ($true) {
        $attempt++

        try {
            $RunContext | Write-DeployEvent -Level 'Debug' -Message "Attempt $attempt for $OperationName."
            $result = & $ScriptBlock
            if ($attempt -gt 1) {
                $RunContext | Write-DeployEvent -Level 'Info' -Message "Operation '$OperationName' succeeded on attempt $attempt."
            }
            return $result
        }
        catch {
            $lastError = $_
            $delay = if ($ExponentialBackoff) {
                [math]::Min($DelaySeconds * [math]::Pow(2, $attempt - 1), 60)
            }
            else {
                $DelaySeconds
            }

            $msg = "Attempt $attempt for $OperationName failed: $($_.Exception.Message)"
            $RunContext | Write-DeployEvent -Level 'Warning' -Message $msg -Data @{
                attempt = $attempt
                maxAttempts = $MaxAttempts
                nextRetryInSeconds = $delay
                errorType = $_.Exception.GetType().FullName
                errorCategory = $_.CategoryInfo.Category
            }

            if ($attempt -ge $MaxAttempts) {
                $finalMsg = "Operation '$OperationName' failed after $MaxAttempts attempts. Last error: $($_.Exception.Message)"
                $RunContext | Write-DeployEvent -Level 'Error' -Message $finalMsg -Data @{
                    totalAttempts = $attempt
                    lastErrorType = $_.Exception.GetType().FullName
                    lastErrorCategory = $_.CategoryInfo.Category
                    lastErrorDetails = $_.Exception.ToString()
                }
                throw $lastError
            }

            Start-Sleep -Seconds $delay
        }
    }
}

function Write-ProgressDeploy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Activity,

        [Parameter(Mandatory)]
        [string] $Status,

        [Parameter()]
        [int] $PercentComplete = -1,

        [Parameter()]
        [int] $CurrentOperation = 0,

        [Parameter()]
        [int] $TotalOperations = 0
    )

    if ($PercentComplete -ge 0) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }
    elseif ($TotalOperations -gt 0) {
        $percent = [math]::Round(($CurrentOperation / $TotalOperations) * 100)
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $percent -CurrentOperation $CurrentOperation -TotalOperations $TotalOperations
    }
    else {
        Write-Progress -Activity $Activity -Status $Status
    }
}
