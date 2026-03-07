#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    # Optional: path to Features-on-Demand ISO root
    [string[]]$Source,

    # Use with -Source to avoid Windows Update
    [switch]$LimitAccess
)

$CapabilitiesToAdd = @(
    'OpenSSH.Server~~~~0.0.1.0',
    'Tpm.TpmDiagnostics~~~~0.0.1.0',
    'WMIC~~~~',
    'Network.Irda~~~~0.0.1.0',
    'Msix.PackagingTool.Driver~~~~0.0.1.0',
    'Microsoft.Windows.StorageManagement~~~~0.0.1.0',
    'App.WirelessDisplay.Connect~~~~0.0.1.0'
)

foreach ($cap in $CapabilitiesToAdd) {
    if ($PSCmdlet.ShouldProcess("Capability: $cap", "Add-WindowsCapability")) {
        try {
            $params = @{
                Online      = $true
                Name        = $cap
                ErrorAction = 'Stop'
            }

            if ($Source)      { $params.Source = $Source }
            if ($LimitAccess) { $params.LimitAccess = $true }

            Add-WindowsCapability @params | Out-Null
            Write-Host "Installed: $cap" -ForegroundColor Green
        }
        catch {
            Write-Warning "FAILED installing $cap : $($_.Exception.Message)"
        }
    }
}

Write-Host "Completed capability installation. Reboot may be required." -ForegroundColor Yellow