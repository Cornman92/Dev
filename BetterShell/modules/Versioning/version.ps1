$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AccessSentinel.psm1'
Import-Module $modulePath -Force

Get-AccessSentinelVersion | Format-List *
