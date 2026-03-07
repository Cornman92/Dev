<#
.SYNOPSIS
    Customizes Windows Recovery Environment (WinRE) by mounting Winre.wim,
    applying drivers, optional components, toolkit, and other changes.

.DESCRIPTION
    Supports:
      - Online mode: customizes the currently installed system's WinRE
      - Offline mode: customizes a specified WinRE.wim

    Features:
      - Safety checks for DISM, reagentc, mount state, and free space
      - Optional backup of Winre.wim
      - Centralized logging to file + console
      - Controlled commit/discard behavior based on warnings
      - Optional reagentc re-registration in Online mode
#>

[CmdletBinding()]
param(
    [ValidateSet('Online','Offline')]
    [string]$Mode = 'Online',

    [string]$WinREWimPath,           # Required in Offline mode; optional override in Online
    [string]$WorkRoot = 'C:\WinRE_Work',
    [switch]$SkipBackup,
    [switch]$SkipReagentc,           # Only relevant in Online mode
    [switch]$NoCommitOnWarning,      # If set, discard changes when warnings occur
    [string]$ToolkitRoot
)

# ------------------------ GLOBAL SETTINGS ------------------------

$ErrorActionPreference = 'Stop'
$scriptName = 'WinPE-CustomizeWinRE.ps1'
$HasWarnings = $false

# ------------------------ LOGGING SETUP --------------------------

