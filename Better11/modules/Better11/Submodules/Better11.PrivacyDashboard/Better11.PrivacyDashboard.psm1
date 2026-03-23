#Requires -Version 7.4
# Better11.PrivacyDashboard - Privacy and telemetry
$script:ModuleRoot = $PSScriptRoot
$publicPath = Join-Path $PSScriptRoot 'Public'
if (Test-Path $publicPath) { Get-ChildItem $publicPath -Filter '*.ps1' | ForEach-Object { . $_.FullName } }
$privatePath = Join-Path $PSScriptRoot 'Private'
if (Test-Path $privatePath) { Get-ChildItem $privatePath -Filter '*.ps1' | ForEach-Object { . $_.FullName } }
