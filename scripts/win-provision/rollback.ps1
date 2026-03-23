param($Snapshot)
. ".\modules\apply.ps1"
$s=Get-Content $Snapshot -Raw|ConvertFrom-Json
$s.Features|%{
  if($_.State -eq "Enabled"){
    Enable-WindowsOptionalFeature -Online -FeatureName $_.FeatureName
  }
}
