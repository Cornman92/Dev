# ConnorOS-PostInstall.ps1
Write-Host "=== ConnorOS Windows Post-Install Starting ===" -ForegroundColor Cyan

# --- SECURITY ---
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -RecoveryPasswordProtector
netsh advfirewall set allprofiles state on
Set-MpPreference -EnableControlledFolderAccess Enabled -EnableNetworkProtection Enabled -PUAProtection Enabled
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# --- PERFORMANCE: Self-benchmarking & dynamic tuning ---
# CPU baseline
$cpu = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples[0].CookedValue
# Disk baseline via winsat
winsat disk -drive c | Out-File "$env:ProgramData\ConnorOS\bench_winsat.txt"
# GPU telemetry
$n = (& nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,clocks.current.graphics --format=csv,noheader) 2>$null
New-Item -ItemType Directory -Path "$env:ProgramData\ConnorOS" -Force | Out-Null
"$($cpu),$($n)" | Out-File "$env:ProgramData\ConnorOS\bench.csv"

# Dynamic pagefile tuning based on pressure
$ram = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize/1024
if ($ram -lt 16384) { wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False; wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=4096,MaximumSize=8192 }

# --- HOT PATCHING (maintenance window placeholder) ---
# Staggered maintenance window tag via registry for orchestrator coordination
Set-ItemProperty -Path "HKLM:\Software\ConnorOS" -Name "MaintenanceWindow" -Value "Sun 03:00-04:00"

# --- CHAOS TESTING (canary only) ---
if ($env:CONNOR_ROLE -eq "canary") {
  # Simulate disk pressure safely
  $tmp = "$env:ProgramData\ConnorOS\chaos.tmp"; fsutil file createnew $tmp 104857600; Remove-Item $tmp
}

# --- UX: Context-aware themes & prompts ---
if ((Get-Date).Hour -ge 18 -or (Get-Date).Hour -lt 6) {
  Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
} else {
  Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1
}
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1

# --- CLOUD & INTEGRATIONS ---
Copy-Item "C:\Winutil\winutils.json" "$env:OneDrive\Backups\winutils.json" -Force
rclone copy "C:\Winutil\winutils.json" onedrive:/ConnorOS
rclone copy "C:\Winutil\winutils.json" gdrive:/ConnorOS
aws s3 cp "C:\Winutil\winutils.json" s3://connoros-backups/winutils.json

# Webhook triggers (sample)
Invoke-RestMethod -Uri "https://ci.example/build" -Method Post -Body '{"event":"profile_applied","node":"'$env:COMPUTERNAME'"}' -ContentType "application/json" 2>$null

# Home automation: gaming mode dim via MQTT (requires mosquitto-clients)
if ($env:CONNOR_MODE -eq "gaming") { & mosquitto_pub -h home.local -t "connoros/gaming" -m "on" }

# --- AI assistants (local) ---
# Summarize last logs via local Ollama
try {
  $prompt = '{"model":"llama2","prompt":"Summarize ConnorOS Windows post-install logs briefly."}'
  Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $prompt -ContentType "application/json" | Out-File "$env:OneDrive\Reports\AI_Summary.txt"
} catch {}

# --- DEV & GAMING ---
git -C "$env:USERPROFILE\.dotfiles" pull 2>$null
git -C "C:\Repos" status | Out-File "$env:OneDrive\Reports\RepoHealth.txt"
Copy-Item "$env:USERPROFILE\SavedGames\*" "$env:OneDrive\GameSaves" -Recurse -Force 2>$null

# --- MONITORING & REPORTS ---
Get-ComputerInfo | ConvertTo-Html | Out-File "$env:OneDrive\Reports\HealthDashboard.html"
Get-Counter "\Processor(_Total)\% Processor Time" | Export-Csv "$env:OneDrive\Reports\CPUTrend.csv" -NoTypeInformation
Get-PhysicalDisk | Get-StorageReliabilityCounter | Export-Csv "$env:OneDrive\Reports\DiskHealth.csv" -NoTypeInformation

# Synthetic monitoring (app startup timing)
$sw = [System.Diagnostics.Stopwatch]::StartNew(); Start-Process notepad -Wait; $sw.Stop()
"NotepadStartMs,$($sw.ElapsedMilliseconds)" | Out-File "$env:OneDrive\Reports\Synthetic.csv" -Append

# --- ORCHESTRATION: distributed load & blue/green flag ---
Set-ItemProperty -Path "HKLM:\Software\ConnorOS" -Name "ProfileChannel" -Value "Stable"
$computers = @("NAS-PC","Laptop-PC","VM-PC")
foreach ($c in $computers) {
  Copy-Item "C:\Winutil\winutils.json" "\\$c\C$\Winutil\" -Force 2>$null
}

# --- SELF-DOCUMENTING ---
"Applied Windows post-install at $(Get-Date -Format s)" | Out-File "$env:OneDrive\Reports\Changelog.txt" -Append

# --- PACKAGING & DR DRILLS ---
Compress-Archive -Path "C:\Winutil" -DestinationPath "E:\ConnorOS_Portable.zip" -Force
Write-Host "=== ConnorOS Windows Post-Install Complete ===" -ForegroundColor Green
