Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop

# Module-level cache
$script:AppCatalogCache = $null

function Get-AppCatalog {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch] $ForceRefresh
    )

    # Use cache if available and not forcing refresh
    if (-not $ForceRefresh -and $script:AppCatalogCache) {
        return $script:AppCatalogCache
    }

    $root = Get-DeployRoot
    $dir = Join-Path $root 'configs\apps'

    if (-not (Test-Path $dir)) {
        throw "App catalog directory '$dir' does not exist."
    }

    $files = Get-ChildItem -Path $dir -Filter '*.json' -File

    if (-not $files) {
        throw "No app catalog JSON files found in '$dir'."
    }

    $catalog = @()

    foreach ($f in $files) {
        $raw = Get-Content -Path $f.FullName -Raw -ErrorAction Stop
        $data = $raw | ConvertFrom-Json -ErrorAction Stop

        foreach ($entry in $data) {
            if (-not $entry.id) {
                throw "App entry in '$($f.FullName)' is missing 'id'."
            }

            # Resolve source path with environment variable substitution (for MSI/EXE sources)
            if ($entry.PSObject.Properties.Name -contains 'sourceType' -and 
                $entry.sourceType -in @('msi', 'exe', 'msix') -and 
                $entry.source) {
                $entry.source = Resolve-DeployPath -Path $entry.source
            }

            $catalog += $entry
        }
    }

    # Cache the result
    $script:AppCatalogCache = $catalog
    return $catalog
}

function Get-AppSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $SetId
    )

    $root = Get-DeployRoot
    $path = Join-Path $root 'configs\apps\appsets.json'

    if (-not (Test-Path $path)) {
        throw "App set configuration file '$path' not found."
    }

    $raw = Get-Content -Path $path -Raw -ErrorAction Stop
    $data = $raw | ConvertFrom-Json -ErrorAction Stop

    $set = $data | Where-Object { $_.id -eq $SetId }

    if (-not $set) {
        throw "App set '$SetId' not found in '$path'."
    }

    return $set
}

