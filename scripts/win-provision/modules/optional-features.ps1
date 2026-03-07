function Apply-OptionalFeatures($desired) {
  foreach ($f in $desired.optionalFeatures.PSObject.Properties) {
    if ($f.Value) {
      Enable-WindowsOptionalFeature -Online -FeatureName $f.Name -All -NoRestart
    }
  }
}

function Restore-OptionalFeaturesFromSnapshot($snapshot) {
  foreach ($f in $snapshot) {
    if ($f.State -eq "Enabled") {
      Enable-WindowsOptionalFeature -Online -FeatureName $f.FeatureName -All -NoRestart
    } else {
      Disable-WindowsOptionalFeature -Online -FeatureName $f.FeatureName -NoRestart
    }
  }
}
