function Get-B11UserProfile {
    [CmdletBinding()] [OutputType([PSCustomObject[]])] param()
    try {
        $profileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' -ErrorAction SilentlyContinue
        return @($profileList | Where-Object { $_.ProfileImagePath -and $_.ProfileImagePath -notlike '*systemprofile*' } | ForEach-Object {
            $path = $_.ProfileImagePath; $username = Split-Path $path -Leaf
            $size = 0; if (Test-Path $path) { $size = [math]::Round(((Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB), 0) }
            $sid = $_.PSChildName; $loaded = Test-Path "Registry::HKEY_USERS\$sid"
            [PSCustomObject]@{ Username = $username; ProfilePath = $path; SizeMb = $size; Sid = $sid; LastUseTime = ''; IsLoaded = $loaded }
        })
    } catch { return @() }
}
