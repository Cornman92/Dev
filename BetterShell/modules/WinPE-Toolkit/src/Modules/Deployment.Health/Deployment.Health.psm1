Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop

function New-HealthSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $Name
    )

    $rootRunDir = Split-Path -Parent $RunContext.RunLogPath
    $snapDir    = Join-Path $rootRunDir 'snapshots'

    if (-not (Test-Path $snapDir)) {
        New-Item -ItemType Directory -Path $snapDir | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $safeName  = ($Name -replace '[^A-Za-z0-9_-]','_')
    $fileName  = "$timestamp-$safeName.json"
    $path      = Join-Path $snapDir $fileName

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Creating health snapshot '$Name' at '$path'."

    $snapshot = [ordered]@{}

    try {
        $os  = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs  = Get-CimInstance -ClassName Win32_ComputerSystem
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1

        $snapshot.metadata = [ordered]@{
            createdAtUtc = (Get-Date).ToUniversalTime().ToString('o')
            runId        = $RunContext.RunId
            machine      = $RunContext.MachineName
            user         = $env:USERNAME
            isWinPE      = $RunContext.IsWinPE
        }

        $snapshot.system = [ordered]@{
            osCaption     = $os.Caption
            osVersion     = $os.Version
            osBuild       = $os.BuildNumber
            osInstallDate = $os.InstallDate
            architecture  = $env:PROCESSOR_ARCHITECTURE
            computerName  = $cs.Name
            manufacturer  = $cs.Manufacturer
            model         = $cs.Model
            totalMemoryGB = [math]::Round([double]$cs.TotalPhysicalMemory / 1GB, 2)
            cpuName       = $cpu.Name
            cpuCores      = $cpu.NumberOfCores
            cpuLogical    = $cpu.NumberOfLogicalProcessors
        }

        # Disks and volumes (best-effort in WinPE and full OS)
        $disks = @()
        try {
            $disks = Get-Disk | Select-Object Number, FriendlyName, Size, PartitionStyle, OperationalStatus
        } catch { }

        $parts = @()
        try {
            $parts = Get-Partition | Select-Object DiskNumber, PartitionNumber, DriveLetter, Size, GptType, MbrType, IsBoot, IsSystem
        } catch { }

        $vols = @()
        try {
            $vols = Get-Volume | Select-Object DriveLetter, FileSystem, Size, SizeRemaining, FileSystemLabel, HealthStatus
        } catch { }

        $snapshot.storage = [ordered]@{
            disks      = $disks
            partitions = $parts
            volumes    = $vols
        }

        # Key services (trimmed to avoid huge payload)
        $services = @()
        try {
            $services = Get-Service | Select-Object Name, DisplayName, Status, StartType
        } catch { }

        $snapshot.services = $services

        # Installed hotfixes (patches)
        $hotfixes = @()
        try {
            $hotfixes = Get-HotFix | Select-Object HotFixID, Description, InstalledOn
        } catch { }

        $snapshot.hotfixes = $hotfixes

        # Installed apps: read the uninstall keys, but only capture name/version/publisher
        $apps = @()
        try {
            $keys = @(
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
            )

            foreach ($k in $keys) {
                if (-not (Test-Path $k)) { continue }

                Get-ChildItem -Path $k | ForEach-Object {
                    try {
                        $p = Get-ItemProperty -Path $_.PSPath -ErrorAction Stop
                        if ($p.DisplayName) {
                            $apps += [pscustomobject]@{
                                Name      = $p.DisplayName
                                Version   = $p.DisplayVersion
                                Publisher = $p.Publisher
                                InstallDate = $p.InstallDate
                            }
                        }
                    } catch { }
                }
            }
        } catch { }

        $snapshot.apps = $apps | Sort-Object Name -Unique

        $json = $snapshot | ConvertTo-Json -Depth 6
        Set-Content -Path $path -Value $json -Encoding UTF8

        $RunContext | Write-DeployEvent -Level 'Info' -Message "Health snapshot '$Name' created."
    }
    catch {
        $RunContext | Write-DeployEvent -Level 'Error' -Message "Failed to create health snapshot '$Name': $($_.Exception.Message)"
        throw
    }

    return $path
}

