. ".\modules\common.ps1"
. ".\modules\drift.ps1"
Assert-Admin
$t=Read-Json ".\state\postinstall-toggles.json"
Detect-Drift $t|Format-Table
