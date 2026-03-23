Set-StrictMode -Version Latest

Import-Module Deployment.Core         -ErrorAction Stop
Import-Module Deployment.Imaging      -ErrorAction Stop
Import-Module Deployment.Drivers      -ErrorAction Stop
Import-Module Deployment.Packages     -ErrorAction Stop
Import-Module Deployment.Optimization -ErrorAction Stop
Import-Module Deployment.Health       -ErrorAction Stop

function Get-TaskSequenceCatalog {
    [CmdletBinding()]
    param()

    $root = Get-DeployConfigPath -RelativePath 'configs\task_sequences'
    $files = Get-ChildItem -Path $root -Filter '*.json' -File -ErrorAction Stop

    $all = @()

    foreach ($file in $files) {
        $raw = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        $data = $raw | ConvertFrom-Json -ErrorAction Stop

        if ($data -is [System.Collections.IEnumerable]) {
            $all += $data
        }
        else {
            $all += $data
        }
    }

    return $all
}

function Get-TaskSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Id
    )

    # Simple implementation: look into configs\task_sequences and aggregate all *.json
    $root = Get-DeployConfigPath -RelativePath 'configs\task_sequences'
    $files = Get-ChildItem -Path $root -Filter '*.json' -File -ErrorAction Stop

    $all = @()

    foreach ($file in $files) {
        $raw = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        $data = $raw | ConvertFrom-Json -ErrorAction Stop

        if ($data -is [System.Collections.IEnumerable]) {
            $all += $data
        }
        else {
            $all += $data
        }
    }

    $ts = $all | Where-Object { $_.id -eq $Id }

    if (-not $ts) {
        throw "Task sequence with id '$Id' not found in configs\task_sequences."
    }

    return $ts
}

