<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Deployment Automation
    Module 8: Automated Deployment and Distribution

.DESCRIPTION
    Enterprise deployment automation for WinPE images including:
    - Network deployment (PXE, WDS integration)
    - Media creation (USB, ISO, VHD)
    - Multi-site distribution
    - Deployment monitoring
    - Automated workflows
    - Rollback capabilities

.NOTES
    Author: Con's Development Team
    Module: 08-Deployment-Automation
    Version: 2.0.0
    Dependencies: DISM, oscdimg, diskpart, WDS (optional)
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Module Variables

$script:ModuleConfig = @{
    Name = 'Deploy-WinPEImage'
    Version = '2.0.0'
    LogPath = Join-Path $env:TEMP 'WinPE-Deployment'
    DeploymentPath = 'C:\WinPE-Deployments'
    MaxConcurrentDeployments = 5
}

$script:MediaTypes = @{
    USB = @{
        FileSystem = 'FAT32'
        PartitionStyle = 'MBR'
        MaxSize = 32GB
    }
    ISO = @{
        Standard = 'ISO9660'
        BootMode = 'UEFI+BIOS'
    }
    VHD = @{
        Type = 'Fixed'
        MaxSize = 127GB
    }
}

#endregion

#region Private Functions

function Initialize-DeploymentEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DeploymentId
    )
    
    try {
        Write-Verbose "Initializing deployment environment: $DeploymentId"
        
        $deployPath = Join-Path $script:ModuleConfig.DeploymentPath $DeploymentId
        $null = New-Item -Path $deployPath -ItemType Directory -Force
        
        $logFile = Join-Path $deployPath "deployment-log.txt"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logFile -Value "=== Deployment Started: $timestamp ==="
        
        return @{
            DeploymentId = $DeploymentId
            DeploymentPath = $deployPath
            LogFile = $logFile
            StartTime = Get-Date
            Status = 'Running'
        }
    }
    catch {
        Write-Error "Failed to initialize deployment environment: $_"
        throw
    }
}

function Write-DeploymentLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$DeploymentContext,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $DeploymentContext.LogFile -Value $logEntry
    
    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error' { Write-Error $Message }
        'Success' { Write-Host $Message -ForegroundColor Green }
        default { Write-Verbose $Message }
    }
}

function New-BootableUSB {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [string]$DriveLetter,
        
        [Parameter(Mandatory)]
        [hashtable]$DeploymentContext,
        
        [switch]$Force
    )
    
    Write-DeploymentLog $DeploymentContext "Creating bootable USB on drive $DriveLetter"
    
    try {
        # Verify drive exists
        $drive = Get-Volume -DriveLetter $DriveLetter -ErrorAction Stop
        
        if (-not $Force) {
            Write-Warning "This will erase all data on drive $DriveLetter. Continue? (Y/N)"
            $response = Read-Host
            if ($response -ne 'Y') {
                throw "Operation cancelled by user"
            }
        }
        
        Write-DeploymentLog $DeploymentContext "Preparing USB drive $DriveLetter"
        
        # Create diskpart script
        $diskpartScript = @"
select volume $DriveLetter
clean
create partition primary
select partition 1
active
format fs=fat32 quick label="WinPE"
assign letter=$DriveLetter
exit
"@
        
        $scriptPath = Join-Path $DeploymentContext.DeploymentPath 'diskpart-usb.txt'
        $diskpartScript | Out-File -FilePath $scriptPath -Encoding ASCII
        
        # Run diskpart
        Write-DeploymentLog $DeploymentContext "Formatting USB drive"
        $diskpartOutput = & diskpart.exe /s $scriptPath 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "Diskpart failed: $diskpartOutput"
        }
        
        # Wait for drive to be ready
        Start-Sleep -Seconds 3
        
        # Extract WIM contents to USB
        Write-DeploymentLog $DeploymentContext "Extracting WinPE image to USB"
        
        $mountPath = Join-Path $DeploymentContext.DeploymentPath 'USBMount'
        $null = New-Item -Path $mountPath -ItemType Directory -Force
        
        & DISM.exe /Mount-Wim /WimFile:$ImagePath /Index:1 /MountDir:$mountPath /ReadOnly | Out-Null
        
        try {
            # Copy files to USB
            $usbPath = "$DriveLetter`:\"
            Write-DeploymentLog $DeploymentContext "Copying files to USB drive"
            
            Copy-Item -Path "$mountPath\*" -Destination $usbPath -Recurse -Force
            
            # Make bootable
            Write-DeploymentLog $DeploymentContext "Making USB bootable"
            
            $bootsectPath = Join-Path $mountPath 'Windows\Boot\DVD\bootsect.exe'
            if (Test-Path $bootsectPath) {
                & $bootsectPath /nt60 "$DriveLetter`:" /mbr /force
            }
            
            Write-DeploymentLog $DeploymentContext "Bootable USB created successfully" -Level Success
        }
        finally {
            & DISM.exe /Unmount-Wim /MountDir:$mountPath /Discard | Out-Null
            Remove-Item -Path $mountPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        return @{
            Success = $true
            DriveLetter = $DriveLetter
            Size = $drive.Size
            Label = 'WinPE'
        }
    }
    catch {
        Write-DeploymentLog $DeploymentContext "Failed to create bootable USB: $_" -Level Error
        throw
    }
}

