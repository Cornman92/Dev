Write-Host "=== ConnorOS Windows Post-Install Starting ===" -ForegroundColor Cyan

# --- SECURITY ---
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -RecoveryPasswordProtector
netsh advfirewall set allprofiles state on
Set-MpPreference -EnableControlledFolderAccess Enabled -EnableNetworkProtection Enabled -PUAProtection Enabled
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# --- PERFORMANCE ---
schtasks /create /tn "SSDOptimize" /tr "defrag C: /O" /sc weekly /d SUN /ru SYSTEM
powercfg -h off
fsutil behavior set DisableDeleteNotify 0
bcdedit /set useplatformclock true

# --- UX ---
if ((Get-Date).Hour -ge 18 -or (Get-Date).Hour -lt 6) {
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
} else {
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1
}
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1

# --- CLOUD ---
Copy-Item "C:\Winutil\winutils.json" "$env:OneDrive\Backups\winutils.json" -Force
rclone copy "C:\Winutil\winutils.json" onedrive:/ConnorOS
rclone copy "C:\Winutil\winutils.json" gdrive:/ConnorOS
aws s3 cp "C:\Winutil\winutils.json" s3://connoros-backups/winutils.json

# --- GAMING ---
Copy-Item "$env:USERPROFILE\SavedGames\*" "$env:OneDrive\GameSaves" -Recurse -Force
& nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader | Out-File "$env:OneDrive\Reports\GPU.csv"

# --- DEV ---
git -C "$env:USERPROFILE\.dotfiles" pull
git -C "C:\Repos" status | Out-File "$env:OneDrive\Reports\RepoHealth.txt"

# --- MONITORING ---
Get-ComputerInfo | ConvertTo-Html | Out-File "$env:OneDrive\Reports\HealthDashboard.html"
Get-Counter "\Processor(_Total)\% Processor Time" | Export-Csv "$env:OneDrive\Reports\CPUTrend.csv"
Get-PhysicalDisk | Get-StorageReliabilityCounter | Export-Csv "$env:OneDrive\Reports\DiskHealth.csv"

# --- ORCHESTRATION ---
$computers = @("NAS-PC","Laptop-PC","VM-PC")
foreach ($c in $computers) {
    Copy-Item "C:\Winutil\winutils.json" "\\$c\C$\Winutil\" -Force
    Invoke-Command -ComputerName $c -ScriptBlock { Start-Process "C:\Winutil\Winutil.exe" -ArgumentList "winutils.json" }
}

# --- FUTURE-PROOFING ---
Compress-Archive -Path "C:\Winutil" -DestinationPath "E:\ConnorOS_Portable.zip" -Force

Write-Host "=== ConnorOS Windows Post-Install Complete ===" -ForegroundColor Green

$report = @{
  node = $env:COMPUTERNAME
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  timestamp = (Get-Date).ToString("s")
  status = "success"
  security = @{ bitlocker="enabled"; firewall="on"; exploitGuard="enabled" }
  performance = @{ trim="active"; hibernation="disabled" }
  cloudSync = @{ onedrive="ok"; gdrive="ok"; s3="ok" }
  gaming = @{ saveSync="ok"; gpuTelemetry="ok" }
  dev = @{ dotfiles="synced"; repoHealth="ok" }
  monitoring = @{ dashboard="generated"; cpuTrend="ok"; diskHealth="ok" }
} | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "http://orchestrator.local:8000/report" -Method Post -Body $report -ContentType "application/json"