try {
    if (-not (Test-Path $WorkRoot)) {
        New-Item -Path $WorkRoot -ItemType Directory -Force | Out-Null
    }

    $LogDir  = Join-Path $WorkRoot "Logs"
    if (-not (Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }

    $LogPath = Join-Path $LogDir ("WinPE-CustomizeWinRE_{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

    function Write-Log {
        param(
            [string]$Message,
            [ValidateSet('INFO','WARN','ERROR')]
            [string]$Level = 'INFO'
        )

        $timestamp = Get-Date -Format "s"
        $line = "{0} [{1}] {2}" -f $timestamp, $Level, $Message
        Add-Content -Path $LogPath -Value $line

        switch ($Level) {
            'INFO'  { Write-Host    $Message }
            'WARN'  { Write-Warning $Message }
            'ERROR' { Write-Error   $Message }
        }
    }

    Write-Log "=== $scriptName starting (Mode: $Mode) ==="
    Write-Log "Log file: $LogPath"
}
catch {
    Write-Host "FATAL: Failed to initialize logging: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Helper to mark warnings
function Set-WarningFlag {
    param([string]$Message)
    $script:HasWarnings = $true
    Write-Log -Message $Message -Level 'WARN'
}

# ------------------------ TOOL PRESENCE CHECK --------------------

try {
    foreach ($tool in @('dism.exe')) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Log -Message "$tool not found in PATH. Cannot continue." -Level 'ERROR'
            throw "$tool missing"
        }
    }

    if ($Mode -eq 'Online' -and -not $SkipReagentc) {
        if (-not (Get-Command 'reagentc.exe' -ErrorAction SilentlyContinue)) {
            Set-WarningFlag "reagentc.exe not found in PATH. WinRE will not be re-registered automatically."
            $SkipReagentc = $true
        }
    }
}
catch {
    Write-Log -Message "Tool presence check failed: $($_.Exception.Message)" -Level 'ERROR'
    exit 1
}

# ------------------------ WORK FOLDERS ---------------------------

try {
    $MountDir  = Join-Path $WorkRoot 'Mount'
    $BackupDir = Join-Path $WorkRoot 'Backup'
    $TempDir   = Join-Path $WorkRoot 'Temp'

    foreach ($dir in @($MountDir, $BackupDir, $TempDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }

    # Free space check
    $drive = (Get-Item $WorkRoot).PSDrive
    if ($drive.Free -lt 5GB) {
        Set-WarningFlag "Less than 5 GB free on drive $($drive.Name):. WinRE customization may fail."
    }
}
catch {
    Write-Log -Message "Failed to prepare work folders: $($_.Exception.Message)" -Level 'ERROR'
    exit 1
}

# ------------------------ TOOLKIT ROOT RESOLUTION ----------------

try {
    if (-not $ToolkitRoot) {
        $scriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Definition
        $ToolkitRoot = Split-Path -Parent $scriptRoot
        Write-Log "Auto-detected Toolkit root: $ToolkitRoot"
    } else {
        Write-Log "Using specified Toolkit root: $ToolkitRoot"
    }

    if (-not (Test-Path $ToolkitRoot)) {
        Write-Log -Message "Toolkit root not found: $ToolkitRoot" -Level 'ERROR'
        throw "ToolkitRoot missing"
    }
}
catch {
    Write-Log -Message "Toolkit root resolution failed: $($_.Exception.Message)" -Level 'ERROR'
    exit 1
}

# ------------------------ RESOLVE WinRE SOURCE -------------------

$resolvedWinREWim = $null

try {
    if ($Mode -eq 'Online' -and -not $WinREWimPath) {
        Write-Log "Resolving WinRE location using reagentc /info (online mode)..."

        $reagentInfo = reagentc /info 2>&1
        if ($LASTEXITCODE -ne 0) {
            Set-WarningFlag "reagentc /info failed (Exit code: $LASTEXITCODE). Output: $reagentInfo"
            throw "Cannot resolve WinRE automatically"
        }

        $reLine = $reagentInfo | Select-String -Pattern 'Windows RE location'
        if (-not $reLine) {
            throw "Could not find 'Windows RE location' in reagentc /info output."
        }

        $rePath = $reLine.ToString().Split(':', 2)[1].Trim()
        if (-not $rePath) {
            throw "Parsed Windows RE location is empty."
        }

        Write-Log "Raw Windows RE location: $rePath"
        $resolvedWinREWim = Join-Path $rePath "Winre.wim"
        Write-Log "Assuming WinRE WIM path: $resolvedWinREWim"
    }
    elseif ($Mode -eq 'Offline') {
        if (-not $WinREWimPath) {
            Write-Log -Message "Offline mode requires -WinREWimPath." -Level 'ERROR'
            throw "Missing WinREWimPath in Offline mode"
        }
        $resolvedWinREWim = $WinREWimPath
        Write-Log "Offline mode: using provided WinRE WIM path: $resolvedWinREWim"
    }
    else {
        # Online mode with explicit WinREWimPath override
        if (-not $WinREWimPath) {
            Write-Log -Message "Online mode without reagentc and without WinREWimPath is not supported in this path." -Level 'ERROR'
            throw "Cannot resolve WinRE path"
        }
        $resolvedWinREWim = $WinREWimPath
        Write-Log "Online mode with explicit WinREWimPath override: $resolvedWinREWim"
    }

    if (-not $resolvedWinREWim) {
        Write-Log -Message "Failed to resolve WinRE WIM path." -Level 'ERROR'
        throw "ResolvedWinREWim null"
    }

    if (-not (Test-Path $resolvedWinREWim)) {
        Write-Log -Message "Resolved WinRE WIM does not exist: $resolvedWinREWim" -Level 'ERROR'
        throw "WinRE WIM missing"
    }

    Write-Log "Final WinRE WIM path: $resolvedWinREWim"
}
catch {
    Write-Log -Message "WinRE source resolution failed: $($_.Exception.Message)" -Level 'ERROR'
    exit 1
}

# ------------------------ OPTIONAL BACKUP ------------------------

try {
    if (-not $SkipBackup) {
        $timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupName  = "Winre_$timestamp.wim"
        $backupPath  = Join-Path $BackupDir $backupName

        Write-Log "Backing up WinRE WIM..."
        Write-Log "  Source: $resolvedWinREWim"
        Write-Log "  Backup: $backupPath"

        Copy-Item -Path $resolvedWinREWim -Destination $backupPath -Force
        Write-Log "Backup completed successfully."
    }
    else {
        Write-Log "Skipping WinRE WIM backup (SkipBackup switch is set)."
    }
}
catch {
    Set-WarningFlag "Failed to backup WinRE WIM: $($_.Exception.Message). Continuing without backup."
}

# ------------------------ MOUNT SAFETY CHECK ---------------------

try {
    Write-Log "Checking for existing DISM mounts..."
    $dismMountCheck = dism /Get-MountedWimInfo 2>&1

    if ($LASTEXITCODE -eq 0 -and $dismMountCheck -match [Regex]::Escape($MountDir)) {
        Set-WarningFlag "DISM reports an existing mount at $MountDir. Aborting to avoid corruption."
        throw "MountDir already in use"
    }

    # Check if directory is non-empty
    $existingMountContent = Get-ChildItem -Path $MountDir -Force -ErrorAction SilentlyContinue
    if ($existingMountContent) {
        Set-WarningFlag "Mount directory is not empty: $MountDir. Aborting to avoid ambiguity."
        throw "MountDir not empty"
    }
}
catch {
    Write-Log -Message "Mount safety check failed: $($_.Exception.Message)" -Level 'ERROR'
    exit 1
}

# ------------------------ MOUNT WinRE WIM ------------------------

$mounted = $false

try {
    Write-Log "Mounting WinRE WIM..."
    Write-Log "  WIM:   $resolvedWinREWim"
    Write-Log "  Mount: $MountDir"

    $dismOutput = dism /Mount-Wim /WimFile:$resolvedWinREWim /Index:1 /MountDir:$MountDir 2>&1
    $dismExit   = $LASTEXITCODE

    if ($dismExit -ne 0) {
        Write-Log -Message "DISM failed to mount WinRE WIM (Exit code: $dismExit)" -Level 'ERROR'
        $dismOutput | ForEach-Object { Write-Log -Message $_ -Level 'ERROR' }
        throw "Mount failed"
    }

    $mounted = $true
    Write-Log "WinRE WIM mounted successfully at $MountDir"
}
catch {
    Write-Log -Message "Mount operation failed: $($_.Exception.Message)" -Level 'ERROR'
    if ($mounted) {
        Write-Log "Attempting to unmount with /Discard due to partial mount..."
        dism /Unmount-Wim /MountDir:$MountDir /Discard | Out-Null
    }
    exit 1
}

# ------------------------ DRIVER INJECTION -----------------------

try {
    Write-Log "=== Driver injection into WinRE ==="

    $driversRoot      = Join-Path $ToolkitRoot "Drivers"
    $winreDriverRoot  = Join-Path $driversRoot "WinRE"
    $modelDriverRoot  = Join-Path $ToolkitRoot "ModelDrivers"

    $driverFolders = @()

    if (Test-Path $winreDriverRoot) {
        $driverFolders += $winreDriverRoot
    } else {
        Set-WarningFlag "WinRE-specific driver folder not found: $winreDriverRoot"
    }

    if (Test-Path $modelDriverRoot) {
        $driverFolders += $modelDriverRoot
    } else {
        Set-WarningFlag "ModelDrivers folder not found: $modelDriverRoot"
    }

    if (-not $driverFolders) {
        Set-WarningFlag "No driver folders found for injection. Skipping driver injection."
    } else {
        foreach ($folder in $driverFolders) {
            Write-Log "Injecting drivers from: $folder"
            $dismDriverOutput = dism /Image:$MountDir /Add-Driver /Driver:$folder /Recurse 2>&1
            $dismDriverExit   = $LASTEXITCODE

            if ($dismDriverExit -ne 0) {
                Set-WarningFlag "DISM /Add-Driver failed for folder: $folder (Exit code: $dismDriverExit)"
                $dismDriverOutput | ForEach-Object { Write-Log -Message $_ -Level 'WARN' }
            } else {
                Write-Log "Driver injection succeeded for folder: $folder"
            }
        }
    }

    Write-Log "Driver injection phase complete."
}
catch {
    Set-WarningFlag "Driver injection encountered a fatal error: $($_.Exception.Message)"
}

# ------------------------ OPTIONAL COMPONENTS --------------------

try {
    Write-Log "=== Optional component injection into WinRE ==="

    $winPEOCsRoot = Join-Path $ToolkitRoot "WinPE_OCs"

    if (-not (Test-Path $winPEOCsRoot)) {
        Set-WarningFlag "WinPE_OCs folder not found: $winPEOCsRoot. Skipping optional components."
    } else {
        $ocFiles = @(
            "WinPE-WMI.cab",
            "WinPE-Scripting.cab",
            "WinPE-NetFX.cab",
            "WinPE-PowerShell.cab",
            "WinPE-HTA.cab",
            "WinPE-StorageWMI.cab"
        )

        foreach ($ocFile in $ocFiles) {
            $ocPath = Join-Path $winPEOCsRoot $ocFile
            if (Test-Path $ocPath) {
                Write-Log "Adding optional component: $ocFile"
                $dismOCOutput = dism /Image:$MountDir /Add-Package /PackagePath:$ocPath 2>&1
                $dismOCExit   = $LASTEXITCODE

                if ($dismOCExit -ne 0) {
                    Set-WarningFlag "DISM /Add-Package failed for $ocFile (Exit code: $dismOCExit)"
                    $dismOCOutput | ForEach-Object { Write-Log -Message $_ -Level 'WARN' }
                } else {
                    Write-Log "Optional component added: $ocFile"
                }
            } else {
                Set-WarningFlag "Optional component CAB not found: $ocPath"
            }
        }
    }

    Write-Log "Optional component phase complete."
}
catch {
    Set-WarningFlag "Optional component injection encountered a fatal error: $($_.Exception.Message)"
}

# ------------------------ TOOLKIT INJECTION ----------------------

try {
    Write-Log "=== Toolkit injection into WinRE ==="

    $targetToolkit = Join-Path $MountDir "Toolkit"

    if (-not (Test-Path $targetToolkit)) {
        New-Item -Path $targetToolkit -ItemType Directory -Force | Out-Null
    }

    Write-Log "Toolkit source: $ToolkitRoot"
    Write-Log "Toolkit target (in image): $targetToolkit"

    $toolkitItems = @("Scripts", "Drivers", "Updates", "Tools")

    foreach ($item in $toolkitItems) {
        $src = Join-Path $ToolkitRoot $item
        if (Test-Path $src) {
            $dest = Join-Path $targetToolkit $item
            Write-Log "Copying $item to WinRE..."
            robocopy $src $dest /E | Out-Null
            if ($LASTEXITCODE -ge 8) {
                Set-WarningFlag "Robocopy reported errors copying $item (exit code $LASTEXITCODE)."
            }
        } else {
            Set-WarningFlag "Toolkit item not found: $src"
        }
    }

    Write-Log "Toolkit injection phase complete."
}
catch {
    Set-WarningFlag "Toolkit injection encountered a fatal error: $($_.Exception.Message)"
}

# ------------------------ FIRMWARE TOOLS -------------------------

try {
    Write-Log "=== Firmware tools injection into WinRE ==="

    $firmwareToolsRoot = Join-Path $ToolkitRoot "FirmwareTools"

    if (-not (Test-Path $firmwareToolsRoot)) {
        Set-WarningFlag "FirmwareTools folder not found: $firmwareToolsRoot. Skipping firmware tools."
    } else {
        $targetFirmware = Join-Path $MountDir "Firmware"
        if (-not (Test-Path $targetFirmware)) {
            New-Item -Path $targetFirmware -ItemType Directory -Force | Out-Null
        }

        Write-Log "Firmware tools source: $firmwareToolsRoot"
        Write-Log "Firmware tools target (in image): $targetFirmware"

        robocopy $firmwareToolsRoot $targetFirmware /E | Out-Null
        if ($LASTEXITCODE -ge 8) {
            Set-WarningFlag "Robocopy reported errors copying firmware tools (exit code $LASTEXITCODE)."
        } else {
            Write-Log "Firmware tools injection completed."
        }
    }
}
catch {
    Set-WarningFlag "Firmware tools injection encountered a fatal error: $($_.Exception.Message)"
}

# ------------------------ BRANDING / UX --------------------------

try {
    Write-Log "=== Branding / UX customization for WinRE ==="

    $system32Path   = Join-Path $MountDir "Windows\System32"
    $winpeshlPath   = Join-Path $system32Path "winpeshl.ini"
    $startnetPath   = Join-Path $system32Path "startnet.cmd"

    $toolkitLauncher = "X:\Toolkit\Scripts\Recovery\Start-Recovery.cmd"

    $winpeshlContent = @"
[LaunchApp]
AppPath = %SystemRoot%\System32\cmd.exe
"@

    Set-Content -Path $winpeshlPath -Value $winpeshlContent -Encoding ASCII
    Write-Log "winpeshl.ini updated to launch cmd.exe"

    $startnetLines = @(
        "@echo off",
        "wpeinit",
        "if exist `"$toolkitLauncher`" call `"$toolkitLauncher`""
    )

    Set-Content -Path $startnetPath -Value $startnetLines -Encoding ASCII
    Write-Log "startnet.cmd updated to initialize WinRE and optionally launch toolkit."

    Write-Log "Branding/UX phase complete (basic shell wiring)."
}
catch {
    Set-WarningFlag "Branding/UX customization encountered a fatal error: $($_.Exception.Message)"
}

# ------------------------ CONFIGURATION --------------------------

try {
    Write-Log "=== Configuration injection into WinRE ==="

    $customRoot    = Join-Path $MountDir "Custom"
    $configRoot    = Join-Path $customRoot "Config"

    if (-not (Test-Path $configRoot)) {
        New-Item -Path $configRoot -ItemType Directory -Force | Out-Null
    }

    $configJsonPath = Join-Path $configRoot "WinRE-ToolkitConfig.json"

    $configObject = [PSCustomObject]@{
        ToolkitRoot      = "X:\Toolkit"
        LogPath          = "X:\Toolkit\Logs"
        Mode             = $Mode
        CustomizedOn     = (Get-Date).ToString("s")
        CustomizedBy     = $env:USERNAME
        Version          = "1.0"
    }

    $configJson = $configObject | ConvertTo-Json -Depth 4
    Set-Content -Path $configJsonPath -Value $configJson -Encoding UTF8

    Write-Log "Configuration written to: $configJsonPath"
    Write-Log "Configuration phase complete."
}
catch {
    Set-WarningFlag "Configuration injection encountered a fatal error: $($_.Exception.Message)"
}

# ------------------------ VALIDATION -----------------------------

try {
    Write-Log "=== Validation of customized WinRE image ==="

    $requiredPaths = @(
        (Join-Path $MountDir "Windows\System32\winpeshl.ini"),
        (Join-Path $MountDir "Windows\System32\startnet.cmd"),
        (Join-Path $MountDir "Toolkit")
    )

    foreach ($path in $requiredPaths) {
        if (-not (Test-Path $path)) {
            Set-WarningFlag "Expected path missing in WinRE image: $path"
        } else {
            Write-Log "Validated presence of: $path"
        }
    }

    $dismListOutput = dism /Image:$MountDir /Get-Packages 2>&1
    if ($LASTEXITCODE -ne 0) {
        Set-WarningFlag "DISM /Get-Packages failed during validation. Exit code: $LASTEXITCODE"
    } else {
        Write-Log "DISM package listing completed."
    }

    Write-Log "Validation phase complete."
}
catch {
    Set-WarningFlag "Validation encountered a fatal error: $($_.Exception.Message)"
}

# ------------------------ UNMOUNT & COMMIT/DISCARD --------------

$commit = $true
if ($NoCommitOnWarning -and $HasWarnings) {
    Set-WarningFlag "Warnings detected and -NoCommitOnWarning is set; discarding changes."
    $commit = $false
}

try {
    if ($commit) {
        Write-Log "Committing changes and unmounting WinRE image..."
        $dismUnmountOutput = dism /Unmount-Wim /MountDir:$MountDir /Commit 2>&1
        $dismUnmountExit   = $LASTEXITCODE

        if ($dismUnmountExit -ne 0) {
            Write-Log -Message "DISM failed to unmount/commit WinRE (Exit code: $dismUnmountExit)" -Level 'ERROR'
            $dismUnmountOutput | ForEach-Object { Write-Log -Message $_ -Level 'ERROR' }
            throw "Unmount/commit failed"
        } else {
            Write-Log "WinRE image unmounted and committed successfully."
        }
    } else {
        Write-Log "Discarding changes and unmounting WinRE image..."
        $dismUnmountOutput = dism /Unmount-Wim /MountDir:$MountDir /Discard 2>&1
        $dismUnmountExit   = $LASTEXITCODE

        if ($dismUnmountExit -ne 0) {
            Write-Log -Message "DISM failed to unmount/discard WinRE (Exit code: $dismUnmountExit)" -Level 'ERROR'
            $dismUnmountOutput | ForEach-Object { Write-Log -Message $_ -Level 'ERROR' }
            throw "Unmount/discard failed"
        } else {
            Write-Log "WinRE image unmounted and changes discarded."
        }
    }
}
catch {
    Write-Log -Message "Unmount operation failed: $($_.Exception.Message)" -Level 'ERROR'
    exit 1
}

# ------------------------ REAGENTC RE-REGISTRATION ---------------

if ($Mode -eq 'Online' -and -not $SkipReagentc) {
    try {
        Write-Log "=== Re-registering WinRE using reagentc (online mode) ==="

        $reDisable = reagentc /disable 2>&1
        if ($LASTEXITCODE -ne 0) {
            Set-WarningFlag "reagentc /disable failed (Exit code: $LASTEXITCODE). Output: $reDisable"
        } else {
            Write-Log "WinRE disabled successfully."
        }

        $winreDir = Split-Path -Parent $resolvedWinREWim
        Write-Log "Setting WinRE image directory: $winreDir"

        $reSet = reagentc /setreimage /path $winreDir 2>&1
        if ($LASTEXITCODE -ne 0) {
            Set-WarningFlag "reagentc /setreimage failed (Exit code: $LASTEXITCODE). Output: $reSet"
        } else {
            Write-Log "WinRE image directory set successfully."
        }

        $reEnable = reagentc /enable 2>&1
        if ($LASTEXITCODE -ne 0) {
            Set-WarningFlag "reagentc /enable failed (Exit code: $LASTEXITCODE). Output: $reEnable"
        } else {
            Write-Log "WinRE enabled successfully."
        }

        Write-Log "Final WinRE configuration (reagentc /info):"
        $reInfo = reagentc /info 2>&1
        $reInfo | ForEach-Object { Write-Log -Message $_ -Level 'INFO' }
    }
    catch {
        Set-WarningFlag "Reagentc re-registration encountered an error: $($_.Exception.Message)"
    }
}
else {
    Write-Log "Skipping reagentc re-registration (Mode: $Mode, SkipReagentc: $SkipReagentc)."
}