function New-BootableISO {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [Parameter(Mandatory)]
        [hashtable]$DeploymentContext,
        
        [string]$VolumeLabel = 'WinPE'
    )
    
    Write-DeploymentLog $DeploymentContext "Creating bootable ISO: $OutputPath"
    
    try {
        # Create temporary extraction directory
        $extractPath = Join-Path $DeploymentContext.DeploymentPath 'ISOContents'
        $null = New-Item -Path $extractPath -ItemType Directory -Force
        
        # Mount and extract WIM
        Write-DeploymentLog $DeploymentContext "Extracting WinPE image"
        
        $mountPath = Join-Path $DeploymentContext.DeploymentPath 'ISOMo unt'
        $null = New-Item -Path $mountPath -ItemType Directory -Force
        
        & DISM.exe /Mount-Wim /WimFile:$ImagePath /Index:1 /MountDir:$mountPath /ReadOnly | Out-Null
        
        try {
            # Copy all files to extraction directory
            Copy-Item -Path "$mountPath\*" -Destination $extractPath -Recurse -Force
            
            # Locate oscdimg.exe (from Windows ADK)
            $adkPaths = @(
                "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg",
                "${env:ProgramFiles}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
            )
            
            $oscdimgPath = $null
            foreach ($path in $adkPaths) {
                $testPath = Join-Path $path 'oscdimg.exe'
                if (Test-Path $testPath) {
                    $oscdimgPath = $testPath
                    break
                }
            }
            
            if (-not $oscdimgPath) {
                throw "oscdimg.exe not found. Windows ADK required for ISO creation."
            }
            
            Write-DeploymentLog $DeploymentContext "Building ISO with oscdimg"
            
            # Get boot sector files
            $etfsbootPath = Join-Path $extractPath 'boot\etfsboot.com'
            $efisysPath = Join-Path $extractPath 'efi\microsoft\boot\efisys.bin'
            
            # Build ISO with dual boot support (BIOS + UEFI)
            $oscdimgArgs = @(
                '-m',
                '-o',
                '-u2',
                '-udfver102',
                "-bootdata:2#p0,e,b`"$etfsbootPath`"#pEF,e,b`"$efisysPath`"",
                "-l$VolumeLabel",
                "`"$extractPath`"",
                "`"$OutputPath`""
            )
            
            $oscdimgOutput = & $oscdimgPath @oscdimgArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "oscdimg failed: $oscdimgOutput"
            }
            
            # Verify ISO was created
            if (Test-Path $OutputPath) {
                $isoSize = (Get-Item $OutputPath).Length
                Write-DeploymentLog $DeploymentContext "ISO created successfully: $([math]::Round($isoSize / 1MB, 2)) MB" -Level Success
                
                return @{
                    Success = $true
                    Path = $OutputPath
                    Size = $isoSize
                    Label = $VolumeLabel
                }
            }
            else {
                throw "ISO file was not created"
            }
        }
        finally {
            & DISM.exe /Unmount-Wim /MountDir:$mountPath /Discard | Out-Null
            Remove-Item -Path $mountPath -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-DeploymentLog $DeploymentContext "Failed to create bootable ISO: $_" -Level Error
        throw
    }
}

