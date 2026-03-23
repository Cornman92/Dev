function Apply-Apps($desired) {
  foreach ($app in $desired.appsEnabled.PSObject.Properties) {
    if ($app.Value) {
      winget install --id $app.Name --exact --silent --accept-package-agreements --accept-source-agreements
    }
  }
}

function Restore-AppsFromSnapshot($apps) {
  $current = winget list | Out-String
  foreach ($a in $apps) {
    if ($current -notmatch $a.Name) {
      winget install --id $a.Id --exact --silent --accept-package-agreements --accept-source-agreements
    }
  }
}
