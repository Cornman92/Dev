Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop

function Get-DeployDisk {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int] $DiskNumber
    )

    $disks = Get-Disk | Where-Object { $_.PartitionStyle -ne 'RAW' -or $_.Size -gt 0 }

    if ($PSBoundParameters.ContainsKey('DiskNumber')) {
        $disk = $disks | Where-Object Number -eq $DiskNumber
        if (-not $disk) {
            throw "Disk number $DiskNumber not found."
        }
        return $disk
    }

    return $disks
}

function Get-DeployDiskLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int] $DiskNumber
    )

    $disk = Get-DeployDisk -DiskNumber $DiskNumber
    $parts = Get-Partition -DiskNumber $DiskNumber | Sort-Object -Property Offset
    $vols  = Get-Volume | Where-Object { $_.ObjectId -like "*Disk#$DiskNumber*" -or $_.UniqueId -like "*Disk#$DiskNumber*" }

    $layout = [pscustomobject]@{
        DiskNumber   = $disk.Number
        SizeBytes    = $disk.Size
        PartitionStyle = $disk.PartitionStyle
        Layout       = @()
    }

    foreach ($p in $parts) {
        $vol = $vols | Where-Object { $_.DriveLetter -eq $p.DriveLetter } | Select-Object -First 1

        $layout.Layout += [pscustomobject]@{
            PartitionNumber = $p.PartitionNumber
            DriveLetter     = $p.DriveLetter
            SizeBytes       = $p.Size
            GptType         = if ($disk.PartitionStyle -eq 'GPT') { $p.GptType } else { $null }
            MbrType         = if ($disk.PartitionStyle -eq 'MBR') { $p.MbrType } else { $null }
            Type            = if ($vol) { $vol.FileSystemLabel } else { $null }
            IsBoot          = $p.IsBoot
            IsSystem        = $p.IsSystem
        }
    }

    return $layout
}