function New-BootableVHD {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [Parameter(Mandatory)]
        [hashtable]$DeploymentContext,
        
        [ValidateSet('Fixed', 'Dynamic')]
        [string]$VHDType = 'Fixed',
        
        [ValidateRange(512MB, 127GB)]
        [long]$SizeBytes = 4GB
    )
    
    Write-DeploymentLog $DeploymentContext "Creating bootable VHD: $OutputPath"
    
    try {
        # Create VHD
        Write-DeploymentLog $DeploymentContext "Creating VHD file ($VHDType, $([math]::Round($SizeBytes / 1GB, 2)) GB)"
        
        $vhdParams = @{
            Path = $OutputPath
            SizeBytes = $SizeBytes
        }
        
        if ($VHDType -eq 'Fixed') {
            $vhdParams.Fixed = $true
        }
        else {
            $vhdParams.Dynamic = $true
        }
        
        $vhd = New-VHD @vhdParams
        
        # Mount VHD
        Write-DeploymentLog $DeploymentContext "Mounting VHD"
        $mountedVHD = Mount-VHD -Path $OutputPath -Passthru
        
        try {
            # Initialize disk
            $disk = Get-Disk -Number $mountedVHD.Number
            Initialize-Disk -Number $disk.Number -PartitionStyle MBR
            
            # Create partition
            $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -IsActive
            $volume = Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "WinPE" -Confirm:$false
            
            # Assign drive letter
            $driveLetter = (Get-Partition -DiskNumber $disk.Number).DriveLetter
            
            Write-DeploymentLog $DeploymentContext "VHD mounted as drive $driveLetter`:"
            
            # Apply WIM to VHD
            Write-DeploymentLog $DeploymentContext "Applying WinPE image to VHD"
            
            $applyPath = "$driveLetter`:\"
            & DISM.exe /Apply-Image /ImageFile:$ImagePath /Index:1 /ApplyDir:$applyPath | Out-Null
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to apply image to VHD"
            }
            
            # Make bootable
            Write-DeploymentLog $DeploymentContext "Configuring VHD boot"
            
            $bcdbootPath = Join-Path $applyPath 'Windows\System32\bcdboot.exe'
            if (Test-Path $bcdbootPath) {
                & $bcdbootPath "$applyPath\Windows" /s "$driveLetter`:" /f ALL
            }
            
            Write-DeploymentLog $DeploymentContext "Bootable VHD created successfully" -Level Success
            
            return @{
                Success = $true
                Path = $OutputPath
                Size = $vhd.Size
                Type = $VHDType
                DiskNumber = $disk.Number
            }
        }
        finally {
            # Dismount VHD
            Dismount-VHD -Path $OutputPath
            Write-DeploymentLog $DeploymentContext "VHD dismounted"
        }
    }
    catch {
        Write-DeploymentLog $DeploymentContext "Failed to create bootable VHD: $_" -Level Error
        
        # Clean up failed VHD
        if (Test-Path $OutputPath) {
            try {
                Dismount-VHD -Path $OutputPath -ErrorAction SilentlyContinue
                Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
            }
            catch {}
        }
        
        throw
    }
}

