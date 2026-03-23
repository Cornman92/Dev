Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop

# Module-level cache
$script:HardwareProfileCache = $null
$script:DriverCatalogCache = $null

function Get-HardwareProfile {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch] $ForceRefresh
    )

    # Use cache if available and not forcing refresh
    if (-not $ForceRefresh -and $script:HardwareProfileCache) {
        return $script:HardwareProfileCache
    }

    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $memBytes = [int64]($cs.TotalPhysicalMemory)
    $video = Get-CimInstance -ClassName Win32_VideoController
    $net   = Get-CimInstance -ClassName Win32_NetworkAdapter |
        Where-Object { $_.PhysicalAdapter -eq $true -and $_.PNPDeviceID }

    # PNP IDs from Win32_PnPEntity (broader coverage)
    $pnp = Get-CimInstance -ClassName Win32_PnPEntity |
        Where-Object { $_.PNPDeviceID -like 'PCI\*' -or $_.PNPDeviceID -like 'USB\*' }

    $obj = [pscustomobject]@{
        Manufacturer     = $cs.Manufacturer
        Model            = $cs.Model
        BIOSVersion      = ($bios.SMBIOSBIOSVersion -join ', ')
        BIOSVendor       = $bios.Manufacturer
        BIOSReleaseDate  = $bios.ReleaseDate
        CPUName          = $cpu.Name
        CPUCores         = $cpu.NumberOfCores
        CPUThreads       = $cpu.NumberOfLogicalProcessors
        TotalMemoryBytes = $memBytes
        TotalMemoryGB    = [math]::Round($memBytes / 1GB, 1)
        OSVersion        = $os.Version
        OSEdition        = $os.Caption
        VideoControllers = $video | Select-Object Name, PNPDeviceID
        NetworkAdapters  = $net   | Select-Object Name, PNPDeviceID
        PnpIds           = $pnp   | Select-Object Name, PNPDeviceID
    }

    # Cache the result
    $script:HardwareProfileCache = $obj
    return $obj
}

function Get-DriverCatalog {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch] $ForceRefresh
    )

    # Use cache if available and not forcing refresh
    if (-not $ForceRefresh -and $script:DriverCatalogCache) {
        return $script:DriverCatalogCache
    }

    $root = Get-DeployRoot
    $dir = Join-Path $root 'configs\drivers'

    if (-not (Test-Path $dir)) {
        throw "Driver catalog directory '$dir' does not exist."
    }

    $files = Get-ChildItem -Path $dir -Filter '*.json' -File

    if (-not $files) {
        throw "No driver catalog JSON files found in '$dir'."
    }

    $catalog = @()

    foreach ($f in $files) {
        $raw = Get-Content -Path $f.FullName -Raw -ErrorAction Stop
        $data = $raw | ConvertFrom-Json -ErrorAction Stop

        foreach ($entry in $data) {
            # Ensure required fields exist
            if (-not $entry.id) {
                throw "Driver pack entry in '$($f.FullName)' is missing 'id'."
            }

            if (-not $entry.paths) {
                throw "Driver pack '$($entry.id)' in '$($f.FullName)' is missing 'paths'."
            }

            # Resolve paths with environment variable substitution
            $resolvedPaths = @()
            foreach ($path in $entry.paths) {
                $resolvedPaths += Resolve-DeployPath -Path $path
            }
            $entry.paths = $resolvedPaths

            $catalog += $entry
        }
    }

    # Cache the result
    $script:DriverCatalogCache = $catalog
    return $catalog
}

function Find-DriverPacksForHardware {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $HardwareProfile,

        [Parameter(Mandatory)]
        [pscustomobject[]] $DriverCatalog
    )

    $matches = @()
    $hwModel = if ($HardwareProfile.Model) { $HardwareProfile.Model } else { '' }
    $hwModel = $hwModel.ToLowerInvariant()
    $hwMfr   = if ($HardwareProfile.Manufacturer) { $HardwareProfile.Manufacturer } else { '' }
    $hwMfr   = $hwMfr.ToLowerInvariant()
    $pnpSet  = @($HardwareProfile.PnpIds | ForEach-Object { $_.PNPDeviceID }) | Where-Object { $_ } | Select-Object -Unique

    foreach ($pack in $DriverCatalog) {
        $score = 0
        $reasons = @()
        $targets = $pack.targetHardware

        if ($targets) {
            # Manufacturer/Model matches
            if ($targets.manufacturer) {
                $tMfr = $targets.manufacturer.ToLowerInvariant()
                if ($hwMfr -like "*$tMfr*") {
                    $score += 20
                    $reasons += "Manufacturer match '$($targets.manufacturer)'"
                }
            }

            if ($targets.model) {
                $tModel = $targets.model.ToLowerInvariant()
                if ($hwModel -like "*$tModel*") {
                    $score += 40
                    $reasons += "Model match '$($targets.model)'"
                }
            }

            if ($targets.modelPatterns) {
                foreach ($pattern in $targets.modelPatterns) {
                    $pat = $pattern.ToLowerInvariant()
                    if ($hwModel -like "*$pat*") {
                        $score += 15
                        $reasons += "Model pattern match '$pattern'"
                    }
                }
            }

            if ($targets.pnpIdPrefixes) {
                $prefixHits = 0
                foreach ($prefix in $targets.pnpIdPrefixes) {
                    # Escape special regex characters in PNP ID prefixes
                    $pref = [regex]::Escape($prefix.ToUpperInvariant())
                    if ($pnpSet -match "^$pref") {
                        $prefixHits++
                    }
                }

                if ($prefixHits -gt 0) {
                    $score += [math]::Min($prefixHits * 5, 40)
                    $reasons += "PNP prefix hits: $prefixHits"
                }
            }
        }

        if ($score -gt 0 -or -not $targets) {
            $matches += [pscustomobject]@{
                DriverPack = $pack
                Score      = $score
                Reasons    = $reasons -join '; '
            }
        }
    }

    $matches = $matches | Sort-Object -Property Score -Descending
    return $matches
}

