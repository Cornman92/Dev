#Requires -Version 7.0
using namespace System.Collections.Concurrent
using namespace System.Collections.Generic

$script:PluginRegistry = [ConcurrentDictionary[string, hashtable]]::new()
$script:PluginSearchPaths = [List[string]]::new()

function Register-B11Plugin { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Path, [string]$Version = '1.0.0', [string]$Description = '', [string[]]$Dependencies = @(), [hashtable]$Metadata = @{})
    if (-not (Test-Path $Path)) { Write-Error "Plugin path '$Path' not found." -ErrorAction Stop; return }
    $plugin = @{ Name = $Name; Path = $Path; Version = $Version; Description = $Description; Dependencies = $Dependencies; Metadata = $Metadata; IsLoaded = $false; LoadedAt = $null; Commands = @() }
    $null = $script:PluginRegistry.TryAdd($Name, $plugin)
    [PSCustomObject]@{ PSTypeName = 'B11.Plugin'; Name = $Name; Version = $Version; Status = 'Registered' } }

function Import-B11Plugin { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory)][string]$Name)
    if (-not $script:PluginRegistry.ContainsKey($Name)) { Write-Error "Plugin '$Name' not registered." -ErrorAction Stop; return }
    $p = $script:PluginRegistry[$Name]
    foreach ($dep in $p.Dependencies) { if (-not $script:PluginRegistry.ContainsKey($dep) -or -not $script:PluginRegistry[$dep].IsLoaded) { Import-B11Plugin -Name $dep } }
    try { Import-Module $p.Path -Force -Global; $p.IsLoaded = $true; $p.LoadedAt = [datetime]::UtcNow
        $mod = Get-Module -Name ([System.IO.Path]::GetFileNameWithoutExtension($p.Path)); $p.Commands = @($mod.ExportedFunctions.Keys)
        [PSCustomObject]@{ PSTypeName = 'B11.Plugin'; Name = $Name; Status = 'Loaded'; Commands = $p.Commands.Count }
    } catch { Write-Error "Failed to load plugin '$Name': $_" -ErrorAction Stop } }

function Remove-B11Plugin { [CmdletBinding(SupportsShouldProcess)][OutputType([void])] param([Parameter(Mandatory)][string]$Name)
    if ($PSCmdlet.ShouldProcess($Name, 'Remove plugin')) { if ($script:PluginRegistry.ContainsKey($Name) -and $script:PluginRegistry[$Name].IsLoaded) { Remove-Module -Name ([System.IO.Path]::GetFileNameWithoutExtension($script:PluginRegistry[$Name].Path)) -Force -ErrorAction SilentlyContinue }
        $r = $null; $null = $script:PluginRegistry.TryRemove($Name, [ref]$r) } }

function Get-B11Plugin { [CmdletBinding()][OutputType([PSCustomObject])] param([string]$Name, [switch]$LoadedOnly)
    $plugins = if ($Name) { if ($script:PluginRegistry.ContainsKey($Name)) { @($script:PluginRegistry[$Name]) } else { @() } } else { $script:PluginRegistry.Values }
    if ($LoadedOnly) { $plugins = $plugins | Where-Object { $_.IsLoaded } }
    foreach ($p in $plugins) { [PSCustomObject]@{ PSTypeName = 'B11.Plugin'; Name = $p.Name; Version = $p.Version; Description = $p.Description; IsLoaded = $p.IsLoaded; Commands = $p.Commands.Count; Dependencies = $p.Dependencies; LoadedAt = $p.LoadedAt } } }

function Test-B11PluginCompatibility { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory)][string]$Name)
    if (-not $script:PluginRegistry.ContainsKey($Name)) { Write-Error "Plugin '$Name' not found." -ErrorAction Stop; return }
    $p = $script:PluginRegistry[$Name]; $issues = [List[string]]::new()
    if (-not (Test-Path $p.Path)) { $issues.Add("Module path missing: $($p.Path)") }
    foreach ($dep in $p.Dependencies) { if (-not $script:PluginRegistry.ContainsKey($dep)) { $issues.Add("Missing dependency: $dep") } }
    $errors = $null; $null = [System.Management.Automation.Language.Parser]::ParseFile($p.Path, [ref]$null, [ref]$errors)
    if ($errors.Count -gt 0) { $issues.Add("Syntax errors: $($errors.Count)") }
    [PSCustomObject]@{ PSTypeName = 'B11.PluginCompat'; Name = $Name; IsCompatible = ($issues.Count -eq 0); Issues = $issues } }

function Add-B11PluginSearchPath { [CmdletBinding()][OutputType([void])] param([Parameter(Mandatory)][ValidateScript({ Test-Path $_ -PathType Container })][string]$Path)
    if ($Path -notin $script:PluginSearchPaths) { $script:PluginSearchPaths.Add($Path) } }