function Deploy-ToWDS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [string]$ImageName,
        
        [Parameter(Mandatory)]
        [hashtable]$DeploymentContext,
        
        [string]$WDSServer = 'localhost',
        
        [string]$ImageGroup = 'WinPE Images'
    )
    
    Write-DeploymentLog $DeploymentContext "Deploying to Windows Deployment Services"
    
    try {
        # Check if WDS is installed
        $wdsFeature = Get-WindowsFeature -Name WDS -ErrorAction SilentlyContinue
        
        if (-not $wdsFeature -or $wdsFeature.InstallState -ne 'Installed') {
            throw "Windows Deployment Services is not installed on this server"
        }
        
        # Import WDS module
        Import-Module WDS -ErrorAction Stop
        
        Write-DeploymentLog $DeploymentContext "Connecting to WDS server: $WDSServer"
        
        # Check if image group exists
        $existingGroup = Get-WdsInstallImageGroup -Name $ImageGroup -ErrorAction SilentlyContinue
        
        if (-not $existingGroup) {
            Write-DeploymentLog $DeploymentContext "Creating image group: $ImageGroup"
            New-WdsInstallImageGroup -Name $ImageGroup
        }
        
        # Import image to WDS
        Write-DeploymentLog $DeploymentContext "Importing image: $ImageName"
        
        $importParams = @{
            Path = $ImagePath
            ImageGroup = $ImageGroup
            ImageName = $ImageName
        }
        
        $wdsImage = Import-WdsInstallImage @importParams
        
        # Enable image
        Enable-WdsInstallImage -ImageName $ImageName -ImageGroup $ImageGroup
        
        Write-DeploymentLog $DeploymentContext "Image deployed to WDS successfully" -Level Success
        
        return @{
            Success = $true
            Server = $WDSServer
            ImageGroup = $ImageGroup
            ImageName = $ImageName
            ImageGuid = $wdsImage.ImageGuid
        }
    }
    catch {
        Write-DeploymentLog $DeploymentContext "Failed to deploy to WDS: $_" -Level Error
        throw
    }
}

#endregion

#region Public Functions

function Deploy-WinPEImage {
    <#
    .SYNOPSIS
        Deploys a WinPE image to various media types.
    
    .DESCRIPTION
        Automates deployment of WinPE images to USB drives, ISO files, VHD files,
        or Windows Deployment Services.
    
    .PARAMETER ImagePath
        Path to the WinPE WIM file to deploy.
    
    .PARAMETER DeploymentType
        Type of deployment: USB, ISO, VHD, or WDS.
    
    .PARAMETER OutputPath
        Output path or drive letter for deployment.
    
    .PARAMETER VolumeLabel
        Volume label for the deployed media.
    
    .PARAMETER Force
        Forces deployment without confirmation.
    
    .EXAMPLE
        Deploy-WinPEImage -ImagePath "C:\WinPE\boot.wim" -DeploymentType ISO -OutputPath "C:\Deploy\winpe.iso"
        
    .EXAMPLE
        Deploy-WinPEImage -ImagePath "C:\WinPE\boot.wim" -DeploymentType USB -OutputPath "F" -Force
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [ValidateSet('USB', 'ISO', 'VHD', 'WDS')]
        [string]$DeploymentType,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [string]$VolumeLabel = 'WinPE',
        
        [string]$ImageName,
        
        [switch]$Force
    )
    
    begin {
        Write-Verbose "Starting WinPE deployment"
        
        if (-not (Test-Path $script:ModuleConfig.DeploymentPath)) {
            $null = New-Item -Path $script:ModuleConfig.DeploymentPath -ItemType Directory -Force
        }
    }
    
    process {
        try {
            # Initialize deployment
            $deploymentId = "Deploy_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            $deploymentContext = Initialize-DeploymentEnvironment -DeploymentId $deploymentId
            
            Write-DeploymentLog $deploymentContext "=== WinPE Deployment ===" -Level Info
            Write-DeploymentLog $deploymentContext "Type: $DeploymentType"
            Write-DeploymentLog $deploymentContext "Image: $ImagePath"
            Write-DeploymentLog $deploymentContext "Output: $OutputPath"
            
            $result = $null
            
            switch ($DeploymentType) {
                'USB' {
                    Write-Host "Deploying to USB drive $OutputPath..." -ForegroundColor Cyan
                    $result = New-BootableUSB -ImagePath $ImagePath -DriveLetter $OutputPath -DeploymentContext $deploymentContext -Force:$Force
                }
                
                'ISO' {
                    Write-Host "Creating bootable ISO..." -ForegroundColor Cyan
                    $result = New-BootableISO -ImagePath $ImagePath -OutputPath $OutputPath -DeploymentContext $deploymentContext -VolumeLabel $VolumeLabel
                }
                
                'VHD' {
                    Write-Host "Creating bootable VHD..." -ForegroundColor Cyan
                    $result = New-BootableVHD -ImagePath $ImagePath -OutputPath $OutputPath -DeploymentContext $deploymentContext
                }
                
                'WDS' {
                    if (-not $ImageName) {
                        $ImageName = [System.IO.Path]::GetFileNameWithoutExtension($ImagePath)
                    }
                    Write-Host "Deploying to Windows Deployment Services..." -ForegroundColor Cyan
                    $result = Deploy-ToWDS -ImagePath $ImagePath -ImageName $ImageName -DeploymentContext $deploymentContext
                }
            }
            
            $deploymentContext.Status = 'Completed'
            $deploymentContext.EndTime = Get-Date
            $deploymentContext.Duration = ($deploymentContext.EndTime - $deploymentContext.StartTime).TotalSeconds
            $deploymentContext.Result = $result
            
            # Display summary
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Yellow
            Write-Host "Type: $DeploymentType"
            Write-Host "Status: $($deploymentContext.Status)" -ForegroundColor Green
            Write-Host "Duration: $([math]::Round($deploymentContext.Duration, 2)) seconds"
            Write-Host "Deployment ID: $deploymentId"
            
            if ($result) {
                foreach ($key in $result.Keys) {
                    if ($key -ne 'Success') {
                        Write-Host "$key`: $($result[$key])"
                    }
                }
            }
            
            Write-Host "`nLog file: $($deploymentContext.LogFile)" -ForegroundColor Cyan
            
            return $deploymentContext
        }
        catch {
            Write-Error "Deployment failed: $_"
            throw
        }
    }
}

