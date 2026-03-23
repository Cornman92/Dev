Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop

function Test-DeploymentPrerequisites {
    [CmdletBinding()]
    param(
        [Parameter()]
        [pscustomobject] $RunContext
    )

    $results = @{
        Passed = $true
        Checks = @()
    }

    # Check admin rights
    $isAdmin = Test-DeployAdmin
    $results.Checks += [pscustomobject]@{
        Name = 'Administrator Rights'
        Status = if ($isAdmin) { 'Pass' } else { 'Fail' }
        Message = if ($isAdmin) { 'Running with administrator privileges' } else { 'Must run as Administrator' }
    }
    if (-not $isAdmin) { $results.Passed = $false }

    # Check disk space (at least 20 GB free on system drive)
    $systemDrive = $env:SystemDrive
    $drive = Get-PSDrive -Name $systemDrive.TrimEnd(':')
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $minFreeGB = 20
    
    $results.Checks += [pscustomobject]@{
        Name = 'Disk Space'
        Status = if ($freeGB -ge $minFreeGB) { 'Pass' } else { 'Warning' }
        Message = "$freeGB GB free on $systemDrive (minimum: $minFreeGB GB)"
    }
    if ($freeGB -lt $minFreeGB) {
        $results.Passed = $false
    }

    # Check PowerShell version (5.1+)
    $psVersion = $PSVersionTable.PSVersion
    $minVersion = [Version]'5.1'
    
    $results.Checks += [pscustomobject]@{
        Name = 'PowerShell Version'
        Status = if ($psVersion -ge $minVersion) { 'Pass' } else { 'Fail' }
        Message = "PowerShell $psVersion (minimum: $minVersion)"
    }
    if ($psVersion -lt $minVersion) { $results.Passed = $false }

    # Check for required executables
    $requiredExes = @('dism.exe', 'bcdboot.exe')
    foreach ($exe in $requiredExes) {
        $exePath = Get-Command -Name $exe -ErrorAction SilentlyContinue
        $results.Checks += [pscustomobject]@{
            Name = "Required Tool: $exe"
            Status = if ($exePath) { 'Pass' } else { 'Fail' }
            Message = if ($exePath) { "Found at: $($exePath.Source)" } else { "Not found in PATH" }
        }
        if (-not $exePath) { $results.Passed = $false }
    }

    # Check network connectivity (optional)
    try {
        $ping = Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction Stop
        $results.Checks += [pscustomobject]@{
            Name = 'Network Connectivity'
            Status = if ($ping) { 'Pass' } else { 'Warning' }
            Message = if ($ping) { 'Network connectivity available' } else { 'No network connectivity (may be required for some operations)' }
        }
    }
    catch {
        $results.Checks += [pscustomobject]@{
            Name = 'Network Connectivity'
            Status = 'Warning'
            Message = 'Could not test network connectivity'
        }
    }

    if ($RunContext) {
        $RunContext | Write-DeployEvent -Level 'Info' -Message "Prerequisites check completed. Passed: $($results.Passed)" -Data @{ checks = $results.Checks }
    }

    return $results
}

function Test-WimFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $WimPath,

        [Parameter()]
        [int] $Index = 1,

        [Parameter()]
        [pscustomobject] $RunContext
    )

    $results = @{
        Passed = $false
        WimPath = $WimPath
        Index = $Index
        Errors = @()
        Warnings = @()
        ImageInfo = $null
    }

    if (-not (Test-Path $WimPath)) {
        $results.Errors += "WIM file not found: $WimPath"
        return $results
    }

    try {
        $imageInfo = Get-WindowsImage -ImagePath $WimPath -ErrorAction Stop
        
        if ($imageInfo.Count -eq 0) {
            $results.Errors += "WIM file contains no images"
            return $results
        }

        $targetImage = $imageInfo | Where-Object { $_.ImageIndex -eq $Index }
        if (-not $targetImage) {
            $results.Errors += "Image index $Index not found. Available indices: $($imageInfo.ImageIndex -join ', ')"
            return $results
        }

        $results.ImageInfo = $targetImage
        $results.Passed = $true

        if ($RunContext) {
            $RunContext | Write-DeployEvent -Level 'Info' -Message "WIM file validated: $WimPath (Index $Index)" -Data @{
                imageName = $targetImage.ImageName
                imageSize = $targetImage.ImageSize
            }
        }
    }
    catch {
        $results.Errors += "Failed to read WIM file: $($_.Exception.Message)"
    }

    return $results
}

function Test-DriverCatalog {
    [CmdletBinding()]
    param(
        [Parameter()]
        [pscustomobject] $RunContext
    )

    $results = @{
        Passed = $true
        CatalogPath = $null
        DriverPacks = @()
        Errors = @()
        Warnings = @()
    }

    try {
        Import-Module Deployment.Drivers -ErrorAction Stop
        $catalog = Get-DriverCatalog
        
        $results.CatalogPath = (Get-DeployConfigPath -RelativePath 'configs\drivers\catalog.json')
        $results.DriverPacks = $catalog

        foreach ($pack in $catalog) {
            $packErrors = @()
            
            foreach ($path in $pack.paths) {
                if (-not (Test-Path $path)) {
                    $packErrors += "Path not found: $path"
                }
            }

            if ($packErrors.Count -gt 0) {
                $results.Warnings += "Driver pack '$($pack.id)': $($packErrors -join '; ')"
            }
        }

        if ($RunContext) {
            $RunContext | Write-DeployEvent -Level 'Info' -Message "Driver catalog validated: $($catalog.Count) driver pack(s)" -Data @{
                packCount = $catalog.Count
                warnings = $results.Warnings.Count
            }
        }
    }
    catch {
        $results.Passed = $false
        $results.Errors += $_.Exception.Message
    }

    return $results
}

