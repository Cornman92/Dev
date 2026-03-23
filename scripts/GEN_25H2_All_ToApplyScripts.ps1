#Requires -RunAsAdministrator
<#
Windows 11 25H2 Unified Generator

Generates 3 APPLY scripts you can edit by deleting entries:
  1) APPLY_EnableSelectedFeatures.ps1      (Optional Features)
  2) APPLY_InstallSelectedCapabilities.ps1 (Capabilities / FoD)
  3) APPLY_ProvisionSelectedPackages.ps1   (AppX/MSIX provisioning from a folder)

Fixes trailing comma issue by writing arrays without a trailing comma.

USAGE EXAMPLES:
  # Just generate features + capabilities (no packages):
  .\GEN_25H2_All_ToApplyScripts.ps1

  # Include packages found under D:\Apps:
  .\GEN_25H2_All_ToApplyScripts.ps1 -PackageRoot "D:\Apps"

  # After editing an APPLY script, test safely:
  .\APPLY_EnableSelectedFeatures.ps1 -WhatIf
#>

[CmdletBinding()]
param(
    # Optional: folder containing .appx/.appxbundle/.msix/.msixbundle you want to provision
    [string]$PackageRoot,

    # Where to drop output
    [string]$BaseOutDir = "C:\Scripts\25H2_Generated"
)

function New-OutputFolder {
    param([string]$BaseOutDir)
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outDir = Join-Path $BaseOutDir $stamp
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    return $outDir
}

function Write-ArrayNoTrailingComma {
    param(
        [System.Text.StringBuilder]$Sb,
        [string]$VarName,
        [string[]]$Items
    )
    $null = $Sb.AppendLine("`$$VarName = @(")
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $safe = $Items[$i].Replace("'", "''")
        if ($i -lt ($Items.Count - 1)) {
            $null = $Sb.AppendLine("    '$safe',")
        } else {
            $null = $Sb.AppendLine("    '$safe'")
        }
    }
    $null = $Sb.AppendLine(")")
    $null = $Sb.AppendLine("")
}

