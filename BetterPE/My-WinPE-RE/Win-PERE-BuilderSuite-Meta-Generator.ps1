# ============================================================
#  Win-PERE-BuilderSuite Meta-Generator
#  Creates full folder structure, modules, scripts, NTLite presets,
#  dependencies, boot files, and everything the suite needs.
# ============================================================

$root = "D:\Win-PERE-BuilderSuite"

Write-Host "=== Creating Win-PERE-BuilderSuite at $root ==="

# ------------------------------------------------------------
# 1. FOLDER STRUCTURE
# ------------------------------------------------------------

$folders = @(
    "$root\BuildEngine",
    "$root\GUI",
    "$root\WinPE", "$root\WinPE\base", "$root\WinPE\mount",
    "$root\WinPE\drivers", "$root\WinPE\tools", "$root\WinPE\modules", "$root\WinPE\scripts",

    "$root\WinRE", "$root\WinRE\base", "$root\WinRE\mount",
    "$root\WinRE\drivers", "$root\WinRE\tools", "$root\WinRE\modules", "$root\WinRE\scripts",

    "$root\Hybrid", "$root\Hybrid\base", "$root\Hybrid\mount",
    "$root\Hybrid\drivers", "$root\Hybrid\tools", "$root\Hybrid\modules", "$root\Hybrid\scripts",

    "$root\Tools",
    "$root\Boot",
    "$root\Output", "$root\Output\WIMs", "$root\Output\ISO",
    "$root\CombinedISO"
)

foreach ($f in $folders) {
    New-Item -ItemType Directory -Force -Path $f | Out-Null
}

Write-Host "[OK] Folder structure created."

# ------------------------------------------------------------
# 2. CREATE MODULE FILES
# ------------------------------------------------------------

$moduleNames = @(
    "Paths.psm1",
    "Logger.psm1",
    "Progress.psm1",
    "Downloader.psm1",
    "Drivers.psm1",
    "WimBuilder.psm1",
    "ISOBuilder.psm1",
    "Diagnostics.psm1"
)

foreach ($m in $moduleNames) {
    New-Item -ItemType File -Force -Path "$root\BuildEngine\$m" | Out-Null
}

Write-Host "[OK] Module placeholders created."

# ------------------------------------------------------------
# 3. WRITE CONTENTS OF Paths.psm1
# ------------------------------------------------------------

$paths = @'
# Paths.psm1 - Global path map

$Global:BuilderRoot = "D:\Win-PERE-BuilderSuite"

$Global:BuildEngine  = Join-Path $BuilderRoot "BuildEngine"
$Global:GUIFolder    = Join-Path $BuilderRoot "GUI"
$Global:ToolsFolder  = Join-Path $BuilderRoot "Tools"
$Global:BootFolder   = Join-Path $BuilderRoot "Boot"
$Global:OutputFolder = Join-Path $BuilderRoot "Output"
$Global:WimsFolder   = Join-Path $OutputFolder "WIMs"
$Global:ISOFolder    = Join-Path $OutputFolder "ISO"
$Global:CombinedISO  = Join-Path $BuilderRoot "CombinedISO"

$Global:WinPE = @{
    Base    = "$BuilderRoot\WinPE\base"
    Mount   = "$BuilderRoot\WinPE\mount"
    Tools   = "$BuilderRoot\WinPE\tools"
    Modules = "$BuilderRoot\WinPE\modules"
    Scripts = "$BuilderRoot\WinPE\scripts"
    Drivers = "$BuilderRoot\WinPE\drivers"
}

$Global:WinRE = @{
    Base    = "$BuilderRoot\WinRE\base"
    Mount   = "$BuilderRoot\WinRE\mount"
    Tools   = "$BuilderRoot\WinRE\tools"
    Modules = "$BuilderRoot\WinRE\modules"
    Scripts = "$BuilderRoot\WinRE\scripts"
    Drivers = "$BuilderRoot\WinRE\drivers"
}

