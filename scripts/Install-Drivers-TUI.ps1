<#
Driver Installer (pnputil) - safe TUI + error handling
Microsoft pnputil return values: 0, 259, 3010, 1641 [4](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-return-values)
#>

[CmdletBinding()]
param(
  [Parameter(Position=0)]
  [string]$DriverRoot = (Get-Location).Path,

  [switch]$NoTUI,
  [switch]$ForceInstall,
  [switch]$DryRun,

  [string]$LogPath = (Join-Path $env:TEMP ("DriverInstall_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss")))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -------------------- Logging --------------------
function Write-Log {
  param(
    [Parameter(Mandatory)][string]$Message,
    [ValidateSet('INFO','WARN','ERROR','DEBUG')][string]$Level = 'INFO'
  )
  $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
  Add-Content -LiteralPath $LogPath -Value $line
}

# -------------------- Admin check --------------------
function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = [Security.Principal.WindowsPrincipal]::new($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# -------------------- pnputil wrapper --------------------
function Invoke-PnpUtil {
  param([Parameter(Mandatory)][string[]]$Args)

  $exe = (Get-Command pnputil.exe -ErrorAction Stop).Source
  $pretty = ($Args | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
  Write-Log "Running: pnputil $pretty" 'DEBUG'

  $output = & $exe @Args 2>&1 | Out-String
  $code = $LASTEXITCODE

  Write-Log ("ExitCode={0} Output={1}" -f $code, ($output -replace "\s+$","")) 'DEBUG'

  [pscustomobject]@{ ExitCode=$code; Output=$output; Args=$pretty }
}

function Get-PnpUtilOutcome {
  param([int]$ExitCode, [string]$Output)

  # Microsoft documented values [4](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-return-values)
  switch ($ExitCode) {
    0     { [pscustomobject]@{Status='Success'; RebootRequired=$false; NotApplicable=$false; Message='Success'} }
    259   { [pscustomobject]@{Status='NotApplicable'; RebootRequired=$false; NotApplicable=$true; Message='No matching devices or already using a better/newer driver'} } # [4](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-return-values)
    3010  { [pscustomobject]@{Status='Success'; RebootRequired=$true; NotApplicable=$false; Message='Success; reboot required'} } # [4](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-return-values)
    1641  { [pscustomobject]@{Status='Success'; RebootRequired=$true; NotApplicable=$false; Message='Success; reboot initiated'} } # [4](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-return-values)
    default {
      $line = ($Output -split "\r?\n" | Where-Object { $_ -match '(?i)failed|error|denied|cannot|blocked|unsigned|exception|corrupt|mismatch' } | Select-Object -First 1)
      if (-not $line) { $line = "pnputil failed with exit code $ExitCode" }
      [pscustomobject]@{Status='Failed'; RebootRequired=$false; NotApplicable=$false; Message=$line.Trim()}
    }
  }
}

function Invoke-PnpUtilChecked {
  param([Parameter(Mandatory)][string[]]$Args, [string]$Context='pnputil')
  $res = Invoke-PnpUtil -Args $Args
  $out = Get-PnpUtilOutcome -ExitCode $res.ExitCode -Output $res.Output
  $lvl = if ($out.Status -eq 'Failed') {'ERROR'} elseif ($out.NotApplicable) {'INFO'} else {'INFO'}
  Write-Log ("{0}: {1} Exit={2} Args={3}" -f $Context, $out.Message, $res.ExitCode, $res.Args) $lvl
  $res | Add-Member -NotePropertyName Outcome -NotePropertyValue $out -Force
  $res
}

# -------------------- Parsing helpers --------------------
function Try-ParseDriverDate {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
  try { return [datetime]::Parse($Text) } catch {}
  foreach ($fmt in @('M/d/yyyy','MM/dd/yyyy','M/d/yy','MM/dd/yy')) {
    try { return [datetime]::ParseExact($Text, $fmt, [System.Globalization.CultureInfo]::InvariantCulture) } catch {}
  }
  return $null
}

function Compare-DriverMeta {
  param($A, $B) # expects DriverDate + DriverVersion (version can be $null)

  if ($A.DriverDate -and $B.DriverDate) {
    if ($A.DriverDate -gt $B.DriverDate) { return 1 }
    if ($A.DriverDate -lt $B.DriverDate) { return -1 }
  } elseif ($A.DriverDate -and -not $B.DriverDate) { return 1 }
  elseif (-not $A.DriverDate -and $B.DriverDate) { return -1 }

  if ($A.DriverVersion -and $B.DriverVersion) {
    if ($A.DriverVersion -gt $B.DriverVersion) { return 1 }
    if ($A.DriverVersion -lt $B.DriverVersion) { return -1 }
  } elseif ($A.DriverVersion -and -not $B.DriverVersion) { return 1 }
  elseif (-not $A.DriverVersion -and $B.DriverVersion) { return -1 }

  return 0
}

# -------------------- Driver store index --------------------
function Get-DriverStoreIndex {
  $res = Invoke-PnpUtilChecked -Args @('/enum-drivers') -Context 'EnumDrivers'
  if ($res.Outcome.Status -eq 'Failed') { throw "pnputil /enum-drivers failed (exit $($res.ExitCode))." }

  $blocks = ($res.Output -split "(\r?\n){2,}") | Where-Object { $_ -match 'Published Name\s*:' }

  $records = foreach ($b in $blocks) {
    $m = @{}
    foreach ($line in ($b -split "\r?\n")) {
      if ($line -match "^\s*([^:]+?)\s*:\s*(.*)\s*$") {
        $k = ($matches[1] -replace '\s+',' ').Trim()
        $m[$k] = $matches[2].Trim()
      }
    }

    $verDate = $m['Driver Version And Date']
    $dt = $null; $ver = $null
    if ($verDate -match "^\s*([0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4})\s+(.+?)\s*$") {
      $dt = Try-ParseDriverDate $matches[1]
      try { $ver = [version]$matches[2].Trim() } catch { $ver = $null }
    }

    [pscustomobject]@{
      OriginalName      = $m['Original Name']
      RawVersionAndDate = $verDate
      DriverDate        = $dt
      DriverVersion     = $ver
    }
  }

  $index = @{}
  foreach ($r in $records) {
    if ([string]::IsNullOrWhiteSpace($r.OriginalName)) { continue }
    if (-not $index.ContainsKey($r.OriginalName)) { $index[$r.OriginalName] = $r; continue }
    if (Compare-DriverMeta -A $r -B $index[$r.OriginalName] -gt 0) { $index[$r.OriginalName] = $r }
  }
  $index
}

# -------------------- INF discovery + metadata --------------------
function Get-InfFiles {
  param([Parameter(Mandatory)][string]$Root)
  if (-not (Test-Path -LiteralPath $Root)) { throw "DriverRoot not found: $Root" }
  Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.inf' -ErrorAction Stop | Sort-Object FullName
}

function Get-InfMetadata {
  param([Parameter(Mandatory)][string]$InfPath)

  $file = Split-Path -Leaf $InfPath
  $dt = $null
  $ver = $null

  $lines = Get-Content -LiteralPath $InfPath -ErrorAction Stop
  foreach ($l in $lines) {
    if ($l -match "^\s*DriverVer\s*=\s*([^,]+)\s*,\s*(.+?)\s*$") {
      $dt = Try-ParseDriverDate ($matches[1].Trim())
      try { $ver = [version]($matches[2].Trim()) } catch { $ver = $null }
      break
    }
  }

  [pscustomobject]@{
    Path          = $InfPath
    FileName      = $file
    DriverDate    = $dt
    DriverVersion = $ver
  }
}

function New-InstallPlan {
  param([Parameter(Mandatory)]$InfFiles, [Parameter(Mandatory)][hashtable]$StoreIndex)

  $plan = New-Object System.Collections.Generic.List[object]

  foreach ($inf in $InfFiles) {
    $meta = Get-InfMetadata -InfPath $inf.FullName
    $action = 'Stage'
    $reason = 'Not found in Driver Store'

    if ($StoreIndex.ContainsKey($meta.FileName)) {
      $store = $StoreIndex[$meta.FileName]

      if (-not $meta.DriverDate -and -not $meta.DriverVersion) {
        $action = 'Skip'
        $reason = 'Already present; INF has no DriverVer to compare'
      } else {
        $cmp = Compare-DriverMeta -A $meta -B $store
        if ($cmp -le 0) {
          $action = 'Skip'
          $reason = "Store has same/newer: $($store.RawVersionAndDate)"
        } else {
          $action = 'Stage'
          $reason = "Newer than store: INF=$($meta.DriverDate) $($meta.DriverVersion)"
        }
      }
    }

    $plan.Add([pscustomobject]@{
      InfPath    = $meta.Path
      InfName    = $meta.FileName
      Action     = $action
      Reason     = $reason
    })
  }

  $plan
}

function Execute-Plan {
  param(
    [Parameter(Mandatory)]$Plan,
    [switch]$ForceInstallMode,
    [switch]$DryRunMode
  )

  $reboot = $false
  $failed = 0
  $skipped = 0
  $staged = 0
  $lastError = $null

  $total = $Plan.Count
  for ($i=0; $i -lt $total; $i++) {
    $item = $Plan[$i]
    $pct = [math]::Floor((($i+1)/[double]$total)*100)

    Write-Host ("[{0,3}%] ({1}/{2}) {3} -> {4}" -f $pct, ($i+1), $total, $item.InfName, $item.Action)

    if ($item.Action -eq 'Skip') { $skipped++; continue }
    if ($DryRunMode) { $staged++; continue }

    $args = @('/add-driver', $item.InfPath)
    if ($ForceInstallMode) { $args += '/install' }

    $res = Invoke-PnpUtilChecked -Args $args -Context ("AddDriver {0}" -f $item.InfName)

    if ($res.Outcome.Status -eq 'Success') {
      $staged++
      if ($res.Outcome.RebootRequired) { $reboot = $true }
    } elseif ($res.Outcome.NotApplicable) {
      $skipped++
    } else {
      $failed++
      $lastError = $res.Outcome.Message
      Write-Log "Troubleshoot: see %windir%\inf\setupapi.dev.log" 'WARN'
    }
  }

  $scan = $null
  if (-not $DryRunMode -and -not $ForceInstallMode) {
    $scan = Invoke-PnpUtilChecked -Args @('/scan-devices') -Context 'ScanDevices'
    if ($scan.Outcome.RebootRequired) { $reboot = $true }
    if ($scan.Outcome.Status -eq 'Failed') { $lastError = $scan.Outcome.Message }
  }

  [pscustomobject]@{
    Total=$total; Staged=$staged; Skipped=$skipped; Failed=$failed;
    RebootRequired=$reboot; LastError=$lastError; Scan=$scan
  }
}

# -------------------- Menu TUI --------------------
function Run-Menu {
  while ($true) {
    Clear-Host
    Write-Host "Driver Installer (pnputil)" -ForegroundColor Cyan
    Write-Host ("DriverRoot: {0}" -f $DriverRoot) -ForegroundColor DarkGray
    Write-Host ("Log:       {0}" -f $LogPath) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "1) Set Driver Folder"
    Write-Host "2) Analyze (build plan)"
    Write-Host "3) Run recommended (stage + scan-devices)"
    Write-Host "4) Run force install (stages + installs each INF)"
    Write-Host "5) Dry run"
    Write-Host "6) Exit"
    Write-Host ""
    $c = Read-Host "Choose 1-6"

    switch ($c) {
      '1' {
        $p = Read-Host "Enter path"
        if (-not [string]::IsNullOrWhiteSpace($p)) {
          $r = Resolve-Path -LiteralPath $p -ErrorAction SilentlyContinue
          if ($r) { $script:DriverRoot = $r.Path }
        }
      }
      '2' {
        $store = Get-DriverStoreIndex
        $infs  = @(Get-InfFiles -Root $script:DriverRoot)
        $plan  = New-InstallPlan -InfFiles $infs -StoreIndex $store
        $s = ($plan | Where-Object Action -eq 'Stage').Count
        $k = ($plan | Where-Object Action -eq 'Skip').Count
        Clear-Host
        Write-Host ("Total INFs: {0}  Stage: {1}  Skip: {2}" -f $plan.Count, $s, $k) -ForegroundColor Cyan
        Write-Host ""
        $plan | Select-Object -First 25 InfName, Action, Reason | Format-Table -AutoSize
        Read-Host "Enter to continue" | Out-Null
      }
      '3' {
        $store = Get-DriverStoreIndex
        $infs  = @(Get-InfFiles -Root $script:DriverRoot)
        $plan  = New-InstallPlan -InfFiles $infs -StoreIndex $store
        $result = Execute-Plan -Plan $plan
        Write-Host ""
        Write-Host ("Done. Staged={0} Skipped={1} Failed={2}" -f $result.Staged, $result.Skipped, $result.Failed) -ForegroundColor Cyan
        if ($result.RebootRequired) { Write-Host "Reboot required." -ForegroundColor Yellow }
        if ($result.LastError) { Write-Host ("Last error: {0}" -f $result.LastError) -ForegroundColor Red }
        Read-Host "Enter to continue" | Out-Null
      }
      '4' {
        $store = Get-DriverStoreIndex
        $infs  = @(Get-InfFiles -Root $script:DriverRoot)
        $plan  = New-InstallPlan -InfFiles $infs -StoreIndex $store
        $result = Execute-Plan -Plan $plan -ForceInstallMode
        Write-Host ""
        Write-Host ("Done. Staged={0} Skipped={1} Failed={2}" -f $result.Staged, $result.Skipped, $result.Failed) -ForegroundColor Cyan
        if ($result.RebootRequired) { Write-Host "Reboot required." -ForegroundColor Yellow }
        if ($result.LastError) { Write-Host ("Last error: {0}" -f $result.LastError) -ForegroundColor Red }
        Read-Host "Enter to continue" | Out-Null
      }
      '5' {
        $store = Get-DriverStoreIndex
        $infs  = @(Get-InfFiles -Root $script:DriverRoot)
        $plan  = New-InstallPlan -InfFiles $infs -StoreIndex $store
        $result = Execute-Plan -Plan $plan -DryRunMode
        Write-Host ""
        Write-Host ("Dry run. Would Stage={0} Would Skip={1}" -f $result.Staged, $result.Skipped) -ForegroundColor Green
        Read-Host "Enter to continue" | Out-Null
      }
      '6' { return }
      default { }
    }
  }
}

# -------------------- Main --------------------
try {
  Write-Log "=== Start ==="
  if (-not (Test-IsAdmin)) { throw "Run as Administrator." }

  # Validate pnputil exists
  $null = Get-Command pnputil.exe -ErrorAction Stop

  if ($NoTUI) {
    $store = Get-DriverStoreIndex
    $infs  = @(Get-InfFiles -Root $script:DriverRoot)
    $plan  = New-InstallPlan -InfFiles $infs -StoreIndex $store
    $result = Execute-Plan -Plan $plan -ForceInstallMode:$ForceInstall -DryRunMode:$DryRun

    Write-Host ("Result: Total={0} Staged={1} Skipped={2} Failed={3}" -f $result.Total, $result.Staged, $result.Skipped, $result.Failed) -ForegroundColor Cyan
    if ($result.RebootRequired) { exit 3010 }  # success + reboot required [4](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-return-values)
    if ($result.Failed -gt 0) { exit 1 }
    exit 0
  } else {
    Run-Menu
  }

  Write-Log "=== End ==="
}
catch {
  Write-Host ("ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
  Write-Log ("Unhandled error: {0}" -f $_.Exception.ToString()) 'ERROR'
  exit 1
}