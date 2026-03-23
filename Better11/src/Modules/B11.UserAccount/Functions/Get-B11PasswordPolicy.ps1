function Get-B11PasswordPolicy {
    [CmdletBinding()] [OutputType([PSCustomObject])] param()
    try {
        $output = net accounts 2>&1
        $minLen = 0; $maxAge = 42; $minAge = 0; $lockout = 0; $lockDur = 30
        foreach ($line in $output) {
            if ($line -match 'Minimum password length:\s+(\d+)') { $minLen = [int]$Matches[1] }
            if ($line -match 'Maximum password age.*?:\s+(\d+)') { $maxAge = [int]$Matches[1] }
            if ($line -match 'Minimum password age.*?:\s+(\d+)') { $minAge = [int]$Matches[1] }
            if ($line -match 'Lockout threshold:\s+(\d+|Never)') { $lockout = if ($Matches[1] -eq 'Never') { 0 } else { [int]$Matches[1] } }
            if ($line -match 'Lockout duration.*?:\s+(\d+)') { $lockDur = [int]$Matches[1] }
        }
        $secedit = "$env:TEMP\b11secedit.cfg"
        $null = secedit /export /cfg $secedit /areas SECURITYPOLICY 2>&1
        $complexity = $false; $history = 0
        if (Test-Path $secedit) {
            $cfg = Get-Content $secedit -Raw
            if ($cfg -match 'PasswordComplexity\s*=\s*(\d+)') { $complexity = $Matches[1] -eq '1' }
            if ($cfg -match 'PasswordHistorySize\s*=\s*(\d+)') { $history = [int]$Matches[1] }
            Remove-Item $secedit -Force -ErrorAction SilentlyContinue
        }
        return [PSCustomObject]@{ MinLength = $minLen; ComplexityEnabled = $complexity; MaxAgeDays = $maxAge; MinAgeDays = $minAge; HistoryCount = $history; LockoutThreshold = $lockout; LockoutDurationMinutes = $lockDur }
    } catch { return [PSCustomObject]@{ MinLength = 0; ComplexityEnabled = $false; MaxAgeDays = 42; MinAgeDays = 0; HistoryCount = 0; LockoutThreshold = 0; LockoutDurationMinutes = 30 } }
}
