function Apply-Capabilities($desired) {
  foreach ($c in $desired.capabilities.PSObject.Properties) {
    if ($c.Value) {
      Add-WindowsCapability -Online -Name $c.Name -ErrorAction SilentlyContinue
    }
  }
}

function Restore-CapabilitiesFromSnapshot($snapshot) {
  foreach ($c in $snapshot) {
    if ($c.State -eq "Installed") {
      Add-WindowsCapability -Online -Name $c.Name -ErrorAction SilentlyContinue
    } else {
      Remove-WindowsCapability -Online -Name $c.Name -ErrorAction SilentlyContinue
    }
  }
}