function Test-AppInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $App
    )

    $detect = $App.detection

    if (-not $detect) {
        return $false
    }

    # Registry detection
    if ($detect.registry) {
        foreach ($item in $detect.registry) {
            $path = $item.path
            $name = $item.name
            $expected = $item.value

            $hive, $sub = $path.Split('\', 2)

            $rootKey = switch ($hive) {
                'HKLM:' { 'HKLM' }
                'HKLM'  { 'HKLM' }
                'HKCU:' { 'HKCU' }
                'HKCU'  { 'HKCU' }
                default { $null }
            }

            if (-not $rootKey -or -not $sub) { continue }

            try {
                $reg = Get-ItemProperty -Path ("Registry::" + $rootKey + "\" + $sub) -Name $name -ErrorAction Stop

                if ($null -ne $expected) {
                    if ($reg.$name -eq $expected) {
                        return $true
                    }
                } else {
                    return $true
                }
            }
            catch {
                # ignore and try other rules
            }
        }
    }

    # File detection
    if ($detect.files) {
        foreach ($item in $detect.files) {
            $path = $item.path
            if (Test-Path $path) {
                return $true
            }
        }
    }

    # ProductCode (MSI)
    if ($detect.productCode) {
        $code = $detect.productCode
        $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        $keyWow = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

        $allKeys = @()
        if (Test-Path $key)    { $allKeys += Get-ChildItem -Path $key }
        if (Test-Path $keyWow) { $allKeys += Get-ChildItem -Path $keyWow }

        foreach ($k in $allKeys) {
            try {
                $props = Get-ItemProperty -Path $k.PSPath -ErrorAction Stop
                if ($props.PSChildName -eq $code) {
                    return $true
                }
            }
            catch { }
        }
    }

    return $false
}

function Install-AppPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [pscustomobject] $App,

        [Parameter()]
        [hashtable] $InstallState
    )

    if (-not $InstallState) {
        $InstallState = @{}
    }

    $id = $App.id

    if ($InstallState.ContainsKey($id)) {
        return # already processed
    }

    # Dependencies
    if ($App.dependencies) {
        $catalog = Get-AppCatalog

        foreach ($depId in $App.dependencies) {
            $dep = $catalog | Where-Object { $_.id -eq $depId }

            if (-not $dep) {
                throw "App '$id' dependency '$depId' not found in catalog."
            }

            Install-AppPackage -RunContext $RunContext -App $dep -InstallState $InstallState
        }
    }

    if (Test-AppInstalled -App $App) {
        $RunContext | Write-DeployEvent -Level 'Info' -Message "App '$id' already installed; skipping."
        $InstallState[$id] = 'Present'
        return
    }

    $sourceType = $App.sourceType
    $RunContext | Write-DeployEvent -Level 'Info' -Message "Installing app '$id' (sourceType=$sourceType)."

    switch ($sourceType) {
        'msi' {
            $path = $App.source

            if (-not (Test-Path $path)) {
                throw "MSI source '$path' for app '$id' not found."
            }

            $args = "/i `"$path`" /qn /norestart"

            if ($App.installArgs) {
                $args += " $($App.installArgs)"
            }

            $exe = 'msiexec.exe'
        }

        'exe' {
            $path = $App.source

            if (-not (Test-Path $path)) {
                throw "EXE source '$path' for app '$id' not found."
            }

            $exe = $path
            $args = $App.installArgs
        }

        'winget' {
            $exe = 'winget.exe'
            $idOrArgs = $App.source

            if (-not $idOrArgs) {
                throw "App '$id' with sourceType 'winget' requires 'source' for id/args."
            }

            $args = "install $idOrArgs --silent --accept-package-agreements --accept-source-agreements"

            if ($App.installArgs) {
                $args += " $($App.installArgs)"
            }
        }

        'choco' {
            $exe = 'choco.exe'
            $pkg = $App.source

            if (-not $pkg) {
                $pkg = $id
            }

            $args = "install $pkg -y"

            if ($App.installArgs) {
                $args += " $($App.installArgs)"
            }
        }

        'msix' {
            $path = $App.source

            if (-not (Test-Path $path)) {
                throw "MSIX source '$path' for app '$id' not found."
            }

            try {
                Add-AppxPackage -Path $path -ErrorAction Stop
                $RunContext | Write-DeployEvent -Level 'Info' -Message "MSIX app '$id' installed successfully."
                $InstallState[$id] = 'Installed'
                return
            }
            catch {
                $RunContext | Write-DeployEvent -Level 'Error' -Message "MSIX install failed for '$id': $($_.Exception.Message)"
                throw
            }
        }

        default {
            throw "Unsupported sourceType '$sourceType' for app '$id'."
        }
    }

    $RunContext | Write-DeployEvent -Level 'Debug' -Message "Launching '$exe' with args '$args' for app '$id'."

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
        throw "Failed to start installer '$exe' for app '$id'."
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    Add-Content -Path $RunContext.RunLogPath -Value $stdout
    if ($stderr) {
        Add-Content -Path $RunContext.RunLogPath -Value $stderr
    }

    if ($proc.ExitCode -ne 0) {
        $RunContext | Write-DeployEvent -Level 'Error' -Message "App '$id' installer exited with code $($proc.ExitCode)."
        throw "Installation failed for app '$id'. Exit code: $($proc.ExitCode)."
    }

    $RunContext | Write-DeployEvent -Level 'Info' -Message "App '$id' installed successfully."
    $InstallState[$id] = 'Installed'
}

function Install-AppSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [string] $SetId
    )

    $set = Get-AppSet -SetId $SetId
    $catalog = Get-AppCatalog
    $InstallState = @{}

    foreach ($appId in $set.appIds) {
        $app = $catalog | Where-Object { $_.id -eq $appId }

        if (-not $app) {
            throw "App '$appId' not found in catalog for set '$SetId'."
        }

        Install-AppPackage -RunContext $RunContext -App $app -InstallState $InstallState
    }
}

