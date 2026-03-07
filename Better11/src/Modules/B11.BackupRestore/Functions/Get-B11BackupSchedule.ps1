function Get-B11BackupSchedule{[CmdletBinding()][OutputType([PSCustomObject[]])]param()
$file=Join-Path $script:B11BackupDir 'schedules.json';if(-not(Test-Path $file)){return @()}
try{return @(Get-Content $file -Raw|ConvertFrom-Json)}catch{return @()}}
