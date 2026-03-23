function Get-B11LocalGroup {
    [CmdletBinding()] [OutputType([PSCustomObject[]])] param()
    try {
        return @(Get-LocalGroup -ErrorAction Stop | ForEach-Object {
            $members = (Get-LocalGroupMember -Group $_.Name -ErrorAction SilentlyContinue).Count
            [PSCustomObject]@{ Name = $_.Name; Sid = $_.SID.Value; Description = $_.Description; MemberCount = $members }
        })
    } catch { Write-Error "Failed: $_"; return @() }
}
