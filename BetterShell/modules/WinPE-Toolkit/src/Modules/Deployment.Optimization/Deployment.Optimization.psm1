Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop

function Get-OptimizationProfiles {
    [CmdletBinding()]
    param()

    $root = Get-DeployRoot
    $dir = Join-Path $root 'configs\optimize\profiles'

    if (-not (Test-Path $dir)) {
        throw "Optimization profile directory '$dir' does not exist."
    }

    $files = Get-ChildItem -Path $dir -Filter '*.json' -File

    if (-not $files) {
        throw "No optimization profile JSON files found in '$dir'."
    }

    $profiles = @()

    foreach ($file in $files) {
        $raw  = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        $data = $raw | ConvertFrom-Json -ErrorAction Stop

        if ($data -is [System.Collections.IEnumerable]) {
            $profiles += $data
        } else {
            $profiles += $data
        }
    }

    return $profiles
}

function Get-OptimizationProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Id
    )

    $profiles = Get-OptimizationProfiles
    $p = $profiles | Where-Object { $_.id -eq $Id }

    if (-not $p) {
        throw "Optimization profile '$Id' not found."
    }

    return $p
}

function Invoke-OptimizationAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [pscustomobject] $Action
    )

    $type = $Action.type

    switch ($type) {
        'RegistrySet' {
            $hive = $Action.hive
            $path = $Action.path
            $name = $Action.name
            $valueType = $Action.valueType
            $value = $Action.value

            if (-not $hive -or -not $path -or -not $name) {
                throw "RegistrySet action requires 'hive', 'path', and 'name'."
            }

            $rootKey = switch ($hive.ToUpperInvariant()) {
                'HKLM' { 'HKLM:' }
                'HKCU' { 'HKCU:' }
                default { throw "RegistrySet hive '$hive' not supported. Use HKLM or HKCU." }
            }

            $fullPath = Join-Path $rootKey $path

            if (-not (Test-Path $fullPath)) {
                New-Item -Path $fullPath -Force | Out-Null
            }

            $RunContext | Write-DeployEvent -Level 'Debug' -Message "Setting registry value '$fullPath\\$name' ($valueType) to '$value'."

            $typeParam = switch ($valueType) {
                'String'        { 'String' }
                'ExpandString'  { 'ExpandString' }
                'DWord'         { 'DWord' }
                'QWord'         { 'QWord' }
                'MultiString'   { 'MultiString' }
                default         { 'String' }
            }

            New-ItemProperty -Path $fullPath -Name $name -PropertyType $typeParam -Value $value -Force | Out-Null
        }

        'ServiceConfig' {
            $svcName    = $Action.serviceName
            $startType  = $Action.startType
            $ensureRunning = [bool]$Action.ensureRunning
            $ensureStopped = [bool]$Action.ensureStopped

            if (-not $svcName) {
                throw "ServiceConfig action requires 'serviceName'."
            }

            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue

            if (-not $svc) {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "Service '$svcName' not found; skipping."
                return
            }

            if ($startType) {
                $RunContext | Write-DeployEvent -Level 'Debug' -Message "Setting service '$svcName' start type to '$startType'."
                sc.exe config $svcName start= $startType | Out-Null
            }

            if ($ensureRunning -and $svc.Status -ne 'Running') {
                $RunContext | Write-DeployEvent -Level 'Debug' -Message "Starting service '$svcName'."
                Start-Service -Name $svcName -ErrorAction SilentlyContinue
            }

            if ($ensureStopped -and $svc.Status -ne 'Stopped') {
                $RunContext | Write-DeployEvent -Level 'Debug' -Message "Stopping service '$svcName'."
                Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            }
        }

        'ScheduledTaskDisable' {
            $taskPath = $Action.taskPath
            $taskName = $Action.taskName

            if (-not $taskName) {
                throw "ScheduledTaskDisable action requires 'taskName'."
            }

            try {
                $task = if ($taskPath) {
                    Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
                } else {
                    Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
                }

                $RunContext | Write-DeployEvent -Level 'Debug' -Message "Disabling scheduled task '$($task.TaskPath)$($task.TaskName)'."
                Disable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
            }
            catch {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "Failed to disable scheduled task '$taskName': $($_.Exception.Message)"
            }
        }

        'PowerPlanSet' {
            $scheme = $Action.scheme

            if (-not $scheme) {
                throw "PowerPlanSet action requires 'scheme'."
            }

            # Map friendly names to GUIDs
            $map = @{
                'BALANCED'            = '381b4222-f694-41f0-9685-ff5bb260df2e'
                'HIGH PERFORMANCE'    = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                'POWERSAVER'          = 'a1841308-3541-4fab-bc81-f71556f20b4a'
                'POWER SAVER'         = 'a1841308-3541-4fab-bc81-f71556f20b4a'
                'ULTIMATE PERFORMANCE'= 'e9a42b02-d5df-448d-aa00-03f14749eb61'
            }

            $schemeKey = $scheme.ToUpperInvariant()
            $guid = if ($map.ContainsKey($schemeKey)) {
                $map[$schemeKey]
            } else {
                $scheme
            }

            $RunContext | Write-DeployEvent -Level 'Info' -Message "Activating power scheme '$scheme' ($guid)."
            powercfg.exe -setactive $guid | Out-Null
        }

        'RunProcess' {
            $exe  = $Action.executable
            $args = $Action.arguments

            if (-not $exe) {
                throw "RunProcess action requires 'executable'."
            }

            $RunContext | Write-DeployEvent -Level 'Debug' -Message "Running process '$exe' with arguments '$args'."

            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = $exe
            $pinfo.Arguments = $args
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError  = $true
            $pinfo.UseShellExecute        = $false
            $pinfo.CreateNoWindow         = $true

            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $pinfo

            if (-not $proc.Start()) {
                throw "Failed to start executable '$exe'."
            }

            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            Add-Content -Path $RunContext.RunLogPath -Value $stdout
            if ($stderr) {
                Add-Content -Path $RunContext.RunLogPath -Value $stderr
            }

            if ($proc.ExitCode -ne 0) {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "RunProcess '$exe' exited with code $($proc.ExitCode)."
            }
        }

        default {
            throw "Unsupported optimization action type '$type'."
        }
    }
}

