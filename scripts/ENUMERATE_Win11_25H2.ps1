#Requires -RunAsAdministrator
$Root = "C:\Scripts"
$OutDir = Join-Path $Root "Enumerate"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
#Requires -RunAsAdministrator
$Root = "C:\Scripts"
$OutDir = Join-Path $Root "Enumerate"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"

Start-Transcript -Path (Join-Path $OutDir "ENUMERATE_$Stamp.log") -Force

# --- Optional Features (Windows Features) ---
# Get-WindowsOptionalFeature lists optional features in the running OS. [1](https://msendpointmgr.com/2022/06/27/remove-built-in-windows-11-apps-leveraging-a-cloud-sourced-reference-file/)
$features = Get-WindowsOptionalFeature -Online |
    Select-Object FeatureName, State |
    Sort-Object FeatureName

$features | Export-Csv (Join-Path $OutDir "OptionalFeatures_$Stamp.csv") -NoTypeInformation
$features | Format-Table -AutoSize | Out-File (Join-Path $OutDir "OptionalFeatures_$Stamp.txt")

# --- Capabilities (Features on Demand) ---
$caps = Get-WindowsCapability -Online |
    Select-Object Name, State, DisplayName |
    Sort-Object Name

$caps | Export-Csv (Join-Path $OutDir "Capabilities_$Stamp.csv") -NoTypeInformation
$caps | Format-Table -AutoSize | Out-File (Join-Path $OutDir "Capabilities_$Stamp.txt")

# --- Provisioned AppX packages (applies to NEW profiles) ---
$prov = Get-AppxProvisionedPackage -Online |
    Select-Object DisplayName, PackageName, Version |
    Sort-Object DisplayName

$prov | Export-Csv (Join-Path $OutDir "ProvisionedAppx_$Stamp.csv") -NoTypeInformation
$prov | Format-Table -AutoSize | Out-File (Join-Path $OutDir "ProvisionedAppx_$Stamp.txt")

# --- Installed AppX packages (existing users; -AllUsers view) ---
$appx = Get-AppxPackage -AllUsers |
    Select-Object Name, PackageFullName, PackageFamilyName |
    Sort-Object Name

$appx | Export-Csv (Join-Path $OutDir "InstalledAppx_AllUsers_$Stamp.csv") -NoTypeInformation
$appx | Format-Table -AutoSize | Out-File (Join-Path $OutDir "InstalledAppx_AllUsers_$Stamp.txt")

Stop-Transcript

Write-Host "Done. Output in: $OutDir" -ForegroundColor Cyan