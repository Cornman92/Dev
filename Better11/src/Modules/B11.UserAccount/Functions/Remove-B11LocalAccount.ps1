function Remove-B11LocalAccount {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [string]$Username)
    if (-not $PSCmdlet.ShouldProcess($Username, 'Delete local account')) { return $false }
    try { Remove-LocalUser -Name $Username -ErrorAction Stop; return $true }
    catch { Write-Error "Failed: $_"; return $false }
}
