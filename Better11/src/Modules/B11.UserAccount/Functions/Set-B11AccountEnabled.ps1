function Set-B11AccountEnabled {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [string]$Username, [Parameter(Mandatory)] [bool]$Enabled)
    if (-not $PSCmdlet.ShouldProcess($Username, "Set enabled=$Enabled")) { return $false }
    try {
        if ($Enabled) { Enable-LocalUser -Name $Username -ErrorAction Stop }
        else { Disable-LocalUser -Name $Username -ErrorAction Stop }
        return $true
    } catch { Write-Error "Failed: $_"; return $false }
}