function New-DeployDiskLayout {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [int] $DiskNumber,

        [Parameter(Mandatory)]
        [ValidateSet('GPT','MBR')]
        [string] $PartitionStyle,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [object[]] $LayoutDefinition,

        [Parameter()]
        [switch] $Force
    )

    $disk = Get-DeployDisk -DiskNumber $DiskNumber
    $desc = "Repartition disk $DiskNumber ($($disk.Size/1GB -as [int]) GB) with style $PartitionStyle and layout definition."

    if (-not (Confirm-DestructiveAction -RunContext $RunContext -ActionDescription $desc -Force:$Force)) {
        throw "Disk layout operation cancelled."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Starting disk layout on disk $DiskNumber."

    if ($PSCmdlet.ShouldProcess("Disk $DiskNumber", "Clear disk and create partitions")) {
        # Clear and initialize disk
        $RunContext | Write-DeployEvent -Level 'Debug' -Message "Clearing and initializing disk $DiskNumber."

        Get-Disk -Number $DiskNumber | Set-Disk -IsReadOnly $false -ErrorAction Stop
        Get-Disk -Number $DiskNumber | Clear-Disk -RemoveData -Confirm:$false -ErrorAction Stop
        Initialize-Disk -Number $DiskNumber -PartitionStyle $PartitionStyle -ErrorAction Stop

        foreach ($entry in $LayoutDefinition) {
            $sizeBytes = if ($entry.SizeGB -gt 0) {
                [math]::Round($entry.SizeGB * 1GB)
            } else {
                0
            }

            $isBoot = [bool]$entry.IsBoot
            $isSystem = [bool]$entry.IsSystem
            $driveLetter = $entry.DriveLetter

            if ($sizeBytes -eq 0) {
                $RunContext | Write-DeployEvent -Level 'Debug' -Message "Creating partition to fill remaining space on disk $DiskNumber."
                $part = New-Partition -DiskNumber $DiskNumber -UseMaximumSize -AssignDriveLetter:$([bool]$driveLetter) -ErrorAction Stop
            }
            else {
                $RunContext | Write-DeployEvent -Level 'Debug' -Message "Creating partition of $($entry.SizeGB) GB on disk $DiskNumber."
                $part = New-Partition -DiskNumber $DiskNumber -Size $sizeBytes -AssignDriveLetter:$([bool]$driveLetter) -ErrorAction Stop
            }

            if ($driveLetter) {
                $part | Set-Partition -NewDriveLetter $driveLetter -ErrorAction Stop
            }

            if ($entry.FileSystem -and $entry.FileSystem -ne '') {
                $label = if ($entry.Label) { $entry.Label } else { '' }
                $RunContext | Write-DeployEvent -Level 'Debug' -Message "Formatting partition $($part.PartitionNumber) as $($entry.FileSystem) with label '$label'."
                Format-Volume -Partition $part -FileSystem $entry.FileSystem -NewFileSystemLabel $label -Confirm:$false -ErrorAction Stop | Out-Null
            }

            if ($PartitionStyle -eq 'GPT' -and $entry.GptType) {
                $part | Set-Partition -GptType $entry.GptType -ErrorAction Stop
            }

            if ($isBoot -or $isSystem) {
                $RunContext | Write-DeployEvent -Level 'Debug' -Message "Marking partition $($part.PartitionNumber) as boot/system (IsBoot=$isBoot, IsSystem=$isSystem)."
                $part | Set-Partition -IsBoot:$isBoot -IsSystem:$isSystem -ErrorAction SilentlyContinue
            }
        }
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Disk layout complete on disk $DiskNumber."
}

function Invoke-ImageApply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $WimPath,

        [Parameter(Mandatory)]
        [ValidateRange(1, 99)]
        [int] $Index,

        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Z]:\\$')]
        [string] $TargetVolumeRoot
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Applying image from '$WimPath' (Index $Index) to '$TargetVolumeRoot'."

    try {
        if (-not (Test-Path $WimPath)) {
            $error = New-Object System.IO.FileNotFoundException "WIM file not found: $WimPath"
            $RunContext | Write-DeployError -Exception $error -Context 'Invoke-ImageApply' -AdditionalData @{
                wimPath = $WimPath
                index = $Index
                targetVolume = $TargetVolumeRoot
            }
            throw $error
        }

    $args = "/Apply-Image /ImageFile:`"$WimPath`" /Index:$Index /ApplyDir:$TargetVolumeRoot /CheckIntegrity"

    $RunContext | Write-DeployEvent -Level 'Debug' -Message "Running DISM with arguments: $args"

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = 'dism.exe'
    $pinfo.Arguments = $args
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError  = $true
    $pinfo.UseShellExecute        = $false
    $pinfo.CreateNoWindow         = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $pinfo

    if (-not $proc.Start()) {
        throw "Failed to start DISM.exe."
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    Add-Content -Path $RunContext.RunLogPath -Value $stdout
    if ($stderr) {
        Add-Content -Path $RunContext.RunLogPath -Value $stderr
    }

        if ($proc.ExitCode -ne 0) {
            $error = New-Object System.Management.Automation.RuntimeException "DISM image apply failed. Exit code: $($proc.ExitCode)."
            $RunContext | Write-DeployError -Exception $error -Context 'Invoke-ImageApply' -AdditionalData @{
                wimPath = $WimPath
                index = $Index
                targetVolume = $TargetVolumeRoot
                dismExitCode = $proc.ExitCode
                dismOutput = $stdout
                dismError = $stderr
            }
            throw $error
        }

        $RunContext | Write-DeployEvent -Level 'Info' -Message "Image apply completed successfully."
    }
    catch {
        $RunContext | Write-DeployError -Exception $_ -Context 'Invoke-ImageApply' -AdditionalData @{
            wimPath = $WimPath
            index = $Index
            targetVolume = $TargetVolumeRoot
        }
        throw
    }
}

function New-BootConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Z]:\\$')]
        [string] $WindowsVolumeRoot,

        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Z]:$')]
        [string] $SystemPartition
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Configuring bootloader. Windows='$WindowsVolumeRoot', SystemPartition='$SystemPartition'."

    $sysPath = $SystemPartition.TrimEnd('\')
    $args = "`"$WindowsVolumeRoot`Windows`" /s $sysPath /f ALL"

    $RunContext | Write-DeployEvent -Level 'Debug' -Message "Running bcdboot.exe with arguments: $args"

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = 'bcdboot.exe'
    $pinfo.Arguments = $args
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError  = $true
    $pinfo.UseShellExecute        = $false
    $pinfo.CreateNoWindow         = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $pinfo

    if (-not $proc.Start()) {
        throw "Failed to start bcdboot.exe."
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    Add-Content -Path $RunContext.RunLogPath -Value $stdout
    if ($stderr) {
        Add-Content -Path $RunContext.RunLogPath -Value $stderr
    }

    if ($proc.ExitCode -ne 0) {
        $RunContext | Write-DeployEvent -Level 'Error' -Message "bcdboot failed with exit code $($proc.ExitCode)."
        throw "Boot configuration failed. Exit code: $($proc.ExitCode)."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Boot configuration completed successfully."
}

