#Requires -RunAsAdministrator
<#
Windows 11 25H2: Generates an APPLY script that contains ALL Optional Feature names
as a literal array ($FeatureNames). Delete entries you don't want, then run APPLY script.
#>

$OutDir = "C:\Scripts"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$apply = Join-Path $OutDir "APPLY_25H2_EnableSelectedFeatures_$stamp.ps1"

# Enumerate all optional features on this machine
$features = Get-WindowsOptionalFeature -Online | Sort-Object FeatureName  # [1](https://learn.microsoft.com/en-us/powershell/module/dism/get-windowsoptionalfeature?view=windowsserver2025-ps)

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine("#Requires -RunAsAdministrator")
$null = $sb.AppendLine("<#")
$null = $sb.AppendLine("APPLY script generated: $((Get-Date).ToString('u'))")
$null = $sb.AppendLine("Edit `$FeatureNames and remove entries you don't want enabled.")
$null = $sb.AppendLine("#>")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("[CmdletBinding(SupportsShouldProcess=`$true, ConfirmImpact='High')]")
$null = $sb.AppendLine("param()")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("`$FeatureNames = @(")

foreach ($f in $features) {
    $name = $f.FeatureName.Replace("'", "''")
    $null = $sb.AppendLine("    '$name',")
}

$null = $sb.AppendLine(")")
$null = $sb.AppendLine("")
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
$null = $sb.AppendLine("Write-Host `"Done. Some features may require reboot.`" -ForegroundColor Yellow")

Set-Content -Path $apply -Value $sb.ToString() -Encoding UTF8
Write-Host "Generated APPLY script: $apply" -ForegroundColor Cyan
Write-Host "Edit it (delete feature names you don't want), then run it with -WhatIf first." -ForegroundColor Cyan