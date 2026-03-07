Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop

function New-AppCaptureProvisioningPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $ScanStatePath = 'scanstate.exe',

        [Parameter()]
        [switch] $OverwriteExisting
    )

    if ((Test-Path $OutputPath) -and -not $OverwriteExisting) {
        throw "Output PPKG '$OutputPath' already exists. Use -OverwriteExisting to replace it."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Creating app-capture provisioning package at '$OutputPath'."

    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }

    $args = "/apps /ppkg `"$OutputPath`" /o"

    $RunContext | Write-DeployEvent -Level 'Debug' -Message "Running '$ScanStatePath' with arguments: $args."

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $ScanStatePath
    $pinfo.Arguments = $args
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError  = $true
    $pinfo.UseShellExecute        = $false
    $pinfo.CreateNoWindow         = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $pinfo

    if (-not $proc.Start()) {
        throw "Failed to start '$ScanStatePath' for provisioning package capture."
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    Add-Content -Path $RunContext.RunLogPath -Value $stdout
    if ($stderr) {
        Add-Content -Path $RunContext.RunLogPath -Value $stderr
    }

    if ($proc.ExitCode -ne 0) {
        $RunContext | Write-DeployEvent -Level 'Error' -Message "scanstate exited with code $($proc.ExitCode)."
        throw "scanstate failed. Exit code: $($proc.ExitCode)."
    }

    if (-not (Test-Path $OutputPath)) {
        throw "scanstate completed but PPKG '$OutputPath' was not created."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Provisioning package created at '$OutputPath'."

    return $OutputPath
}

function Install-ProvisioningPackageLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $PackagePath,

        [Parameter()]
        [switch] $Quiet,

        [Parameter()]
        [string] $LogsDirectory
    )

    if (-not (Test-Path $PackagePath)) {
        throw "Provisioning package '$PackagePath' does not exist."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Installing provisioning package '$PackagePath' on local system."

    $installCmd = Get-Command -Name Install-ProvisioningPackage -ErrorAction SilentlyContinue

    if ($installCmd) {
        $params = @{
            PackagePath = $PackagePath
        }

        if ($Quiet) { $params['QuietInstall'] = $true }
        if ($LogsDirectory) { $params['LogsDirectoryPath'] = $LogsDirectory }

        try {
            $null = Install-ProvisioningPackage @params
            $RunContext | Write-DeployEvent -Level 'Info' -Message "Provisioning package installed via Install-ProvisioningPackage."
            return
        }
        catch {
            $RunContext | Write-DeployEvent -Level 'Warning' -Message "Install-ProvisioningPackage failed: $($_.Exception.Message). Falling back to DISM."
        }
    }

    $args = "/online /Add-ProvisioningPackage /PackagePath:`"$PackagePath`""

    $RunContext | Write-DeployEvent -Level 'Debug' -Message "Running DISM with arguments: $args."

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
        throw "Failed to start dism.exe for provisioning package install."
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    Add-Content -Path $RunContext.RunLogPath -Value $stdout
    if ($stderr) {
        Add-Content -Path $RunContext.RunLogPath -Value $stderr
    }

    if ($proc.ExitCode -ne 0) {
        $RunContext | Write-DeployEvent -Level 'Error' -Message "DISM /Add-ProvisioningPackage failed with exit code $($proc.ExitCode)."
        throw "Provisioning package installation failed. Exit code: $($proc.ExitCode)."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Provisioning package installed via DISM."
}

function Add-ProvisioningPackageToOfflineImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ImagePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $PackagePath
    )

    if (-not (Test-Path $ImagePath)) {
        throw "Offline image path '$ImagePath' not found."
    }

    if (-not (Test-Path $PackagePath)) {
        throw "Provisioning package '$PackagePath' not found."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Adding provisioning package '$PackagePath' to offline image '$ImagePath'."

    $args = "/Image:`"$ImagePath`" /Add-ProvisioningPackage /PackagePath:`"$PackagePath`""

    $RunContext | Write-DeployEvent -Level 'Debug' -Message "Running DISM with arguments: $args."

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
        throw "Failed to start dism.exe for offline provisioning package injection."
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    Add-Content -Path $RunContext.RunLogPath -Value $stdout
    if ($stderr) {
        Add-Content -Path $RunContext.RunLogPath -Value $stderr
    }

    if ($proc.ExitCode -ne 0) {
        $RunContext | Write-DeployEvent -Level 'Error' -Message "DISM /Add-ProvisioningPackage (offline) failed with exit code $($proc.ExitCode)."
        throw "Offline provisioning package injection failed. Exit code: $($proc.ExitCode)."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Provisioning package added to offline image."
}

