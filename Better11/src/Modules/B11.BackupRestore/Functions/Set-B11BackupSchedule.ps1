function Set-B11BackupSchedule {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [string]$ScheduleId,
        [Parameter()] [string]$Name,
        [Parameter()] [string]$Frequency,
        [Parameter()] [int]$RetentionCount = -1,
        [Parameter()] [bool]$IsEnabled = $true
    )

    $config = Read-JsonConfig -FileName 'schedules.json'
    if ($null -eq $config -or $null -eq $config.Schedules) { Write-Error 'No schedules.'; return $false }

    $found = $false
    $updated = @($config.Schedules | ForEach-Object {
        if ($_.Id -eq $ScheduleId) {
            $found = $true
            if ($Name) { $_.Name = $Name }
            if ($Frequency) { $_.Frequency = $Frequency }
            if ($RetentionCount -ge 0) { $_.RetentionCount = $RetentionCount }
            $_.IsEnabled = $IsEnabled
        }
        $_
    })

    if (-not $found) { Write-Error "Schedule not found: $ScheduleId"; return $false }
    if (-not $PSCmdlet.ShouldProcess($ScheduleId, 'Update schedule')) { return $false }

    $config.Schedules = $updated
    Write-JsonConfig -FileName 'schedules.json' -Data $config
    return $true
}
