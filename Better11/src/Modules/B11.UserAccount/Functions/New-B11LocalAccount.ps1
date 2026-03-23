function New-B11LocalAccount {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [string]$Username, [Parameter()] [string]$Password = '', [Parameter()] [string]$FullName = '')
    if (-not $PSCmdlet.ShouldProcess($Username, 'Create local account')) { return $false }
    try {
        $params = @{ Name = $Username; NoPassword = $true }
        if ($Password) { $params.Remove('NoPassword'); $params['Password'] = (ConvertTo-SecureString $Password -AsPlainText -Force) }
        if ($FullName) { $params['FullName'] = $FullName }
        New-LocalUser @params -ErrorAction Stop | Out-Null; return $true
    } catch { Write-Error "Failed: $_"; return $false }
}
