param()

# Session execution policy (best-effort)
try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force } catch { }

# Prefetch offline cache
try {
  Import-Module (Join-Path $PSScriptRoot '..\Modules\OfflineCache\OfflineCache.psd1') -Force
  if (Test-Path (Join-Path $PSScriptRoot '..\Config\installer_metadata.json')) {
    $metaPath = (Join-Path $PSScriptRoot '..\Config\installer_metadata.json')
    $pref = Invoke-OfflineCachePrefetch -InstallerMetadataPath $metaPath -WhatIf:$WhatIf
    Write-Host ("[PREFETCH] " + ($pref | ConvertTo-Json -Compress))
  }
} catch { Write-Host ("[PREFETCH][ERROR] " + $_.Exception.Message) }

# Optional signing
try {
  $cfg = Join-Path $PSScriptRoot '..\Config\signing.json'
  if (Test-Path $cfg) {
    $sg = Get-Content -LiteralPath $cfg -Raw | ConvertFrom-Json
    if ($sg.enabled) {
      Import-Module (Join-Path $PSScriptRoot '..\Modules\Signing\Signing.psd1') -Force
      $sig = Invoke-Signing -Thumbprint $sg.thumbprint -WhatIf:$WhatIf
      Write-Host ("[SIGN] " + ($sig | ConvertTo-Json -Compress))
    } else {
      Write-Host "[SIGN] Skipped"
    }
  }
} catch { Write-Host ("[SIGN][ERROR] " + $_.Exception.Message) }

# Release notes
try {
  Import-Module (Join-Path $PSScriptRoot '..\Modules\ReleaseNotes\ReleaseNotes.psd1') -Force
  $rn = New-ReleaseNotes
  Write-Host ("[RELEASE] " + $rn)
} catch { Write-Host ("[RELEASE][ERROR] " + $_.Exception.Message) }
