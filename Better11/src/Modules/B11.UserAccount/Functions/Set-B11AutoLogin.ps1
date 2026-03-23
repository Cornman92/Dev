function Set-B11AutoLogin {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [string]$Username, [Parameter()] [string]$Password = '')
    if (-not $PSCmdlet.ShouldProcess($Username, 'Configure auto-login')) { return $false }
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    try {
        Set-ItemProperty -Path $regPath -Name 'AutoAdminLogon' -Value '1' -Force
        Set-ItemProperty -Path $regPath -Name 'DefaultUserName' -Value $Username -Force
        Set-ItemProperty -Path $regPath -Name 'DefaultPassword' -Value $Password -Force
        return $true
    } catch { Write-Error "Failed: $_"; return $false }
}
