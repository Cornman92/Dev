. ".\modules\common.ps1"
. ".\modules\bootstrap.ps1"
Assert-Admin
$t=Read-Json ".\state\postinstall-toggles.json"
$t=Bootstrap-State $t $true
$t.metadata.generatedOn=(Get-Date)
Write-Json ".\state\postinstall-toggles.json" $t
