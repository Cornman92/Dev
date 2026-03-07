function Stop-B11UserSession {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [int]$SessionId)
    if (-not $PSCmdlet.ShouldProcess("Session $SessionId", 'Logoff session')) { return $false }
    try { $null = logoff $SessionId 2>&1; return $true }
    catch { Write-Error "Failed: $_"; return $false }
}