function Invoke-TaskSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [pscustomobject] $TaskSequence,

        [Parameter()]
        [hashtable] $Variables
    )

    if (-not $Variables) {
        $Variables = @{}
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Starting task sequence '$($TaskSequence.name)' (id=$($TaskSequence.id))."

    $stepIndex = 0
    $totalSteps = $TaskSequence.steps.Count

    foreach ($step in $TaskSequence.steps) {
        $stepIndex++
        $stepName = $step.name
        $stepType = $step.type

        # Show progress
        Write-ProgressDeploy -Activity "Task Sequence: $($TaskSequence.name)" `
            -Status "Step $stepIndex of $totalSteps : $stepName" `
            -CurrentOperation $stepIndex `
            -TotalOperations $totalSteps

        $RunContext | Write-DeployEvent -Level 'Info' -Message "Running step $stepIndex : $stepName (type=$stepType)." -Data @{ stepId = $step.id; type = $step.type }

        try {
            Invoke-TaskStep -RunContext $RunContext -Step $step -Variables $Variables
        }
        catch {
            $RunContext | Write-DeployError -Exception $_ -Context "Invoke-TaskSequence.Step$stepIndex" -AdditionalData @{
                stepId = $step.id
                stepName = $step.name
                stepType = $step.type
                stepIndex = $stepIndex
                totalSteps = $TaskSequence.steps.Count
            }
            throw
        }
    }

    Write-Progress -Activity "Task Sequence: $($TaskSequence.name)" -Completed

    Write-Progress -Activity "Task Sequence: $($TaskSequence.name)" -Completed

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Task sequence '$($TaskSequence.name)' completed successfully."
}

function Invoke-TaskStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [pscustomobject] $Step,

        [Parameter(Mandatory)]
        [hashtable] $Variables
    )

    $type = $Step.type
    $inputs = $Step.inputs

    switch ($type) {
        'PartitionDisk' {
            $diskNumber = if ($Variables.ContainsKey('DiskNumber')) {
                [int]$Variables['DiskNumber']
            }
            else {
                [int]$inputs.diskNumber
            }

            $partitionStyle  = $inputs.partitionStyle
            $layoutDef       = @()

            foreach ($item in $inputs.layout) {
                $layoutDef += [pscustomobject]@{
                    SizeGB      = [double]$item.sizeGB
                    FileSystem  = $item.fileSystem
                    Label       = $item.label
                    DriveLetter = $item.driveLetter
                    IsBoot      = [bool]$item.isBoot
                    IsSystem    = [bool]$item.isSystem
                    GptType     = $item.gptType
                }
            }

            New-DeployDiskLayout -RunContext $RunContext -DiskNumber $diskNumber -PartitionStyle $partitionStyle -LayoutDefinition $layoutDef -Force:$inputs.force
        }

        'ApplyImage' {
            $wimPath   = $inputs.wimPath
            # Resolve WIM path with environment variable substitution
            $wimPath   = Resolve-DeployPath -Path $wimPath
            
            # If resolution didn't change the path and it contains %VAR%, try fallback
            if ($wimPath -like '*%*' -and $inputs._wimPathFallback) {
                $wimPath = Resolve-DeployPath -Path $inputs._wimPathFallback
            }
            
            $index     = [int]$inputs.index
            $drive     = $inputs.targetDriveLetter

            if ($drive.Length -eq 1) { $drive = "${drive}:\" }
            if (-not $drive.EndsWith('\')) { $drive += '\' }

            Invoke-ImageApply -RunContext $RunContext -WimPath $wimPath -Index $index -TargetVolumeRoot $drive

            $Variables['WindowsVolumeRoot'] = $drive
        }

        'ConfigureBoot' {
            $sysDrive = $inputs.systemPartitionDriveLetter
            if ($sysDrive.Length -eq 1) { $sysDrive = "${sysDrive}:" }

            $winRoot = $Variables['WindowsVolumeRoot']

            if (-not $winRoot) {
                throw "WindowsVolumeRoot variable not set. Ensure an ApplyImage step runs before ConfigureBoot."
            }

            New-BootConfig -RunContext $RunContext -WindowsVolumeRoot $winRoot -SystemPartition $sysDrive
        }

        'DetectHardware' {
            $hw = Get-HardwareProfile
            $Variables['HardwareProfile'] = $hw

            $RunContext | Write-DeployEvent -Level 'Info' -Message "Hardware profile captured." -Data @{
                Manufacturer = $hw.Manufacturer
                Model        = $hw.Model
                MemoryGB     = $hw.TotalMemoryGB
                CPU          = $hw.CPUName
            }
        }

        'InjectDrivers' {
            $hw = $Variables['HardwareProfile']

            if (-not $hw) {
                $hw = Get-HardwareProfile
                $Variables['HardwareProfile'] = $hw
            }

            $catalog = Get-DriverCatalog
            $matches = Find-DriverPacksForHardware -HardwareProfile $hw -DriverCatalog $catalog

            if (-not $matches -or $matches.Count -eq 0) {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "No matching driver packs found; skipping driver injection."
                return
            }

            $limit = if ($inputs.maxPacks -gt 0) { [int]$inputs.maxPacks } else { 3 }
            $selected = $matches | Select-Object -First $limit | ForEach-Object { $_.DriverPack }

            $mode = $inputs.mode

            if ($mode -eq 'offline-os') {
                $winRoot = $Variables['WindowsVolumeRoot']

                if (-not $winRoot) {
                    throw "WindowsVolumeRoot variable not set for offline driver injection."
                }

                Add-DriversToOfflineWindows -RunContext $RunContext -WindowsVolumeRoot $winRoot -DriverPacks $selected
            }
            elseif ($mode -eq 'mounted-image') {
                $mountPath = $inputs.mountPath

                if (-not $mountPath) {
                    throw "InjectDrivers step with mode 'mounted-image' requires 'mountPath'."
                }

                Add-DriversToMountedImage -RunContext $RunContext -MountPath $mountPath -DriverPacks $selected
            }
            else {
                throw "InjectDrivers step mode '$mode' is not supported. Use 'offline-os' or 'mounted-image'."
            }
        }

        'InstallAppSet' {
            $setId = $inputs.appSetId

            if (-not $setId) {
                throw "InstallAppSet step requires 'appSetId'."
            }

            Install-AppSet -RunContext $RunContext -SetId $setId
        }

        'HealthSnapshot' {
            $name = $inputs.name

            if (-not $name) {
                $name = $Step.id
            }

            $path = New-HealthSnapshot -RunContext $RunContext -Name $name

            if (-not $Variables.ContainsKey('HealthSnapshots')) {
                $Variables['HealthSnapshots'] = @{}
            }

            $Variables['HealthSnapshots'][$name] = $path
        }

        'ApplyOptimizationProfile' {
            $profileId = $inputs.profileId

            if (-not $profileId) {
                throw "ApplyOptimizationProfile step requires 'profileId'."
            }

            Invoke-OptimizationProfile -RunContext $RunContext -Id $profileId
        }

        'ApplyDebloatProfile' {
            $profileId = $inputs.profileId

            if (-not $profileId) {
                throw "ApplyDebloatProfile step requires 'profileId'."
            }

            Invoke-DebloatProfile -RunContext $RunContext -Id $profileId
        }

        'ApplyPersonalizationProfile' {
            $profileId = $inputs.profileId

            if (-not $profileId) {
                throw "ApplyPersonalizationProfile step requires 'profileId'."
            }

            Set-PersonalizationProfile -RunContext $RunContext -Id $profileId
        }

        'RunProcess' {
            $exe = $inputs.executable

            if (-not $exe) {
                throw "RunProcess step requires 'executable'."
            }

            # Resolve executable path with environment variable substitution
            $exe = Resolve-DeployPath -Path $exe

            # If resolution didn't change the path and it contains %VAR%, try fallback
            if ($exe -like '*%*' -and $inputs._executableFallback) {
                $exe = Resolve-DeployPath -Path $inputs._executableFallback
            }

            $args = if ($inputs.arguments) { $inputs.arguments } else { '' }

            $RunContext | Write-DeployEvent -Level 'Info' -Message "Running process: $exe $args"

            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = $exe
            $pinfo.Arguments = $args
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError  = $true
            $pinfo.UseShellExecute        = $false
            $pinfo.CreateNoWindow         = $true

            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $pinfo

            if (-not $proc.Start()) {
                throw "Failed to start process '$exe'."
            }

            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            Add-Content -Path $RunContext.RunLogPath -Value $stdout
            if ($stderr) {
                Add-Content -Path $RunContext.RunLogPath -Value $stderr
            }

            if ($proc.ExitCode -ne 0) {
                $RunContext | Write-DeployEvent -Level 'Error' -Message "Process '$exe' exited with code $($proc.ExitCode)."
                throw "Process execution failed. Exit code: $($proc.ExitCode)."
            }

            $RunContext | Write-DeployEvent -Level 'Info' -Message "Process '$exe' completed successfully."
        }

        'Reboot' {
            $RunContext | Write-DeployEvent -Level 'Info' -Message "Reboot step requested."
            Write-Host "Rebooting in 5 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            Restart-Computer -Force
        }

        default {
            throw "Unsupported task step type '$type'."
        }
    }
}