function Invoke-OptimizationProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $Id
    )

    $profile = Get-OptimizationProfile -Id $Id
    $RunContext | Write-DeployEvent -Level 'Info' -Message "Applying optimization profile '$($profile.name)' (id=$Id)."

    if (-not $profile.actions -or $profile.actions.Count -eq 0) {
        $RunContext | Write-DeployEvent -Level 'Warning' -Message "Optimization profile '$Id' has no actions."
        return
    }

    foreach ($action in $profile.actions) {
        try {
            Invoke-OptimizationAction -RunContext $RunContext -Action $action
        }
        catch {
            $RunContext | Write-DeployEvent -Level 'Error' -Message "Optimization action in profile '$Id' failed: $($_.Exception.Message)"

            if ($profile.failOnError) {
                throw
            }
        }
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Optimization profile '$Id' applied."
}

function Get-DebloatProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Id
    )

    $root = Get-DeployRoot
    $path = Join-Path $root 'configs\optimize\debloat.json'

    if (-not (Test-Path $path)) {
        throw "Debloat configuration file '$path' not found."
    }

    $raw = Get-Content -Path $path -Raw -ErrorAction Stop
    $data = $raw | ConvertFrom-Json -ErrorAction Stop

    $profile = $data | Where-Object { $_.id -eq $Id }

    if (-not $profile) {
        throw "Debloat profile '$Id' not found in '$path'."
    }

    return $profile
}

function Invoke-DebloatProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $Id
    )

    $profile = Get-DebloatProfile -Id $Id
    $RunContext | Write-DeployEvent -Level 'Info' -Message "Applying debloat profile '$($profile.name)' (id=$Id)."

    # Remove Appx packages for current user and provisioned packages
    if ($profile.removeAppxNames -and $profile.removeAppxNames.Count -gt 0) {
        $names = $profile.removeAppxNames

        foreach ($name in $names) {
            $RunContext | Write-DeployEvent -Level 'Debug' -Message "Attempting to remove Appx packages matching '$name'."

            try {
                $appx = Get-AppxPackage -AllUsers | Where-Object {
                    $_.Name -like "*$name*" -or $_.PackageFamilyName -like "*$name*"
                }

                foreach ($pkg in $appx) {
                    $RunContext | Write-DeployEvent -Level 'Info' -Message "Removing Appx package '$($pkg.Name)' for all users."
                    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                }
            }
            catch {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "Failed to enumerate/remove Appx for '$name': $($_.Exception.Message)"
            }

            try {
                $prov = Get-AppxProvisionedPackage -Online | Where-Object {
                    $_.DisplayName -like "*$name*" -or $_.PackageName -like "*$name*"
                }

                foreach ($p in $prov) {
                    $RunContext | Write-DeployEvent -Level 'Info' -Message "Removing provisioned Appx package '$($p.DisplayName)'."
                    Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction SilentlyContinue | Out-Null
                }
            }
            catch {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "Failed to enumerate/remove provisioned Appx for '$name': $($_.Exception.Message)"
            }
        }
    }

    # Registry-based debloat tweaks
    if ($profile.registryTweaks) {
        foreach ($t in $profile.registryTweaks) {
            try {
                Invoke-OptimizationAction -RunContext $RunContext -Action ([pscustomobject]@{
                    type      = 'RegistrySet'
                    hive      = $t.hive
                    path      = $t.path
                    name      = $t.name
                    valueType = $t.valueType
                    value     = $t.value
                })
            }
            catch {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "Debloat registry tweak failed: $($_.Exception.Message)"
            }
        }
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Debloat profile '$Id' applied."
}

function Set-PersonalizationProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $Id
    )

    $root = Get-DeployRoot
    $path = Join-Path $root 'configs\optimize\personalization.json'

    if (-not (Test-Path $path)) {
        throw "Personalization configuration file '$path' not found."
    }

    $raw = Get-Content -Path $path -Raw -ErrorAction Stop
    $data = $raw | ConvertFrom-Json -ErrorAction Stop

    $profile = $data | Where-Object { $_.id -eq $Id }

    if (-not $profile) {
        throw "Personalization profile '$Id' not found in '$path'."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Applying personalization profile '$($profile.name)' (id=$Id)."

    # Simple implementation: mostly registry + RunProcess actions, reuse Invoke-OptimizationAction
    if ($profile.actions) {
        foreach ($a in $profile.actions) {
            try {
                Invoke-OptimizationAction -RunContext $RunContext -Action $a
            }
            catch {
                $RunContext | Write-DeployEvent -Level 'Warning' -Message "Personalization action failed: $($_.Exception.Message)"
            }
        }
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Personalization profile '$Id' applied."
}

