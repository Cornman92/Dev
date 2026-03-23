#Requires -Version 7.0
$functionPath = Join-Path $PSScriptRoot 'Functions'
if (Test-Path $functionPath) { Get-ChildItem -Path $functionPath -Filter '*.ps1' -Recurse | ForEach-Object { . $_.FullName } }