function Start-WinPEMultiSiteDeployment {
    <#
    .SYNOPSIS
        Deploys WinPE images to multiple sites or servers.
    
    .DESCRIPTION
        Orchestrates deployment of WinPE images across multiple target locations
        with parallel execution and monitoring.
    
    .PARAMETER ImagePath
        Path to the WinPE WIM file to deploy.
    
    .PARAMETER DeploymentTargets
        Array of deployment target configurations.
    
    .PARAMETER MaxParallel
        Maximum number of parallel deployments.
    
    .EXAMPLE
        $targets = @(
            @{ Type = 'WDS'; Server = 'WDS01'; ImageName = 'WinPE-Site1' },
            @{ Type = 'ISO'; OutputPath = '\\FileServer\Deploy\winpe.iso' }
        )
        Start-WinPEMultiSiteDeployment -ImagePath "C:\WinPE\boot.wim" -DeploymentTargets $targets
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [array]$DeploymentTargets,
        
        [ValidateRange(1, 10)]
        [int]$MaxParallel = 3
    )
    
    process {
        try {
            Write-Host "Starting multi-site deployment" -ForegroundColor Cyan
            Write-Host "Targets: $($DeploymentTargets.Count)"
            Write-Host "Max parallel: $MaxParallel`n"
            
            $jobs = @()
            $results = @()
            
            foreach ($target in $DeploymentTargets) {
                # Wait if max parallel reached
                while ((Get-Job -State Running).Count -ge $MaxParallel) {
                    Start-Sleep -Seconds 2
                }
                
                # Start deployment job
                $job = Start-Job -ScriptBlock {
                    param($ImagePath, $Target)
                    
                    $params = @{
                        ImagePath = $ImagePath
                        DeploymentType = $Target.Type
                        OutputPath = $Target.OutputPath
                    }
                    
                    if ($Target.ImageName) {
                        $params.ImageName = $Target.ImageName
                    }
                    
                    if ($Target.Force) {
                        $params.Force = $true
                    }
                    
                    Deploy-WinPEImage @params
                } -ArgumentList $ImagePath, $target
                
                $jobs += $job
                Write-Host "Started deployment job: $($target.Type) - $($target.OutputPath ?? $target.Server)" -ForegroundColor Yellow
            }
            
            # Monitor jobs
            Write-Host "`nMonitoring deployments..." -ForegroundColor Cyan
            
            while ($jobs | Where-Object { $_.State -eq 'Running' }) {
                $running = ($jobs | Where-Object { $_.State -eq 'Running' }).Count
                $completed = ($jobs | Where-Object { $_.State -eq 'Completed' }).Count
                $failed = ($jobs | Where-Object { $_.State -eq 'Failed' }).Count
                
                Write-Host "`rRunning: $running | Completed: $completed | Failed: $failed" -NoNewline
                Start-Sleep -Seconds 2
            }
            
            Write-Host "`n`nAll deployments finished" -ForegroundColor Green
            
            # Collect results
            foreach ($job in $jobs) {
                $jobResult = Receive-Job -Job $job
                $results += @{
                    JobId = $job.Id
                    State = $job.State
                    Result = $jobResult
                }
                Remove-Job -Job $job
            }
            
            # Display summary
            Write-Host "`n=== Multi-Site Deployment Summary ===" -ForegroundColor Yellow
            Write-Host "Total: $($results.Count)"
            Write-Host "Successful: $(($results | Where-Object { $_.State -eq 'Completed' }).Count)" -ForegroundColor Green
            Write-Host "Failed: $(($results | Where-Object { $_.State -eq 'Failed' }).Count)" -ForegroundColor Red
            
            return $results
        }
        catch {
            Write-Error "Multi-site deployment failed: $_"
            throw
        }
    }
}