function Add-DriversToOfflineWindows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Z]:\\$')]
        [string] $WindowsVolumeRoot,

        [Parameter(Mandatory)]
        [object[]] $DriverPacks
    )

    if (-not $DriverPacks -or $DriverPacks.Count -eq 0) {
        $RunContext | Write-DeployEvent -Level 'Info' -Message 'No driver packs provided for offline injection.'
        return
    }

    $imagePath = $WindowsVolumeRoot.TrimEnd('\')

    foreach ($pack in $DriverPacks) {
        $id = $pack.id
        $RunContext | Write-DeployEvent -Level 'Info' -Message "Injecting driver pack '$id' into offline Windows at '$imagePath'."

        foreach ($p in $pack.paths) {
            $driverPath = $p

            if (-not (Test-Path $driverPath)) {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "Driver path '$driverPath' for pack '$id' does not exist; skipping."
                continue
            }

            $args = "/Image:`"$imagePath`" /Add-Driver /Driver:`"$driverPath`" /Recurse"

            $RunContext | Write-DeployEvent -Level 'Debug' -Message "Running DISM for driver path '$driverPath' with args: $args"

            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = 'dism.exe'
            $pinfo.Arguments = $args
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError  = $true
            $pinfo.UseShellExecute        = $false
            $pinfo.CreateNoWindow         = $true

            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $pinfo

            if (-not $proc.Start()) {
                throw "Failed to start dism.exe for driver injection."
            }

            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            Add-Content -Path $RunContext.RunLogPath -Value $stdout
            if ($stderr) {
                Add-Content -Path $RunContext.RunLogPath -Value $stderr
            }

            if ($proc.ExitCode -ne 0) {
                $RunContext | Write-DeployEvent -Level 'Error' -Message "DISM /Add-Driver failed for '$driverPath' (pack '$id') with exit code $($proc.ExitCode)."
                throw "Driver injection failed for '$driverPath'. Exit code: $($proc.ExitCode)."
            }
        }

        $RunContext | Write-DeployEvent -Level 'Info' -Message "Driver pack '$id' injected successfully into offline image."
    }
}

function Add-DriversToMountedImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $MountPath,

        [Parameter(Mandatory)]
        [object[]] $DriverPacks
    )

    if (-not (Test-Path $MountPath)) {
        throw "Mounted image path '$MountPath' does not exist."
    }

    if (-not $DriverPacks -or $DriverPacks.Count -eq 0) {
        $RunContext | Write-DeployEvent -Level 'Info' -Message 'No driver packs provided for mounted image injection.'
        return
    }

    foreach ($pack in $DriverPacks) {
        $id = $pack.id
        $RunContext | Write-DeployEvent -Level 'Info' -Message "Injecting driver pack '$id' into mounted image at '$MountPath'."

        foreach ($p in $pack.paths) {
            $driverPath = $p

            if (-not (Test-Path $driverPath)) {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "Driver path '$driverPath' for pack '$id' does not exist; skipping."
                continue
            }

            $args = "/Image:`"$MountPath`" /Add-Driver /Driver:`"$driverPath`" /Recurse"

            $RunContext | Write-DeployEvent -Level 'Debug' -Message "Running DISM for driver path '$driverPath' with args: $args"

            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = 'dism.exe'
            $pinfo.Arguments = $args
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError  = $true
            $pinfo.UseShellExecute        = $false
            $pinfo.CreateNoWindow         = $true

            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $pinfo

            if (-not $proc.Start()) {
                throw "Failed to start dism.exe for mounted image driver injection."
            }

            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            Add-Content -Path $RunContext.RunLogPath -Value $stdout
            if ($stderr) {
                Add-Content -Path $RunContext.RunLogPath -Value $stderr
            }

            if ($proc.ExitCode -ne 0) {
                $RunContext | Write-DeployEvent -Level 'Error' -Message "DISM /Add-Driver failed for '$driverPath' (pack '$id') with exit code $($proc.ExitCode)."
                throw "Driver injection failed for '$driverPath'. Exit code: $($proc.ExitCode)."
            }
        }

        $RunContext | Write-DeployEvent -Level 'Info' -Message "Driver pack '$id' injected successfully into mounted image."
    }
}

