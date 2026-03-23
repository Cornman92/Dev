#Requires -Version 7.0
$script:B11BackupDir = Join-Path $env:APPDATA 'Better11\Backups'
if (-not (Test-Path $script:B11BackupDir)) { New-Item -Path $script:B11BackupDir -ItemType Directory -Force | Out-Null }
$functionPath = Join-Path $PSScriptRoot 'Functions'
if (Test-Path $functionPath) { Get-ChildItem -Path $functionPath -Filter '*.ps1' -Recurse | ForEach-Object { . $_.FullName } }
