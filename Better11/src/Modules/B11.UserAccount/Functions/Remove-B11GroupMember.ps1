function Remove-B11GroupMember {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [string]$GroupName, [Parameter(Mandatory)] [string]$Username)
    if (-not $PSCmdlet.ShouldProcess("$Username from $GroupName", 'Remove group member')) { return $false }
    try { Remove-LocalGroupMember -Group $GroupName -Member $Username -ErrorAction Stop; return $true }
    catch { Write-Error "Failed: $_"; return $false }
}