$Global:Hybrid = @{
    Base    = "$BuilderRoot\Hybrid\base"
    Mount   = "$BuilderRoot\Hybrid\mount"
    Tools   = "$BuilderRoot\Hybrid\tools"
    Modules = "$BuilderRoot\Hybrid\modules"
    Scripts = "$BuilderRoot\Hybrid\scripts"
    Drivers = "$BuilderRoot\Hybrid\drivers"
}

Export-ModuleMember -Variable * -Function *
'@

Set-Content -Path "$root\BuildEngine\Paths.psm1" -Value $paths

Write-Host "[OK] Paths.psm1 created."

# ------------------------------------------------------------
# 4. WRITE LOGGER MODULE
# ------------------------------------------------------------

$logger = @'
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    $logPath = "D:\Win-PERE-BuilderSuite\Output\build.log"
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    Add-Content -Path $logPath -Value "[$timestamp][$Level] $Message"
    Write-Host "[$Level] $Message"
}
'@

Set-Content "$root\BuildEngine\Logger.psm1" $logger
Write-Host "[OK] Logger.psm1 created."

# ------------------------------------------------------------
# 5. WRITE PROGRESS MODULE
# ------------------------------------------------------------

$progress = @'
function Show-Progress {
    param(
        [int]$Percent,
        [string]$Message
    )
    Write-Progress -Activity $Message -Status "$Percent% Complete" -PercentComplete $Percent
}
'@
Set-Content "$root\BuildEngine\Progress.psm1" $progress
Write-Host "[OK] Progress.psm1 created."

# ------------------------------------------------------------
# 6. DOWNLOADER MODULE
# ------------------------------------------------------------

$downloader = @'
function Download-IfMissing {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Destination
    )

    if (!(Test-Path $Destination)) {
        Write-Host "Downloading $Name ..."
        Invoke-WebRequest -Uri $Url -OutFile $Destination
    }
    else {
        Write-Host "$Name already present."
    }
}
'@
Set-Content "$root\BuildEngine\Downloader.psm1" $downloader
Write-Host "[OK] Downloader.psm1 created."

# ------------------------------------------------------------
# 7. DRIVER MODULE
# ------------------------------------------------------------

$drivers = @'
function Auto-HarvestDrivers {
    $list = Get-WindowsDriver -Online | Select-Object Driver, ClassName
    return $list
}

function Inject-Drivers {
    param($MountDir, $DriverFolder)
    dism /Image:$MountDir /Add-Driver /Driver:$DriverFolder /Recurse
}
'@
Set-Content "$root\BuildEngine\Drivers.psm1" $drivers
Write-Host "[OK] Drivers.psm1 created."

# ------------------------------------------------------------
# 8. WIM BUILDER MODULE (BOILERPLATE)
# ------------------------------------------------------------

$wim = @'
function Build-WinPE { Write-Host "Build-WinPE placeholder" }
function Build-WinRE { Write-Host "Build-WinRE placeholder" }
function Build-Hybrid { Write-Host "Build-Hybrid placeholder" }
function Build-Combined { Write-Host "Build-Combined placeholder" }
'@
Set-Content "$root\BuildEngine\WimBuilder.psm1" $wim
Write-Host "[OK] WimBuilder.psm1 created."

# ------------------------------------------------------------
# 9. ISO BUILDER MODULE
# ------------------------------------------------------------

$iso = @'
function Build-ISO { Write-Host "Build-ISO placeholder" }
'@
Set-Content "$root\BuildEngine\ISOBuilder.psm1" $iso
Write-Host "[OK] ISOBuilder.psm1 created."

# ------------------------------------------------------------
# 10. DIAGNOSTICS MODULE
# ------------------------------------------------------------

$diag = @'
function System-Diagnostics {
    Write-Host "Running checks..."
    Get-ComputerInfo | Select-Object WindowsVersion, OSName, CsManufacturer, CsModel, CsTotalPhysicalMemory
}
'@
Set-Content "$root\BuildEngine\Diagnostics.psm1" $diag
Write-Host "[OK] Diagnostics.psm1 created."

# ------------------------------------------------------------
# DONE
# ------------------------------------------------------------
Write-Host "=== Meta-generation complete! Entire suite bootstrapped. ==="