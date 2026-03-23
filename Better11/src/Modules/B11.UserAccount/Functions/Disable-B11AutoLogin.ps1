function Disable-B11AutoLogin {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])] param()
    if (-not $PSCmdlet.ShouldProcess('Auto-login', 'Disable')) { return $false }
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    try {
        Set-ItemProperty -Path $regPath -Name 'AutoAdminLogon' -Value '0' -Force
        Remove-ItemProperty -Path $regPath -Name 'DefaultPassword' -Force -ErrorAction SilentlyContinue
        return $true
    } catch { Write-Error "Failed: $_"; return $false }
}