function Test-AppCatalog {
    [CmdletBinding()]
    param(
        [Parameter()]
        [pscustomobject] $RunContext
    )

    $results = @{
        Passed = $true
        CatalogPath = $null
        Apps = @()
        Errors = @()
        Warnings = @()
    }

    try {
        Import-Module Deployment.Packages -ErrorAction Stop
        $catalog = Get-AppCatalog
        
        $results.CatalogPath = (Get-DeployConfigPath -RelativePath 'configs\apps\apps.json')
        $results.Apps = $catalog

        foreach ($app in $catalog) {
            # Check source paths for MSI/EXE/MSIX
            if ($app.sourceType -in @('msi', 'exe', 'msix') -and $app.source) {
                if (-not (Test-Path $app.source)) {
                    $results.Warnings += "App '$($app.id)': Source not found: $($app.source)"
                }
            }

            # Validate detection rules
            if (-not $app.detection) {
                $results.Warnings += "App '$($app.id)': No detection rules defined"
            }
        }

        # Check app sets
        try {
            $appSets = Get-AppSet -SetId 'dev-workstation' -ErrorAction SilentlyContinue
        }
        catch {
            # App sets file might not exist, that's okay
        }

        if ($RunContext) {
            $RunContext | Write-DeployEvent -Level 'Info' -Message "App catalog validated: $($catalog.Count) app(s)" -Data @{
                appCount = $catalog.Count
                warnings = $results.Warnings.Count
            }
        }
    }
    catch {
        $results.Passed = $false
        $results.Errors += $_.Exception.Message
    }

    return $results
}

function Test-TaskSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $TaskSequenceId,

        [Parameter()]
        [pscustomobject] $RunContext
    )

    $results = @{
        Passed = $false
        TaskSequenceId = $TaskSequenceId
        Errors = @()
        Warnings = @()
        StepCount = 0
    }

    try {
        Import-Module Deployment.TaskSequence -ErrorAction Stop
        $ts = Get-TaskSequence -Id $TaskSequenceId
        
        $results.StepCount = $ts.steps.Count

        # Validate step structure
        foreach ($step in $ts.steps) {
            if (-not $step.id) {
                $results.Errors += "Step missing 'id' field"
            }
            if (-not $step.type) {
                $results.Errors += "Step '$($step.id)' missing 'type' field"
            }
            if (-not $step.inputs) {
                $results.Warnings += "Step '$($step.id)' missing 'inputs' field"
            }
        }

        # Check for required steps in bare-metal deployments
        $stepTypes = $ts.steps | ForEach-Object { $_.type }
        if ($stepTypes -contains 'PartitionDisk' -and -not ($stepTypes -contains 'ApplyImage')) {
            $results.Errors += "PartitionDisk step found but no ApplyImage step"
        }

        $results.Passed = ($results.Errors.Count -eq 0)

        if ($RunContext) {
            $RunContext | Write-DeployEvent -Level 'Info' -Message "Task sequence validated: $TaskSequenceId" -Data @{
                stepCount = $results.StepCount
                errors = $results.Errors.Count
            }
        }
    }
    catch {
        $results.Errors += $_.Exception.Message
    }

    return $results
}

function Test-HardwareCompatibility {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable] $Requirements,

        [Parameter()]
        [pscustomobject] $RunContext
    )

    $results = @{
        Passed = $true
        HardwareProfile = $null
        Checks = @()
        Errors = @()
    }

    try {
        Import-Module Deployment.Drivers -ErrorAction Stop
        $hw = Get-HardwareProfile
        $results.HardwareProfile = $hw

        if ($Requirements) {
            # Check minimum memory
            if ($Requirements.MinMemoryGB) {
                $minMem = [double]$Requirements.MinMemoryGB
                $actualMem = $hw.TotalMemoryGB
                $status = if ($actualMem -ge $minMem) { 'Pass' } else { 'Fail' }
                $results.Checks += [pscustomobject]@{
                    Name = 'Minimum Memory'
                    Status = $status
                    Message = "$actualMem GB (required: $minMem GB)"
                }
                if ($status -eq 'Fail') {
                    $results.Passed = $false
                    $results.Errors += "Insufficient memory: $actualMem GB < $minMem GB"
                }
            }

            # Check CPU cores
            if ($Requirements.MinCores) {
                $minCores = [int]$Requirements.MinCores
                $actualCores = $hw.CPUCores
                $status = if ($actualCores -ge $minCores) { 'Pass' } else { 'Fail' }
                $results.Checks += [pscustomobject]@{
                    Name = 'Minimum CPU Cores'
                    Status = $status
                    Message = "$actualCores cores (required: $minCores cores)"
                }
                if ($status -eq 'Fail') {
                    $results.Passed = $false
                    $results.Errors += "Insufficient CPU cores: $actualCores < $minCores"
                }
            }
        }

        if ($RunContext) {
            $RunContext | Write-DeployEvent -Level 'Info' -Message "Hardware compatibility check completed" -Data @{
                manufacturer = $hw.Manufacturer
                model = $hw.Model
                memoryGB = $hw.TotalMemoryGB
                cpuCores = $hw.CPUCores
            }
        }
    }
    catch {
        $results.Passed = $false
        $results.Errors += $_.Exception.Message
    }

    return $results
}

