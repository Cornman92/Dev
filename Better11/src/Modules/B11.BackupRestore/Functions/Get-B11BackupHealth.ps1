function Get-B11BackupHealth {
    <#
    .SYNOPSIS
        Gets overall backup system health status.
    #>
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param()

    $regBackups = Get-B11RegistryBackup
    $appBackups = Get-B11AppConfigBackup
    $schedules = Get-B11BackupSchedule

    $allBackups = @()
    $totalSize = 0L
    $healthy = 0
    $corrupted = 0

    foreach ($b in $regBackups) {
        $allBackups += $b
        $totalSize += $b.SizeBytes
        if ($b.Status -eq 'Success' -and (Test-Path $b.FilePath)) { $healthy++ } else { $corrupted++ }
    }
    foreach ($b in $appBackups) {
        $allBackups += $b
        $totalSize += $b.SizeBytes
        if ($b.Status -eq 'Success' -and (Test-Path $b.ArchivePath)) { $healthy++ } else { $corrupted++ }
    }

    $oldestDays = 0
    $newestDays = 0
    $now = [DateTime]::UtcNow
    if ($allBackups.Count -gt 0) {
        $dates = $allBackups | ForEach-Object { [DateTime]::Parse($_.CreatedDate) } | Sort-Object
        $oldestDays = [int]($now - $dates[0]).TotalDays
        $newestDays = [int]($now - $dates[-1]).TotalDays
    }

    $activeSchedules = ($schedules | Where-Object { $_.IsEnabled }).Count
    $hasOverdue = $false
    foreach ($s in ($schedules | Where-Object { $_.IsEnabled })) {
        if ($s.NextRunTime -and [DateTime]::Parse($s.NextRunTime) -lt $now) { $hasOverdue = $true; break }
    }

    return [PSCustomObject]@{
        TotalBackups     = $allBackups.Count
        TotalSizeBytes   = $totalSize
        HealthyCount     = $healthy
        CorruptedCount   = $corrupted
        OldestBackupDays = $oldestDays
        NewestBackupDays = $newestDays
        ActiveSchedules  = $activeSchedules
        HasOverdueBackups = $hasOverdue
    }
}
