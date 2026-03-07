function Get-B11LocalAccount {
    [CmdletBinding()] [OutputType([PSCustomObject[]])] param()
    try {
        $admins = (Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue).Name | ForEach-Object { ($_ -split '\\')[-1] }
        return @(Get-LocalUser -ErrorAction Stop | ForEach-Object {
            [PSCustomObject]@{
                Username = $_.Name; FullName = $_.FullName; Sid = $_.SID.Value; Enabled = $_.Enabled
                IsAdmin = ($_.Name -in $admins); Description = $_.Description
                LastLogin = if ($_.LastLogon) { $_.LastLogon.ToString('o') } else { 'Never' }
                PasswordNeverExpires = $_.PasswordNeverExpires; IsLockedOut = $_.IsLockedOut
            }
        })
    } catch { Write-Error "Failed: $_"; return @() }
}
