. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\catalog.ps1"

function Bootstrap-State($t,[bool]$Force){
  Ensure-Prop $t "appsEnabled" ([pscustomobject]@{})
  foreach($g in (Get-AppCatalog).Keys){
    foreach($a in (Get-AppCatalog)[$g]){
      $id=Get-AppId $a
      if($Force -or -not($t.appsEnabled.PSObject.Properties.Name -contains $id)){
        $t.appsEnabled|Add-Member -NotePropertyName $id -NotePropertyValue $true -Force
      }
    }
  }

  Ensure-Prop $t "optionalFeatures" ([pscustomobject]@{})
  Get-WindowsOptionalFeature -Online|%{
    if($Force -or -not($t.optionalFeatures.PSObject.Properties.Name -contains $_.FeatureName)){
      $t.optionalFeatures|Add-Member -NotePropertyName $_.FeatureName `
        -NotePropertyValue ($_.State -eq "Enabled") -Force
    }
  }

  Ensure-Prop $t "capabilities" ([pscustomobject]@{})
  Get-WindowsCapability -Online|%{
    if($Force -or -not($t.capabilities.PSObject.Properties.Name -contains $_.Name)){
      $t.capabilities|Add-Member -NotePropertyName $_.Name `
        -NotePropertyValue ($_.State -eq "Installed") -Force
    }
  }
  $t
}
