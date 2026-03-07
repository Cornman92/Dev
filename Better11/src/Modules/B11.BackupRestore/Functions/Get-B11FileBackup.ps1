function Get-B11FileBackup{[CmdletBinding()][OutputType([PSCustomObject[]])]param()
$dir=Join-Path $script:B11BackupDir 'Files';if(-not(Test-Path $dir)){return @()}
$metaFile=Join-Path $dir 'manifest.json';if(-not(Test-Path $metaFile)){return @()}
try{return @(Get-Content $metaFile -Raw|ConvertFrom-Json)}catch{return @()}}