function Remove-WinPEDeployment {
    <#
    .SYNOPSIS
        Removes or rolls back a WinPE deployment.
    
    .DESCRIPTION
        Cleans up deployed WinPE images from various targets.
    
    .PARAMETER DeploymentType
        Type of deployment to remove: WDS, NetworkShare.
    
    .PARAMETER ImageName
        Name of the image to remove (for WDS).
    
    .PARAMETER Path
        Path to remove (for network shares).
    
    .EXAMPLE
        Remove-WinPEDeployment -DeploymentType WDS -ImageName "WinPE-Prod"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('WDS', 'NetworkShare')]
        [string]$DeploymentType,
        
        [string]$ImageName,
        
        [string]$Path,
        
        [string]$WDSServer = 'localhost',
        
        [string]$ImageGroup = 'WinPE Images'
    )
    
    process {
        try {
            Write-Host "Removing deployment..." -ForegroundColor Cyan
            
            switch ($DeploymentType) {
                'WDS' {
                    if (-not $ImageName) {
                        throw "ImageName is required for WDS removal"
                    }
                    
                    Import-Module WDS -ErrorAction Stop
                    
                    Write-Verbose "Removing WDS image: $ImageName"
                    Remove-WdsInstallImage -ImageName $ImageName -ImageGroup $ImageGroup -Confirm:$false
                    
                    Write-Host "WDS image removed successfully" -ForegroundColor Green
                }
                
                'NetworkShare' {
                    if (-not $Path) {
                        throw "Path is required for network share removal"
                    }
                    
                    if (Test-Path $Path) {
                        Write-Verbose "Removing file: $Path"
                        Remove-Item -Path $Path -Force
                        Write-Host "File removed successfully" -ForegroundColor Green
                    }
                    else {
                        Write-Warning "Path not found: $Path"
                    }
                }
            }
            
            return @{
                Success = $true
                Type = $DeploymentType
                RemovedAt = Get-Date
            }
        }
        catch {
            Write-Error "Failed to remove deployment: $_"
            throw
        }
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Deploy-WinPEImage',
    'Start-WinPEMultiSiteDeployment',
    'Remove-WinPEDeployment'
)
