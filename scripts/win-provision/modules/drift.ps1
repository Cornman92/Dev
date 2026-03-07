function Detect-Drift($t){
  $out=@()
  foreach($f in $t.optionalFeatures.PSObject.Properties){
    $cur=(Get-WindowsOptionalFeature -Online -FeatureName $f.Name).State -eq "Enabled"
    if($cur -ne $f.Value){
      $out+=[pscustomobject]@{Type="Feature";Name=$f.Name}
    }
  }
  foreach($c in $t.capabilities.PSObject.Properties){
    $cur=(Get-WindowsCapability -Online -Name $c.Name).State -eq "Installed"
    if($cur -ne $c.Value){
      $out+=[pscustomobject]@{Type="Capability";Name=$c.Name}
    }
  }
  $out
}
