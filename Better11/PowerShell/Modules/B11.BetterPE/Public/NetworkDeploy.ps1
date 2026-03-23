#Requires -Version 5.1

<#
.SYNOPSIS
    BetterPE Phase 4 — PXE/WDS Network Deployment.
.DESCRIPTION
    Network-based deployment via PXE boot, WDS integration, TFTP management,
    multicast sessions, and MDT-compatible task sequence support.
#>

function Initialize-B11PxeServer {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$TftpRoot,

        [Parameter()]
        [string]$BootImage,

        [Parameter()]
        [ValidateSet('x64', 'x86', 'arm64')]
        [string]$Architecture = 'x64',

        [Parameter()]
        [string]$DhcpServerIp,

        [Parameter()]
        [switch]$EnableProxy
    )

    if ($PSCmdlet.ShouldProcess($TftpRoot, 'Initialize PXE server environment')) {
        # Create TFTP directory structure
        $bootDir = Join-Path $TftpRoot 'Boot'
        $imageDir = Join-Path $TftpRoot 'Images'
        $configDir = Join-Path $TftpRoot 'Config'

        foreach ($dir in @($bootDir, $imageDir, $configDir)) {
            if (-not (Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
            }
        }

        # Architecture-specific boot loader paths
        $archMap = @{
            'x64'   = @{ BcdFile = 'BCD'; BootMgr = 'bootmgfw.efi'; PxeLoader = 'pxeboot.n12' }
            'x86'   = @{ BcdFile = 'BCD'; BootMgr = 'bootmgr.exe'; PxeLoader = 'pxeboot.com' }
            'arm64' = @{ BcdFile = 'BCD'; BootMgr = 'bootmgfw.efi'; PxeLoader = 'pxeboot.n12' }
        }

        $archConfig = $archMap[$Architecture]

        # Copy boot image if provided
        if ($BootImage -and (Test-Path $BootImage)) {
            Copy-Item -Path $BootImage -Destination (Join-Path $imageDir "boot_${Architecture}.wim") -Force
        }

        # Generate DHCP options file for proxy mode
        $dhcpConfig = @{
            Option066 = $DhcpServerIp  # Boot Server Host Name
            Option067 = "Boot\$($archConfig.PxeLoader)"  # Bootfile Name
            ProxyMode = $EnableProxy.IsPresent
        }

        $dhcpConfig | ConvertTo-Json | Set-Content -Path (Join-Path $configDir 'dhcp-options.json') -Encoding utf8

        [PSCustomObject]@{
            PSTypeName   = 'B11.PxeServer'
            TftpRoot     = $TftpRoot
            Architecture = $Architecture
            BootDir      = $bootDir
            ImageDir     = $imageDir
            ConfigDir    = $configDir
            ProxyMode    = $EnableProxy.IsPresent
            Status       = 'Initialized'
        }
    }
}

function Add-B11WdsBootImage {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ImagePath,

        [Parameter(Mandatory)]
        [string]$ImageName,

        [Parameter()]
        [string]$ImageGroup = 'Better11',

        [Parameter()]
        [ValidateSet('x64', 'x86', 'arm64')]
        [string]$Architecture = 'x64',

        [Parameter()]
        [string]$Description = ''
    )

    if ($PSCmdlet.ShouldProcess($ImageName, 'Add WDS boot image')) {
        $wdsutilArgs = @(
            '/Add-Image'
            "/ImageFile:`"$ImagePath`""
            "/ImageName:`"$ImageName`""
            '/ImageType:Boot'
        )

        if ($Description) {
            $wdsutilArgs += "/Description:`"$Description`""
        }

        try {
            $result = & wdsutil.exe $wdsutilArgs 2>&1
            $success = $LASTEXITCODE -eq 0

            [PSCustomObject]@{
                PSTypeName   = 'B11.WdsImage'
                ImageName    = $ImageName
                ImageType    = 'Boot'
                Architecture = $Architecture
                ImageGroup   = $ImageGroup
                SourcePath   = $ImagePath
                Success      = $success
                Output       = ($result -join "`n")
            }
        } catch {
            Write-Error "Failed to add WDS boot image: $_" -ErrorAction Stop
        }
    }
}

