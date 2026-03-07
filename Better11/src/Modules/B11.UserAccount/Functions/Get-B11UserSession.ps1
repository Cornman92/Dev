function Get-B11UserSession {
    [CmdletBinding()] [OutputType([PSCustomObject[]])] param()
    try {
        $output = query user 2>&1
        return @($output | Select-Object -Skip 1 | Where-Object { $_ -match '\S' } | ForEach-Object {
            $parts = $_ -split '\s{2,}'
            $username = ($parts[0] ?? '').Trim('>').Trim()
            $sessionType = if ($parts[1] -match 'console') { 'Console' } elseif ($parts[1] -match 'rdp') { 'RDP' } else { $parts[1] }
            $id = 0; foreach ($p in $parts) { if ($p -match '^\d+$') { $id = [int]$p; break } }
            $state = if ($_ -match 'Active') { 'Active' } elseif ($_ -match 'Disc') { 'Disconnected' } else { 'Unknown' }
            [PSCustomObject]@{ SessionId = $id; Username = $username; State = $state; SessionType = $sessionType; LogonTime = ''; IdleTime = '' }
        })
    } catch { return @() }
}