function Generate-ApplyFeatures {
    param([string]$OutDir)

    $applyPath = Join-Path $OutDir "APPLY_EnableSelectedFeatures.ps1"

    # Enumerate optional features on the running OS (authoritative list). [1](https://msendpointmgr.com/2022/06/27/remove-built-in-windows-11-apps-leveraging-a-cloud-sourced-reference-file/)
    $features = Get-WindowsOptionalFeature -Online | Sort-Object FeatureName | Select-Object -ExpandProperty FeatureName

    $sb = New-Object System.Text.StringBuilder
    $null = $sb.AppendLine("#Requires -RunAsAdministrator")
    $null = $sb.AppendLine("<#")
    $null = $sb.AppendLine("APPLY: Enable selected Optional Features (generated $(Get-Date -Format u))")
    $null = $sb.AppendLine("Edit `$FeatureNames and delete entries you DO NOT want enabled.")
    $null = $sb.AppendLine("#>")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("[CmdletBinding(SupportsShouldProcess=`$true, ConfirmImpact='High')]")
    $null = $sb.AppendLine("param()")
    $null = $sb.AppendLine("")

    Write-ArrayNoTrailingComma -Sb $sb -VarName "FeatureNames" -Items $features

    $null = $sb.AppendLine("foreach (`$name in `$FeatureNames) {")
    $null = $sb.AppendLine("    if (`$PSCmdlet.ShouldProcess(`"OptionalFeature: `$name`", `"Enable`")) {")
    $null = $sb.AppendLine("        try {")
    $null = $sb.AppendLine("            Enable-WindowsOptionalFeature -Online -FeatureName `$name -All -NoRestart -ErrorAction Stop | Out-Null")
    $null = $sb.AppendLine("            Write-Host `"Enabled: `$name`" -ForegroundColor Green")
    $null = $sb.AppendLine("        } catch {")
    $null = $sb.AppendLine("            Write-Warning `"FAILED enabling `$name : `$(`$_.Exception.Message)`"")
    $null = $sb.AppendLine("        }")
    $null = $sb.AppendLine("    }")
    $null = $sb.AppendLine("}")
    $null = $sb.AppendLine("Write-Host `"Done. Some features may require a reboot.`" -ForegroundColor Yellow")

    Set-Content -Path $applyPath -Value $sb.ToString() -Encoding UTF8
    return $applyPath
}

function Generate-ApplyCapabilities {
    param([string]$OutDir)

    $applyPath = Join-Path $OutDir "APPLY_InstallSelectedCapabilities.ps1"

    # Enumerate all capabilities on the running OS; install uses Add-WindowsCapability. [2](https://www.pdq.com/powershell/add-windowscapability/)[3](https://man.hubwiz.com/docset/Powershell.docset/Contents/Resources/Documents/docs.microsoft.com/en-us/powershell/module/dism/add-windowscapability.html)
    $caps = Get-WindowsCapability -Online | Sort-Object Name | Select-Object -ExpandProperty Name

    $sb = New-Object System.Text.StringBuilder
    $null = $sb.AppendLine("#Requires -RunAsAdministrator")
    $null = $sb.AppendLine("<#")
    $null = $sb.AppendLine("APPLY: Install selected Capabilities (generated $(Get-Date -Format u))")
    $null = $sb.AppendLine("Edit `$CapabilityNames and delete entries you DO NOT want installed.")
    $null = $sb.AppendLine("Supports -Source and -LimitAccess for local FoD media. [2](https://www.pdq.com/powershell/add-windowscapability/)[3](https://man.hubwiz.com/docset/Powershell.docset/Contents/Resources/Documents/docs.microsoft.com/en-us/powershell/module/dism/add-windowscapability.html)")
    $null = $sb.AppendLine("#>")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("[CmdletBinding(SupportsShouldProcess=`$true, ConfirmImpact='High')]")
    $null = $sb.AppendLine("param(")
    $null = $sb.AppendLine("    [string[]]`$Source,")
    $null = $sb.AppendLine("    [switch]`$LimitAccess")
    $null = $sb.AppendLine(")")
    $null = $sb.AppendLine("")

    Write-ArrayNoTrailingComma -Sb $sb -VarName "CapabilityNames" -Items $caps

    $null = $sb.AppendLine("foreach (`$name in `$CapabilityNames) {")
    $null = $sb.AppendLine("    if (`$PSCmdlet.ShouldProcess(`"Capability: `$name`", `"Add-WindowsCapability`")) {")
    $null = $sb.AppendLine("        try {")
    $null = $sb.AppendLine("            `$p = @{ Online = `$true; Name = `$name; ErrorAction = 'Stop' }")
    $null = $sb.AppendLine("            if (`$Source) { `$p.Source = `$Source }")
    $null = $sb.AppendLine("            if (`$LimitAccess) { `$p.LimitAccess = `$true }")
    $null = $sb.AppendLine("            Add-WindowsCapability @p | Out-Null")
    $null = $sb.AppendLine("            Write-Host `"Installed/Ensured: `$name`" -ForegroundColor Green")
    $null = $sb.AppendLine("        } catch {")
    $null = $sb.AppendLine("            Write-Warning `"FAILED installing `$name : `$(`$_.Exception.Message)`"")
    $null = $sb.AppendLine("        }")
    $null = $sb.AppendLine("    }")
    $null = $sb.AppendLine("}")
    $null = $sb.AppendLine("Write-Host `"Done. Some capabilities may require a reboot.`" -ForegroundColor Yellow")

    Set-Content -Path $applyPath -Value $sb.ToString() -Encoding UTF8
    return $applyPath
}

function Generate-ApplyPackages {
    param([string]$OutDir, [string]$PackageRoot)

    $applyPath = Join-Path $OutDir "APPLY_ProvisionSelectedPackages.ps1"

    if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
        # If no root specified, create a stub script explaining usage
        @"
#Requires -RunAsAdministrator
<#
APPLY: Provision selected AppX/MSIX packages for NEW users.

This script was generated, but no -PackageRoot was provided to the generator.
Re-run the generator like:
  .\GEN_25H2_All_ToApplyScripts.ps1 -PackageRoot "D:\Apps"
#>
Write-Host "No PackageRoot was provided at generation time. Re-run generator with -PackageRoot." -ForegroundColor Yellow
"@ | Set-Content -Path $applyPath -Encoding UTF8
        return $applyPath
    }

    if (-not (Test-Path $PackageRoot)) {
        throw "PackageRoot not found: $PackageRoot"
    }

    # Provisioning requires package paths; cmdlet is Add-AppxProvisionedPackage. [4](https://shellgeek.com/powershell-disable-windows-optional-features/)[5](https://www.tenforums.com/software-apps/165584-completely-uninstall-provisioned-apps-how-detailed-explanation.html)
    $pkgs = Get-ChildItem -Path $PackageRoot -Recurse -File -Include *.appx,*.appxbundle,*.msix,*.msixbundle |
            Sort-Object FullName | Select-Object -ExpandProperty FullName

    $sb = New-Object System.Text.StringBuilder
    $null = $sb.AppendLine("#Requires -RunAsAdministrator")
    $null = $sb.AppendLine("<#")
    $null = $sb.AppendLine("APPLY: Provision selected AppX/MSIX packages for NEW users (generated $(Get-Date -Format u))")
    $null = $sb.AppendLine("Edit `$PackagePaths and delete entries you DO NOT want provisioned.")
    $null = $sb.AppendLine("Uses Add-AppxProvisionedPackage -Online -PackagePath ... [4](https://shellgeek.com/powershell-disable-windows-optional-features/)[5](https://www.tenforums.com/software-apps/165584-completely-uninstall-provisioned-apps-how-detailed-explanation.html)")
    $null = $sb.AppendLine("#>")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("[CmdletBinding(SupportsShouldProcess=`$true, ConfirmImpact='High')]")
    $null = $sb.AppendLine("param([switch]`$SkipLicense)")
    $null = $sb.AppendLine("")

    Write-ArrayNoTrailingComma -Sb $sb -VarName "PackagePaths" -Items $pkgs

    $null = $sb.AppendLine("foreach (`$pkgPath in `$PackagePaths) {")
    $null = $sb.AppendLine("    if (`$PSCmdlet.ShouldProcess(`"Provision: `$pkgPath`", `"Add-AppxProvisionedPackage`")) {")
    $null = $sb.AppendLine("        try {")
    $null = $sb.AppendLine("            if (`$SkipLicense) {")
    $null = $sb.AppendLine("                Add-AppxProvisionedPackage -Online -PackagePath `$pkgPath -SkipLicense -ErrorAction Stop | Out-Null")
    $null = $sb.AppendLine("            } else {")
    $null = $sb.AppendLine("                Add-AppxProvisionedPackage -Online -PackagePath `$pkgPath -ErrorAction Stop | Out-Null")
    $null = $sb.AppendLine("            }")
    $null = $sb.AppendLine("            Write-Host `"Provisioned: `$pkgPath`" -ForegroundColor Green")
    $null = $sb.AppendLine("        } catch {")
    $null = $sb.AppendLine("            Write-Warning `"FAILED provisioning `$pkgPath : `$(`$_.Exception.Message)`"")
    $null = $sb.AppendLine("        }")
    $null = $sb.AppendLine("    }")
    $null = $sb.AppendLine("}")
    $null = $sb.AppendLine("Write-Host `"Done provisioning packages for new users.`" -ForegroundColor Yellow")

    Set-Content -Path $applyPath -Value $sb.ToString() -Encoding UTF8
    return $applyPath
}

# ---------------- MAIN ----------------
$outDir = New-OutputFolder -BaseOutDir $BaseOutDir

$feat = Generate-ApplyFeatures     -OutDir $outDir
$cap  = Generate-ApplyCapabilities -OutDir $outDir
$pkg  = Generate-ApplyPackages     -OutDir $outDir -PackageRoot $PackageRoot

Write-Host ""
Write-Host "Generated output folder: $outDir" -ForegroundColor Cyan
Write-Host " - $feat" -ForegroundColor Cyan
Write-Host " - $cap"  -ForegroundColor Cyan
Write-Host " - $pkg"  -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host " 1) Edit each APPLY script and delete entries you don't want." -ForegroundColor Yellow
Write-Host " 2) Run APPLY scripts with -WhatIf first to validate." -ForegroundColor Yellow