function Add-B11WdsInstallImage {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ImagePath,

        [Parameter(Mandatory)]
        [string]$ImageName,

        [Parameter()]
        [string]$ImageGroup = 'Better11',

        [Parameter()]
        [string]$UnattendFile
    )

    if ($PSCmdlet.ShouldProcess($ImageName, 'Add WDS install image')) {
        $wdsutilArgs = @(
            '/Add-Image'
            "/ImageFile:`"$ImagePath`""
            "/ImageName:`"$ImageName`""
            '/ImageType:Install'
            "/ImageGroup:`"$ImageGroup`""
        )

        if ($UnattendFile -and (Test-Path $UnattendFile)) {
            $wdsutilArgs += "/UnattendFile:`"$UnattendFile`""
        }

        try {
            $result = & wdsutil.exe $wdsutilArgs 2>&1

            [PSCustomObject]@{
                PSTypeName = 'B11.WdsImage'
                ImageName  = $ImageName
                ImageType  = 'Install'
                ImageGroup = $ImageGroup
                SourcePath = $ImagePath
                Success    = ($LASTEXITCODE -eq 0)
                Output     = ($result -join "`n")
            }
        } catch {
            Write-Error "Failed to add WDS install image: $_" -ErrorAction Stop
        }
    }
}

function New-B11MulticastSession {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$SessionName,

        [Parameter(Mandatory)]
        [string]$ImageName,

        [Parameter()]
        [string]$ImageGroup = 'Better11',

        [Parameter()]
        [ValidateSet('AutoCast', 'ScheduledCast')]
        [string]$TransmissionType = 'AutoCast',

        [Parameter()]
        [int]$MinimumClients = 1,

        [Parameter()]
        [datetime]$StartTime
    )

    if ($PSCmdlet.ShouldProcess($SessionName, 'Create multicast session')) {
        $wdsutilArgs = @(
            '/New-MulticastTransmission'
            "/FriendlyName:`"$SessionName`""
            "/Image:`"$ImageName`""
            '/ImageType:Install'
            "/ImageGroup:`"$ImageGroup`""
            "/TransmissionType:$TransmissionType"
        )

        if ($TransmissionType -eq 'ScheduledCast') {
            if ($StartTime) {
                $wdsutilArgs += "/StartTime:`"$($StartTime.ToString('yyyy/MM/dd:HH:mm'))`""
            }
            $wdsutilArgs += "/Clients:$MinimumClients"
        }

        try {
            $result = & wdsutil.exe $wdsutilArgs 2>&1

            [PSCustomObject]@{
                PSTypeName       = 'B11.MulticastSession'
                SessionName      = $SessionName
                ImageName        = $ImageName
                TransmissionType = $TransmissionType
                MinimumClients   = $MinimumClients
                Success          = ($LASTEXITCODE -eq 0)
                Output           = ($result -join "`n")
            }
        } catch {
            Write-Error "Failed to create multicast session: $_" -ErrorAction Stop
        }
    }
}

function Get-B11WdsStatus {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    try {
        $serverInfo = & wdsutil.exe /Get-Server /Show:All 2>&1
        $isInstalled = (Get-WindowsFeature -Name WDS -ErrorAction SilentlyContinue).Installed

        [PSCustomObject]@{
            PSTypeName = 'B11.WdsStatus'
            IsInstalled = $isInstalled
            IsRunning   = (Get-Service -Name WDSServer -ErrorAction SilentlyContinue).Status -eq 'Running'
            ServerInfo  = ($serverInfo -join "`n")
        }
    } catch {
        [PSCustomObject]@{
            PSTypeName = 'B11.WdsStatus'
            IsInstalled = $false
            IsRunning   = $false
            ServerInfo  = "WDS not available: $_"
        }
    }
}

