Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop

function Export-ToDscConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $OptimizationProfileId,

        [Parameter()]
        [string] $OutputPath
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Exporting optimization profile to DSC configuration" -Data @{
        optimizationProfileId = $OptimizationProfileId
    }

    Import-Module Deployment.Optimization -ErrorAction Stop

    try {
        $profile = Get-OptimizationProfile -Id $OptimizationProfileId
        $root = Get-DeployRoot

        if (-not $OutputPath) {
            $OutputPath = Join-Path $root "configs\dsc\$OptimizationProfileId.ps1"
        }

        $dscConfig = @"
Configuration $OptimizationProfileId {
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost {
        # Generated from optimization profile: $($profile.name)
        # Description: $($profile.description)

"@

        foreach ($action in $profile.actions) {
            switch ($action.type) {
                'RegistrySet' {
                    $dscConfig += @"
        Registry '$($action.path)\$($action.name)' {
            Ensure = 'Present'
            Key = '$($action.path)'
            ValueName = '$($action.name)'
            ValueType = '$($action.valueType)'
            ValueData = '$($action.value)'
        }

"@
                }
                'ServiceConfig' {
                    $dscConfig += @"
        Service '$($action.serviceName)' {
            Name = '$($action.serviceName)'
            State = '$(if ($action.ensureStopped) { 'Stopped' } else { 'Running' })'
            StartupType = '$($action.startType)'
        }

"@
                }
            }
        }

        $dscConfig += @"
    }
}
"@

        $dscConfig | Set-Content -Path $OutputPath -Encoding UTF8
        $RunContext | Write-DeployEvent -Level 'Info' -Message "DSC configuration exported to: $OutputPath"

        return $OutputPath
    }
    catch {
        $RunContext | Write-DeployError -Exception $_ -Context 'Export-ToDscConfiguration'
        throw
    }
}

function Compile-DscConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $ConfigurationPath,

        [Parameter()]
        [string] $OutputPath
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Compiling DSC configuration" -Data @{
        configurationPath = $ConfigurationPath
    }

    if (-not (Test-Path $ConfigurationPath)) {
        throw "Configuration file not found: $ConfigurationPath"
    }

    try {
        . $ConfigurationPath

        if (-not $OutputPath) {
            $OutputPath = Join-Path (Split-Path $ConfigurationPath) 'Output'
        }

        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $configName = [System.IO.Path]::GetFileNameWithoutExtension($ConfigurationPath)
        & $configName -OutputPath $OutputPath

        $RunContext | Write-DeployEvent -Level 'Info' -Message "DSC configuration compiled to: $OutputPath"
        return $OutputPath
    }
    catch {
        $RunContext | Write-DeployError -Exception $_ -Context 'Compile-DscConfiguration'
        throw
    }
}

function Apply-DscConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $MofPath
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Applying DSC configuration" -Data @{
        mofPath = $MofPath
    }

    if (-not (Test-Path $MofPath)) {
        throw "MOF file not found: $MofPath"
    }

    try {
        Start-DscConfiguration -Path (Split-Path $MofPath) -Wait -Force -Verbose
        $RunContext | Write-DeployEvent -Level 'Info' -Message "DSC configuration applied successfully"
    }
    catch {
        $RunContext | Write-DeployError -Exception $_ -Context 'Apply-DscConfiguration'
        throw
    }
}

function Test-DscConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $MofPath
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Testing DSC configuration compliance"

    if (-not (Test-Path $MofPath)) {
        throw "MOF file not found: $MofPath"
    }

    try {
        $result = Test-DscConfiguration -Path (Split-Path $MofPath)
        $RunContext | Write-DeployEvent -Level 'Info' -Message "DSC configuration test completed. InDesiredState: $($result.InDesiredState)"
        return $result
    }
    catch {
        $RunContext | Write-DeployError -Exception $_ -Context 'Test-DscConfiguration'
        throw
    }
}

