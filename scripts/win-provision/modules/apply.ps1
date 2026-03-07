. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\catalog.ps1"

function Apply-State($t){
  if(Module-Enabled $t "WinGet"){
    foreach($g in (Get-AppCatalog).Keys){
      if(-not $t.wingetInstall.GroupsEnabled.$g){continue}
      foreach($a in (Get-AppCatalog)[$g]){
        $id=Get-AppId $a
        if($t.appsEnabled.$id){
          winget install --id $id --exact --silent `
            --accept-package-agreements --accept-source-agreements
        }
      }
    }
  }

  if(Module-Enabled $t "OptionalFeaturesEnable"){
    foreach($f in $t.optionalFeatures.PSObject.Properties){
      if($f.Value){
        Enable-WindowsOptionalFeature -Online -FeatureName $f.Name -All -NoRestart
      }
    }
  }

  if(Module-Enabled $t "CapabilitiesEnable"){
    foreach($c in $t.capabilities.PSObject.Properties){
      if($c.Value){
        Add-WindowsCapability -Online -Name $c.Name
      }
    }
  }
}