function Compare-HealthSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $BaselinePath,

        [Parameter(Mandatory)]
        [string] $CurrentPath
    )

    if (-not (Test-Path $BaselinePath)) {
        throw "Baseline snapshot '$BaselinePath' not found."
    }

    if (-not (Test-Path $CurrentPath)) {
        throw "Current snapshot '$CurrentPath' not found."
    }

    $baseRaw = Get-Content -Path $BaselinePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $currRaw = Get-Content -Path $CurrentPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

    # Compare only app and service deltas for now (most useful)
    $baseApps = @{}
    foreach ($a in $baseRaw.apps) {
        $baseApps[$a.Name] = $a
    }

    $currApps = @{}
    foreach ($a in $currRaw.apps) {
        $currApps[$a.Name] = $a
    }

    $addedApps   = @()
    $removedApps = @()
    $changedApps = @()

    foreach ($name in $currApps.Keys) {
        if (-not $baseApps.ContainsKey($name)) {
            $addedApps += $currApps[$name]
        } else {
            $b = $baseApps[$name]
            $c = $currApps[$name]

            if ($b.Version -ne $c.Version) {
                $changedApps += [pscustomobject]@{
                    Name        = $name
                    OldVersion  = $b.Version
                    NewVersion  = $c.Version
                    OldPublisher= $b.Publisher
                    NewPublisher= $c.Publisher
                }
            }
        }
    }

    foreach ($name in $baseApps.Keys) {
        if (-not $currApps.ContainsKey($name)) {
            $removedApps += $baseApps[$name]
        }
    }

    $baseSvc = @{}
    foreach ($s in $baseRaw.services) { $baseSvc[$s.Name] = $s }

    $currSvc = @{}
    foreach ($s in $currRaw.services) { $currSvc[$s.Name] = $s }

    $serviceChanges = @()

    foreach ($name in $currSvc.Keys) {
        $c = $currSvc[$name]
        $b = $baseSvc[$name]

        if ($b) {
            if ($b.Status -ne $c.Status -or $b.StartType -ne $c.StartType) {
                $serviceChanges += [pscustomobject]@{
                    Name          = $name
                    OldStatus     = $b.Status
                    NewStatus     = $c.Status
                    OldStartType  = $b.StartType
                    NewStartType  = $c.StartType
                }
            }
        }
    }

    return [pscustomobject]@{
        BaselinePath   = $BaselinePath
        CurrentPath    = $CurrentPath
        AddedApps      = $addedApps
        RemovedApps    = $removedApps
        ChangedApps    = $changedApps
        ServiceChanges = $serviceChanges
    }
}

function New-SystemRestorePointSafe {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Description = 'Better11 deployment snapshot'
    )

    # Only works in full OS, not WinPE
    if ($env:SystemDrive -eq 'X:' -or (Test-Path 'X:\Windows\System32\winpe.jpg')) {
        return $null
    }

    try {
        $restoreClass = Get-CimClass -ClassName SystemRestore -Namespace root\default -ErrorAction Stop
    }
    catch {
        return $null
    }

    try {
        $result = Invoke-CimMethod -ClassName SystemRestore -Namespace root\default -MethodName CreateRestorePoint -Arguments @{
            Description = $Description
            RestorePointType = 0  # APPLICATION_INSTALL
            EventType        = 100
        }

        return $result
    }
    catch {
        return $null
    }
}

function Export-DeployDiagnostics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext
    )

    $runDir = Split-Path -Parent $RunContext.RunLogPath
    $zipPath = Join-Path $runDir 'diagnostics.zip'

    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force
    }

    Compress-Archive -Path (Join-Path $runDir '*') -DestinationPath $zipPath -Force

    return $zipPath
}