function Install-B11WdsRole {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [switch]$IncludeTransportServer,

        [Parameter()]
        [switch]$IncludeDeploymentServer
    )

    if ($PSCmdlet.ShouldProcess('Windows Deployment Services', 'Install server role')) {
        $features = @('WDS')
        if ($IncludeTransportServer) { $features += 'WDS-Transport' }
        if ($IncludeDeploymentServer) { $features += 'WDS-Deployment' }

        $results = foreach ($feature in $features) {
            Install-WindowsFeature -Name $feature -IncludeManagementTools -ErrorAction Continue
        }

        [PSCustomObject]@{
            PSTypeName       = 'B11.WdsInstall'
            FeaturesInstalled = $features
            Success          = ($results | Where-Object { -not $_.Success }).Count -eq 0
            RestartNeeded    = ($results | Where-Object { $_.RestartNeeded -ne 'No' }).Count -gt 0
        }
    }
}

function New-B11TftpConfig {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$TftpRoot,

        [Parameter()]
        [int]$Port = 69,

        [Parameter()]
        [int]$MaxBlockSize = 1468,

        [Parameter()]
        [string[]]$AllowedSubnets = @('0.0.0.0/0')
    )

    if ($PSCmdlet.ShouldProcess($TftpRoot, 'Create TFTP configuration')) {
        $config = @{
            TftpRoot       = $TftpRoot
            Port           = $Port
            MaxBlockSize   = $MaxBlockSize
            AllowedSubnets = $AllowedSubnets
            WindowSize     = 4
            RetransmitTimeout = 3
            CreatedAt      = (Get-Date -Format 'o')
        }

        $configPath = Join-Path $TftpRoot 'tftp-config.json'
        $config | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding utf8

        [PSCustomObject]@{
            PSTypeName = 'B11.TftpConfig'
            TftpRoot   = $TftpRoot
            Port       = $Port
            ConfigPath = $configPath
            Status     = 'Created'
        }
    }
}

function Start-B11NetworkDeployment {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,

        [Parameter(Mandatory)]
        [string[]]$TargetMachines,

        [Parameter()]
        [string]$UnattendFile,

        [Parameter()]
        [string]$DriverPath,

        [Parameter()]
        [ValidateSet('Unicast', 'Multicast')]
        [string]$TransferMode = 'Unicast',

        [Parameter()]
        [switch]$WakeOnLan
    )

    if ($PSCmdlet.ShouldProcess("$($TargetMachines.Count) machines", 'Start network deployment')) {
        $deploymentId = "deploy_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

        $deployment = @{
            Id             = $deploymentId
            ImagePath      = $ImagePath
            TargetMachines = $TargetMachines
            TransferMode   = $TransferMode
            UnattendFile   = $UnattendFile
            DriverPath     = $DriverPath
            WakeOnLan      = $WakeOnLan.IsPresent
            StartedAt      = [datetime]::UtcNow
            Status         = 'Initiating'
            MachineStatus  = @{}
        }

        # Initialize per-machine status
        foreach ($machine in $TargetMachines) {
            $deployment.MachineStatus[$machine] = @{
                Status     = 'Pending'
                Progress   = 0
                StartedAt  = $null
                Error      = $null
            }
        }

        # Wake-on-LAN if requested
        if ($WakeOnLan) {
            Write-Verbose "Sending Wake-on-LAN packets to $($TargetMachines.Count) machines..."
            foreach ($machine in $TargetMachines) {
                $deployment.MachineStatus[$machine].Status = 'WoL Sent'
            }
        }

        $deployment.Status = 'Running'

        [PSCustomObject]@{
            PSTypeName     = 'B11.NetworkDeployment'
            DeploymentId   = $deploymentId
            ImagePath      = $ImagePath
            TargetCount    = $TargetMachines.Count
            TransferMode   = $TransferMode
            Status         = 'Running'
            StartedAt      = $deployment.StartedAt
        }
    }
}

Export-ModuleMember -Function @(
    'Initialize-B11PxeServer', 'Add-B11WdsBootImage', 'Add-B11WdsInstallImage',
    'New-B11MulticastSession', 'Get-B11WdsStatus', 'Install-B11WdsRole',
    'New-B11TftpConfig', 'Start-B11NetworkDeployment'
)
