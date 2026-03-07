# Better11.InstallEngine
# Unified installer for winget or offline installers defined in Config/installer_metadata.json
using namespace System.Collections.Concurrent

function Read-Better11Json {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "JSON not found: $Path" }
    Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Install-WingetPackage {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Source = "winget",
        [switch]$Force,
        [switch]$Silent
    )
    $args = @("install","--id",$Id,"--accept-package-agreements","--accept-source-agreements")
    if ($Force) { $args += "--force" }
    if ($Silent) { $args += "--silent" }
    if ($PSCmdlet.ShouldProcess($Id, "winget install")) {
        $p = Start-Process -FilePath "winget" -ArgumentList $args -Wait -PassThru -NoNewWindow
        return [pscustomobject]@{ Id=$Id; ExitCode=$p.ExitCode; Tool="winget" }
    } else {
        return [pscustomobject]@{ Id=$Id; ExitCode=0; Tool="winget"; WhatIf=$true }
    }
}

function Install-OfflinePackage {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)][pscustomobject]$Meta  # from installer_metadata.json
    )
    if (-not (Test-Path -LiteralPath $Meta.Path)) { throw "Installer not found: $($Meta.Path)" }
    $args = $Meta.SilentArgs
    if (-not $args) { throw "SilentArgs missing for $($Meta.Name)" }
    if ($PSCmdlet.ShouldProcess($Meta.Name, "offline install")) {
        $p = Start-Process -FilePath $Meta.Path -ArgumentList $args -Wait -PassThru -NoNewWindow
        return [pscustomobject]@{ Id=$Meta.Name; ExitCode=$p.ExitCode; Tool="offline" }
    } else {
        return [pscustomobject]@{ Id=$Meta.Name; ExitCode=0; Tool="offline"; WhatIf=$true }
    }
}

function Install-Better11Apps {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)][string]$CatalogPath,               # Manifests/apps.json in future
        [Parameter(Mandatory)][string]$InstallerMetadataPath,     # Config/installer_metadata.json
        [string[]]$Select,                                        # subset of app IDs
        [switch]$OfflineOnly,
        [int]$MaxConcurrency = 3,
        [switch]$WhatIf
    )
    $catalog = Read-Better11Json -Path $CatalogPath
    $meta    = Read-Better11Json -Path $InstallerMetadataPath

    $apps = if ($Select) { $catalog | Where-Object { $_.Id -in $Select } } else { $catalog }
    $results = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

    $scriptBlock = {
        param($item, $metaPath, $offlineOnly, $whatIf)
        $meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
        if (-not $offlineOnly -and $item.Source -eq "winget") {
            Install-WingetPackage -Id $item.Id -Silent -WhatIf:$whatIf
        } else {
            $m = $meta | Where-Object { $_.Name -eq $item.Id }
            if (-not $m) { throw "Metadata missing for $($item.Id)" }
            Install-OfflinePackage -Meta $m -WhatIf:$whatIf
        }
    }

    $throttle = [System.Threading.SemaphoreSlim]::new($MaxConcurrency, $MaxConcurrency)
    $tasks = foreach ($a in $apps) {
        $throttle.Wait()
        [System.Threading.Tasks.Task]::Run({
            try {
                $r = & $using:scriptBlock $a $using:InstallerMetadataPath $using:OfflineOnly $using:WhatIf
                $using:results.Add($r)
            } catch {
                $using:results.Add([pscustomobject]@{ Id=$a.Id; ExitCode=1; Error=$_.Exception.Message })
            } finally {
                $using:throttle.Release() | Out-Null
            }
        })
    }
    [System.Threading.Tasks.Task]::WaitAll($tasks)

    return @($results)
}

Export-ModuleMember -Function Install-Better11Apps, Install-WingetPackage, Install-OfflinePackage, Read-Better11Json
