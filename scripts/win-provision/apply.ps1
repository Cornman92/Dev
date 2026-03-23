. ".\modules\common.ps1"
. ".\modules\apply.ps1"
Assert-Admin
$t=Read-Json ".\state\postinstall-toggles.json"
Apply-State $t
