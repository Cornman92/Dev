Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop
Import-Module Deployment.TaskSequence -ErrorAction Stop

function Export-ToMdt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $TaskSequenceId,

        [Parameter(Mandatory)]
        [string] $MdtPath,

        [Parameter()]
        [string] $MdtShareName = 'DeploymentShare$'
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Exporting task sequence to MDT" -Data @{
        taskSequenceId = $TaskSequenceId
        mdtPath = $MdtPath
    }

    if (-not (Test-Path $MdtPath)) {
        throw "MDT path not found: $MdtPath"
    }

    # Import MDT module if available
    $mdtModule = Get-Module -ListAvailable -Name MicrosoftDeploymentToolkit
    if (-not $mdtModule) {
        throw "MDT PowerShell module not found. Please install Microsoft Deployment Toolkit."
    }

    Import-Module MicrosoftDeploymentToolkit -ErrorAction Stop

    try {
        # Get task sequence
        $ts = Get-TaskSequence -Id $TaskSequenceId

        # Convert to MDT format
        $mdtTs = Convert-MdtTaskSequence -TaskSequence $ts

        # Create MDT task sequence
        $mdtShare = Get-Item "DS001:$MdtShareName"
        $mdtTaskSequence = New-Item -Path "DS001:$MdtShareName\Task Sequences" -Name $ts.name -ItemType TaskSequence -ErrorAction Stop

        $RunContext | Write-DeployEvent -Level 'Info' -Message "Task sequence exported to MDT successfully"
        return $mdtTaskSequence
    }
    catch {
        $RunContext | Write-DeployError -Exception $_ -Context 'Export-ToMdt'
        throw
    }
}

function Import-FromMdt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $MdtTaskSequencePath,

        [Parameter()]
        [string] $OutputId
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Importing task sequence from MDT" -Data @{
        mdtTaskSequencePath = $MdtTaskSequencePath
    }

    # Import MDT module if available
    $mdtModule = Get-Module -ListAvailable -Name MicrosoftDeploymentToolkit
    if (-not $mdtModule) {
        throw "MDT PowerShell module not found. Please install Microsoft Deployment Toolkit."
    }

    Import-Module MicrosoftDeploymentToolkit -ErrorAction Stop

    try {
        $mdtTs = Get-Item $MdtTaskSequencePath
        $ts = Convert-SccmTaskSequence -MdtTaskSequence $mdtTs

        # Save to toolkit format
        $root = Get-DeployRoot
        $outputPath = Join-Path $root "configs\task_sequences\$OutputId.json"
        
        if (-not $OutputId) {
            $OutputId = $mdtTs.Name -replace '[^a-zA-Z0-9-]', '-'
        }

        $ts | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8

        $RunContext | Write-DeployEvent -Level 'Info' -Message "Task sequence imported from MDT successfully"
        return $ts
    }
    catch {
        $RunContext | Write-DeployError -Exception $_ -Context 'Import-FromMdt'
        throw
    }
}

function Sync-WithSccm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $TaskSequenceId,

        [Parameter(Mandatory)]
        [string] $SccmSiteCode,

        [Parameter()]
        [string] $SccmServerName = $env:COMPUTERNAME
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Syncing task sequence with SCCM" -Data @{
        taskSequenceId = $TaskSequenceId
        sccmSiteCode = $SccmSiteCode
        sccmServer = $SccmServerName
    }

    # Check if SCCM admin console is available
    $sccmModule = Get-Module -ListAvailable -Name ConfigurationManager
    if (-not $sccmModule) {
        throw "SCCM PowerShell module not found. Please install Configuration Manager admin console."
    }

    try {
        # Connect to SCCM site
        $siteDrive = "${SccmSiteCode}:"
        if (-not (Get-PSDrive -Name $SccmSiteCode -ErrorAction SilentlyContinue)) {
            Import-Module ConfigurationManager -ErrorAction Stop
            New-PSDrive -Name $SccmSiteCode -PSProvider CMSite -Root $SccmServerName -ErrorAction Stop | Out-Null
        }

        Set-Location "${siteDrive}:\"

        # Get task sequence
        $ts = Get-TaskSequence -Id $TaskSequenceId

        # Convert to SCCM format
        $sccmTs = Convert-SccmTaskSequence -TaskSequence $ts

        # Create or update SCCM task sequence
        $existingTs = Get-CMTaskSequence -Name $ts.name -ErrorAction SilentlyContinue
        if ($existingTs) {
            Set-CMTaskSequence -InputObject $existingTs -TaskSequence $sccmTs
            $RunContext | Write-DeployEvent -Level 'Info' -Message "SCCM task sequence updated"
        }
        else {
            New-CMTaskSequence -Name $ts.name -TaskSequence $sccmTs
            $RunContext | Write-DeployEvent -Level 'Info' -Message "SCCM task sequence created"
        }

        Set-Location $PWD
        $RunContext | Write-DeployEvent -Level 'Info' -Message "Task sequence synced with SCCM successfully"
    }
    catch {
        $RunContext | Write-DeployError -Exception $_ -Context 'Sync-WithSccm'
        throw
    }
}

function Convert-MdtTaskSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $TaskSequence
    )

    # Convert toolkit task sequence to MDT format
    # This is a simplified conversion - real implementation would be more complex
    $mdtSteps = @()

    foreach ($step in $TaskSequence.steps) {
        $mdtStep = @{
            Type = $step.type
            Name = $step.name
            Properties = $step.inputs
        }
        $mdtSteps += $mdtStep
    }

    return @{
        Name = $TaskSequence.name
        Description = $TaskSequence.description
        Steps = $mdtSteps
    }
}

function Convert-SccmTaskSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $TaskSequence
    )

    # Convert toolkit task sequence to SCCM format
    # This is a placeholder - real implementation would use SCCM SDK
    $sccmSteps = @()

    foreach ($step in $TaskSequence.steps) {
        $sccmStep = @{
            Action = $step.type
            Name = $step.name
            Parameters = $step.inputs
        }
        $sccmSteps += $sccmStep
    }

    return @{
        Name = $TaskSequence.name
        Description = $TaskSequence.description
        Steps = $sccmSteps
    }
}

