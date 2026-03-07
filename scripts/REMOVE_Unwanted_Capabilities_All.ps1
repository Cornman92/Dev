#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param()

$CapabilitiesToRemove = @(
    # --- Print / Scan / XPS ---
    'Print.Fax.Scan~~~~0.0.1.0',
    'Print.Management.Console~~~~0.0.1.0',
    'XPS.Viewer~~~~0.0.1.0',

    # --- RSAT ---
    'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',

    # --- Accessibility / Input ---
    'Accessibility.Braille~~~~0.0.1.0',
    'Hello.Face.20134~~~~0.0.1.0',
    'MathRecognizer~~~~0.0.1.0',

    # --- Ethernet (Intel) ---
    'Microsoft.Windows.Ethernet.Client.Intel.E1i68x64~~~~0.0.1.0',
    'Microsoft.Windows.Ethernet.Client.Intel.E2f68~~~~0.0.1.0',

    # --- Wi‑Fi Broadcom ---
    'Microsoft.Windows.Wifi.Client.Broadcom.Bcmpciedhd63~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Broadcom.Bcmwl63a~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Broadcom.Bcmwl63al~~~~0.0.1.0',

    # --- Wi‑Fi Intel ---
    'Microsoft.Windows.Wifi.Client.Intel.Netwbw02~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Intel.Netwew00~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Intel.Netwew01~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Intel.Netwlv64~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Intel.Netwns64~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Intel.Netwsw00~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Intel.Netwtw02~~~~0.0.1.0',

    # --- Wi‑Fi Qualcomm ---
    'Microsoft.Windows.Wifi.Client.Qualcomm.Athw8x~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Qualcomm.Athwnx~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Qualcomm.Qcamain10x64~~~~0.0.1.0',

    # --- Wi‑Fi Realtek ---
    'Microsoft.Windows.Wifi.Client.Realtek.Rtl8187se~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Realtek.Rtl8192se~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Realtek.Rtl819xp~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Realtek.Rtl85n64~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Realtek.Rtwlane~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Realtek.Rtwlane01~~~~0.0.1.0',
    'Microsoft.Windows.Wifi.Client.Realtek.Rtwlane13~~~~0.0.1.0',

    # --- Wi‑Fi Ralink ---
    'Microsoft.Windows.Wifi.Client.Ralink.Netr28x~~~~0.0.1.0',

    # --- Wi‑Fi Marvel ---
    'Microsoft.Windows.Wifi.Client.Marvel.Mrvlpcie8897~~~~0.0.1.0'
)

foreach ($cap in $CapabilitiesToRemove) {
    $current = Get-WindowsCapability -Online -Name $cap -ErrorAction SilentlyContinue

    if (-not $current) {
        Write-Host "Not found (skipping): $cap" -ForegroundColor DarkGray
        continue
    }

    if ($current.State -ne 'Installed') {
        Write-Host "Not installed (skipping): $cap" -ForegroundColor DarkGray
        continue
    }

    if ($PSCmdlet.ShouldProcess($cap, "Remove-WindowsCapability")) {
        try {
            Remove-WindowsCapability -Online -Name $cap -ErrorAction Stop | Out-Null
            Write-Host "Removed: $cap" -ForegroundColor Green
        }
        catch {
            Write-Warning "FAILED removing $cap : $($_.Exception.Message)"
        }
    }
}

Write-Host "Capability cleanup complete. **REBOOT REQUIRED**." -ForegroundColor Yellow