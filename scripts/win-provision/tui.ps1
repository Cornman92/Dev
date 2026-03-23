. ".\modules\common.ps1"
$t=Read-Json ".\state\postinstall-toggles.json"
Clear-Host
Write-Host "Toggle apps (type name, enter toggles, Q quit)"
while($true){
  $k=Read-Host "App ID"
  if($k -eq "Q"){break}
  if($t.appsEnabled.PSObject.Properties.Name -contains $k){
    $t.appsEnabled.$k = -not $t.appsEnabled.$k
    Write-Json ".\state\postinstall-toggles.json" $t
  }
}
