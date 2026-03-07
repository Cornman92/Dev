function Get-B11AutoLogin {
    [CmdletBinding()] [OutputType([PSCustomObject])] param()
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $reg = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
    $enabled = ($reg.AutoAdminLogon ?? '0') -eq '1'
    return [PSCustomObject]@{ Enabled = $enabled; Username = $reg.DefaultUserName ?? ''; Domain = $reg.DefaultDomainName ?? '' }
}
