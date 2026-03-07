function Get-B11GroupMember {
    [CmdletBinding()] [OutputType([PSCustomObject[]])]
    param([Parameter(Mandatory)] [string]$GroupName)
    try {
        return @(Get-LocalGroupMember -Group $GroupName -ErrorAction Stop | ForEach-Object {
            [PSCustomObject]@{ Name = $_.Name; Sid = $_.SID.Value; ObjectClass = $_.ObjectClass; PrincipalSource = "$($_.PrincipalSource)" }
        })
    } catch { Write-Error "Failed: $_"; return @() }
}