function Find-B11Plugin { [CmdletBinding()][OutputType([PSCustomObject[]])] param([string]$Filter = '*')
    foreach ($searchPath in $script:PluginSearchPaths) { Get-ChildItem -Path $searchPath -Filter '*.psd1' -Recurse -Depth 2 | Where-Object { $_.BaseName -like $Filter } | ForEach-Object {
        $manifest = Import-PowerShellDataFile $_.FullName -ErrorAction SilentlyContinue
        if ($manifest) { [PSCustomObject]@{ PSTypeName = 'B11.DiscoveredPlugin'; Name = $_.BaseName; Path = $_.FullName; Version = $manifest.ModuleVersion; Description = $manifest.Description } } } } }

function Enable-B11Plugin { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory)][string]$Name)
    if (-not $script:PluginRegistry[$Name].IsLoaded) { Import-B11Plugin -Name $Name } else { [PSCustomObject]@{ PSTypeName = 'B11.Plugin'; Name = $Name; Status = 'Already loaded' } } }

function Disable-B11Plugin { [CmdletBinding(SupportsShouldProcess)][OutputType([void])] param([Parameter(Mandatory)][string]$Name)
    if ($PSCmdlet.ShouldProcess($Name, 'Disable plugin')) { if ($script:PluginRegistry.ContainsKey($Name)) {
        $p = $script:PluginRegistry[$Name]; if ($p.IsLoaded) { Remove-Module -Name ([System.IO.Path]::GetFileNameWithoutExtension($p.Path)) -Force -ErrorAction SilentlyContinue; $p.IsLoaded = $false } } } }

function Update-B11Plugin { [CmdletBinding(SupportsShouldProcess)][OutputType([PSCustomObject])] param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$NewPath, [string]$NewVersion)
    if ($PSCmdlet.ShouldProcess($Name, 'Update plugin')) { if (-not $script:PluginRegistry.ContainsKey($Name)) { Write-Error "Plugin '$Name' not found." -ErrorAction Stop; return }
        $wasLoaded = $script:PluginRegistry[$Name].IsLoaded; if ($wasLoaded) { Disable-B11Plugin -Name $Name }
        $script:PluginRegistry[$Name].Path = $NewPath; if ($NewVersion) { $script:PluginRegistry[$Name].Version = $NewVersion }
        if ($wasLoaded) { Import-B11Plugin -Name $Name }
        [PSCustomObject]@{ PSTypeName = 'B11.Plugin'; Name = $Name; Version = $script:PluginRegistry[$Name].Version; Status = 'Updated' } } }

function Get-B11PluginStatistics { [CmdletBinding()][OutputType([PSCustomObject])] param()
    $all = $script:PluginRegistry.Values; $loaded = ($all | Where-Object { $_.IsLoaded }).Count
    [PSCustomObject]@{ PSTypeName = 'B11.PluginStats'; TotalRegistered = $all.Count; LoadedCount = $loaded; TotalCommands = ($all | Where-Object { $_.IsLoaded } | ForEach-Object { $_.Commands.Count } | Measure-Object -Sum).Sum; SearchPaths = $script:PluginSearchPaths.Count } }

function Export-B11PluginConfig { [CmdletBinding()][OutputType([void])] param([Parameter(Mandatory)][string]$Path)
    $config = $script:PluginRegistry.Values | ForEach-Object { @{ Name = $_.Name; Path = $_.Path; Version = $_.Version; Description = $_.Description; Dependencies = $_.Dependencies } }
    @{ Plugins = $config; SearchPaths = @($script:PluginSearchPaths) } | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Encoding utf8 }

function Import-B11PluginConfig { [CmdletBinding()][OutputType([void])] param([Parameter(Mandatory)][ValidateScript({ Test-Path $_ })][string]$Path)
    $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
    foreach ($sp in $config.SearchPaths) { Add-B11PluginSearchPath -Path $sp -ErrorAction SilentlyContinue }
    foreach ($p in $config.Plugins) { Register-B11Plugin -Name $p.Name -Path $p.Path -Version $p.Version -Description $p.Description -Dependencies @($p.Dependencies) -ErrorAction SilentlyContinue } }

Export-ModuleMember -Function @(
    'Register-B11Plugin', 'Import-B11Plugin', 'Remove-B11Plugin', 'Get-B11Plugin',
    'Test-B11PluginCompatibility', 'Add-B11PluginSearchPath', 'Find-B11Plugin',
    'Enable-B11Plugin', 'Disable-B11Plugin', 'Update-B11Plugin',
    'Get-B11PluginStatistics', 'Export-B11PluginConfig', 'Import-B11PluginConfig'
)
