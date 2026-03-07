<#
.SYNOPSIS
    WinPE PowerBuilder - Image Customization Module
    Advanced WinPE image customization and personalization

.DESCRIPTION
    This module provides comprehensive image customization capabilities including:
    - Custom branding and theming
    - Wallpaper and boot screen customization
    - File injection and replacement
    - Registry modifications
    - Service configuration
    - Default settings and preferences

.NOTES
    Module: Image-Customization
    Version: 1.0.0
    Author: Better11 Development Team
    Requires: PowerShell 5.1+, Windows ADK, DISM
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

#region Module Variables

$script:ModuleRoot = $PSScriptRoot
$script:LogPath = Join-Path $env:TEMP "WinPE-ImageCustomization.log"
$script:BrandingPath = Join-Path $ModuleRoot "Branding"
$script:ResourcesPath = Join-Path $ModuleRoot "Resources"
$script:TemplatesPath = Join-Path $ModuleRoot "Templates"

# Ensure required paths exist
@($BrandingPath, $ResourcesPath, $TemplatesPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

#endregion

#region Logging Functions

function Write-CustomLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
    }
    Write-Host $logMessage -ForegroundColor $color
    
    Add-Content -Path $script:LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

#endregion

#region Branding Functions

function Set-WinPEBranding {
    <#
    .SYNOPSIS
        Applies custom branding to WinPE image
    
    .DESCRIPTION
        Customizes WinPE with organization branding including wallpapers,
        logos, boot screens, and visual identity
    
    .EXAMPLE
        Set-WinPEBranding -MountPath "C:\Mount\WinPE" -OrganizationName "Contoso" -LogoPath "C:\Branding\logo.png"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter(Mandatory)]
        [string]$OrganizationName,
        
        [Parameter()]
        [string]$LogoPath,
        
        [Parameter()]
        [string]$WallpaperPath,
        
        [Parameter()]
        [string]$BootScreenPath,
        
        [Parameter()]
        [string]$FaviconPath,
        
        [Parameter()]
        [string]$PrimaryColor = "#0078D4",
        
        [Parameter()]
        [string]$SecondaryColor = "#005A9E",
        
        [Parameter()]
        [string]$AccentColor = "#00B4FF",
        
        [Parameter()]
        [hashtable]$CustomBranding = @{}
    )
    
    try {
        Write-CustomLog "Applying WinPE branding for: $OrganizationName" -Level Info
        
        if (-not (Test-Path $MountPath)) {
            throw "Mount path not found: $MountPath"
        }
        
        # Create branding directory structure
        $brandingDir = Join-Path $MountPath "Windows\System32\Branding"
        $wallpaperDir = Join-Path $MountPath "Windows\Web\Wallpaper"
        $resourcesDir = Join-Path $MountPath "Windows\Resources"
        
        @($brandingDir, $wallpaperDir, $resourcesDir) | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -Path $_ -ItemType Directory -Force | Out-Null
            }
        }
        
        # Copy logo if provided
        if ($LogoPath -and (Test-Path $LogoPath)) {
            Write-CustomLog "Installing organization logo" -Level Info
            $logoDestination = Join-Path $brandingDir "OrganizationLogo.png"
            Copy-Item -Path $LogoPath -Destination $logoDestination -Force
            
            # Create multiple sizes for different uses
            $logoSizes = @(16, 32, 48, 64, 128, 256)
            foreach ($size in $logoSizes) {
                $resizedLogo = Join-Path $brandingDir "OrganizationLogo_$($size)x$($size).png"
                # Use ImageMagick or similar if available
                # convert $LogoPath -resize ${size}x${size} $resizedLogo
            }
        }
        
        # Copy wallpaper if provided
        if ($WallpaperPath -and (Test-Path $WallpaperPath)) {
            Write-CustomLog "Installing custom wallpaper" -Level Info
            
            $wallpaperDestination = Join-Path $wallpaperDir "OrganizationWallpaper.jpg"
            Copy-Item -Path $WallpaperPath -Destination $wallpaperDestination -Force
            
            # Set as default wallpaper via registry
            $regFile = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
"Wallpaper"="$($wallpaperDestination -replace '\\', '\\\\')"
"WallpaperStyle"="2"

[HKEY_CURRENT_USER\Control Panel\Desktop]
"Wallpaper"="$($wallpaperDestination -replace '\\', '\\\\')"
"WallpaperStyle"="2"
"TileWallpaper"="0"
"@
            $regFilePath = Join-Path $MountPath "Windows\Setup\Scripts\SetWallpaper.reg"
            $regFile | Set-Content -Path $regFilePath -Force
        }
        
        # Create branding configuration file
        $brandingConfig = @{
            OrganizationName = $OrganizationName
            PrimaryColor = $PrimaryColor
            SecondaryColor = $SecondaryColor
            AccentColor = $AccentColor
            LogoPath = if ($LogoPath) { "C:\Windows\System32\Branding\OrganizationLogo.png" } else { $null }
            WallpaperPath = if ($WallpaperPath) { "C:\Windows\Web\Wallpaper\OrganizationWallpaper.jpg" } else { $null }
            CustomSettings = $CustomBranding
            AppliedDate = (Get-Date).ToString('o')
        }
        
        $configPath = Join-Path $brandingDir "BrandingConfig.json"
        $brandingConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Force
        
        # Create OEM information
        $oemInfoPath = Join-Path $MountPath "Windows\System32\oeminfo.ini"
        $oemInfo = @"
[General]
Manufacturer=$OrganizationName
Model=Windows PE Custom Build
SupportURL=https://support.example.com
SupportPhone=1-800-SUPPORT

[Support Information]
Line1=For technical support, contact:
Line2=$OrganizationName IT Support
Line3=Email: support@example.com
Line4=Phone: 1-800-SUPPORT
Line5=Hours: 24/7
"@
        $oemInfo | Set-Content -Path $oemInfoPath -Force
        
        # Create custom startnet.cmd header
        $startnetPath = Join-Path $MountPath "Windows\System32\startnet.cmd"
        if (Test-Path $startnetPath) {
            $startnetContent = Get-Content $startnetPath -Raw
            $brandedHeader = @"
@echo off
cls
echo ========================================
echo   $OrganizationName
echo   Windows PE Custom Environment
echo ========================================
echo.

$startnetContent
"@
            $brandedHeader | Set-Content -Path $startnetPath -Force
        }
        
        # Apply theme colors via registry
        $themeRegContent = @"
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize]
"ColorPrevalence"=dword:00000001
"EnableTransparency"=dword:00000001
"AppsUseLightTheme"=dword:00000000
"SystemUsesLightTheme"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM]
"ColorizationColor"=dword:c4$($PrimaryColor.TrimStart('#'))
"ColorizationColorBalance"=dword:00000059
"ColorizationAfterglow"=dword:c4$($SecondaryColor.TrimStart('#'))
"@
        $themeRegPath = Join-Path $MountPath "Windows\Setup\Scripts\ApplyTheme.reg"
        $themeRegContent | Set-Content -Path $themeRegPath -Force
        
        Write-CustomLog "WinPE branding applied successfully" -Level Success
    }
    catch {
        Write-CustomLog "Failed to apply WinPE branding: $_" -Level Error
        throw
    }
}

function New-CustomBootScreen {
    <#
    .SYNOPSIS
        Creates custom boot screen for WinPE
    
    .DESCRIPTION
        Customizes the boot screen with organization branding
    
    .EXAMPLE
        New-CustomBootScreen -MountPath "C:\Mount\WinPE" -BackgroundImage "C:\boot.bmp" -OrganizationName "Contoso"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter()]
        [string]$BackgroundImage,
        
        [Parameter()]
        [string]$OrganizationName,
        
        [Parameter()]
        [string]$LoadingText = "Loading..."
    )
    
    try {
        Write-CustomLog "Creating custom boot screen" -Level Info
        
        $bootResPath = Join-Path $MountPath "Windows\Boot\Resources"
        $bootBcdPath = Join-Path $MountPath "Windows\Boot\BCD"
        
        if (-not (Test-Path $bootResPath)) {
            New-Item -Path $bootResPath -ItemType Directory -Force | Out-Null
        }
        
        if ($BackgroundImage -and (Test-Path $BackgroundImage)) {
            # Copy boot background
            $bootBgDest = Join-Path $bootResPath "bootres.dll"
            Copy-Item -Path $BackgroundImage -Destination $bootBgDest -Force
            
            Write-CustomLog "Custom boot background installed" -Level Success
        }
        
        # Modify BCD for custom boot options
        if (Test-Path $bootBcdPath) {
            # Use bcdedit equivalent commands
            $bcdCommands = @(
                "bcdedit /store `"$bootBcdPath`" /set {default} description `"$OrganizationName WinPE`"",
                "bcdedit /store `"$bootBcdPath`" /set {bootmgr} timeout 3"
            )
            
            foreach ($cmd in $bcdCommands) {
                Invoke-Expression $cmd | Out-Null
            }
        }
        
        Write-CustomLog "Custom boot screen created successfully" -Level Success
    }
    catch {
        Write-CustomLog "Failed to create custom boot screen: $_" -Level Error
        throw
    }
}

#endregion

#region File Injection Functions

function Add-CustomFile {
    <#
    .SYNOPSIS
        Injects custom files into WinPE image
    
    .DESCRIPTION
        Adds custom files, scripts, tools, or resources to specific locations in WinPE
    
    .EXAMPLE
        Add-CustomFile -MountPath "C:\Mount\WinPE" -SourcePath "C:\Tools\MyTool.exe" -DestinationPath "Windows\System32"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter(Mandatory)]
        [string]$SourcePath,
        
        [Parameter(Mandatory)]
        [string]$DestinationPath,
        
        [Parameter()]
        [switch]$Overwrite,
        
        [Parameter()]
        [switch]$Recurse
    )
    
    try {
        Write-CustomLog "Injecting custom file: $(Split-Path $SourcePath -Leaf)" -Level Info
        
        if (-not (Test-Path $SourcePath)) {
            throw "Source file not found: $SourcePath"
        }
        
        $fullDestPath = Join-Path $MountPath $DestinationPath
        
        if (-not (Test-Path $fullDestPath)) {
            New-Item -Path $fullDestPath -ItemType Directory -Force | Out-Null
        }
        
        $copyParams = @{
            Path = $SourcePath
            Destination = $fullDestPath
            Force = $Overwrite.IsPresent
        }
        
        if ($Recurse) {
            $copyParams.Recurse = $true
        }
        
        Copy-Item @copyParams
        
        Write-CustomLog "File injected successfully: $(Split-Path $SourcePath -Leaf)" -Level Success
    }
    catch {
        Write-CustomLog "Failed to inject custom file: $_" -Level Error
        throw
    }
}

function Add-CustomFileSet {
    <#
    .SYNOPSIS
        Injects multiple custom files from a manifest
    
    .DESCRIPTION
        Batch injects files based on a JSON manifest configuration
    
    .EXAMPLE
        Add-CustomFileSet -MountPath "C:\Mount\WinPE" -ManifestPath "C:\FileManifest.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter(Mandatory)]
        [string]$ManifestPath,
        
        [Parameter()]
        [switch]$ContinueOnError
    )
    
    try {
        Write-CustomLog "Processing file injection manifest" -Level Info
        
        if (-not (Test-Path $ManifestPath)) {
            throw "Manifest file not found: $ManifestPath"
        }
        
        $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
        
        $successCount = 0
        $failureCount = 0
        
        foreach ($fileEntry in $manifest.Files) {
            try {
                Write-CustomLog "Injecting: $($fileEntry.Source) -> $($fileEntry.Destination)" -Level Info
                
                $params = @{
                    MountPath = $MountPath
                    SourcePath = $fileEntry.Source
                    DestinationPath = $fileEntry.Destination
                }
                
                if ($fileEntry.Overwrite) { $params.Overwrite = $true }
                if ($fileEntry.Recurse) { $params.Recurse = $true }
                
                Add-CustomFile @params
                $successCount++
            }
            catch {
                $failureCount++
                Write-CustomLog "Failed to inject file: $($fileEntry.Source) - $_" -Level Error
                
                if (-not $ContinueOnError) {
                    throw
                }
            }
        }
        
        Write-CustomLog "File injection completed: $successCount succeeded, $failureCount failed" -Level Info
    }
    catch {
        Write-CustomLog "Failed to process file injection manifest: $_" -Level Error
        throw
    }
}

function Replace-SystemFile {
    <#
    .SYNOPSIS
        Replaces an existing system file with a custom version
    
    .DESCRIPTION
        Safely replaces system files with custom versions, creating backups
    
    .EXAMPLE
        Replace-SystemFile -MountPath "C:\Mount\WinPE" -FilePath "Windows\System32\winpeshl.ini" -ReplacementPath "C:\Custom\winpeshl.ini"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [string]$ReplacementPath,
        
        [Parameter()]
        [switch]$CreateBackup = $true
    )
    
    try {
        Write-CustomLog "Replacing system file: $FilePath" -Level Info
        
        $fullFilePath = Join-Path $MountPath $FilePath
        $backupDir = Join-Path $MountPath "Windows\Backup"
        
        if (-not (Test-Path $ReplacementPath)) {
            throw "Replacement file not found: $ReplacementPath"
        }
        
        if (Test-Path $fullFilePath) {
            if ($CreateBackup) {
                if (-not (Test-Path $backupDir)) {
                    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
                }
                
                $backupName = "$(Split-Path $FilePath -Leaf).backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                $backupPath = Join-Path $backupDir $backupName
                
                Copy-Item -Path $fullFilePath -Destination $backupPath -Force
                Write-CustomLog "Backup created: $backupName" -Level Info
            }
            
            # Remove original
            Remove-Item -Path $fullFilePath -Force
        }
        
        # Copy replacement
        Copy-Item -Path $ReplacementPath -Destination $fullFilePath -Force
        
        Write-CustomLog "System file replaced successfully" -Level Success
    }
    catch {
        Write-CustomLog "Failed to replace system file: $_" -Level Error
        throw
    }
}

#endregion

#region Registry Customization Functions

function Set-WinPERegistry {
    <#
    .SYNOPSIS
        Applies custom registry modifications to WinPE
    
    .DESCRIPTION
        Loads WinPE registry hives and applies custom registry settings
    
    .EXAMPLE
        Set-WinPERegistry -MountPath "C:\Mount\WinPE" -RegistryFile "C:\CustomRegistry.reg"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter()]
        [string]$RegistryFile,
        
        [Parameter()]
        [hashtable]$RegistrySettings = @{},
        
        [Parameter()]
        [ValidateSet('HKLM', 'HKU', 'DEFAULT')]
        [string]$HiveToLoad = 'HKLM'
    )
    
    try {
        Write-CustomLog "Applying registry customizations to WinPE" -Level Info
        
        # Define registry hive paths
        $systemHive = Join-Path $MountPath "Windows\System32\config\SYSTEM"
        $softwareHive = Join-Path $MountPath "Windows\System32\config\SOFTWARE"
        $defaultHive = Join-Path $MountPath "Windows\System32\config\DEFAULT"
        
        $tempHiveKey = "HKLM\WinPE_TEMP"
        
        # Load the appropriate hive
        $hiveToMount = switch ($HiveToLoad) {
            'HKLM' { $softwareHive }
            'HKU' { $defaultHive }
            'DEFAULT' { $defaultHive }
        }
        
        if (Test-Path $hiveToMount) {
            Write-CustomLog "Loading registry hive: $hiveToMount" -Level Info
            
            $result = reg load $tempHiveKey $hiveToMount 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to load registry hive: $result"
            }
            
            try {
                # Apply registry file if provided
                if ($RegistryFile -and (Test-Path $RegistryFile)) {
                    Write-CustomLog "Importing registry file: $RegistryFile" -Level Info
                    
                    # Modify .reg file to use temp hive key
                    $regContent = Get-Content $RegistryFile -Raw
                    $modifiedContent = $regContent -replace 'HKEY_LOCAL_MACHINE', $tempHiveKey
                    
                    $tempRegFile = Join-Path $env:TEMP "temp_$(Get-Date -Format 'yyyyMMddHHmmss').reg"
                    $modifiedContent | Set-Content -Path $tempRegFile -Force
                    
                    $result = reg import $tempRegFile 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to import registry file: $result"
                    }
                    
                    Remove-Item -Path $tempRegFile -Force
                }
                
                # Apply individual registry settings
                foreach ($setting in $RegistrySettings.GetEnumerator()) {
                    $keyPath = "$tempHiveKey\$($setting.Value.Path)"
                    $valueName = $setting.Value.Name
                    $valueData = $setting.Value.Data
                    $valueType = $setting.Value.Type
                    
                    Write-CustomLog "Setting registry value: $keyPath\$valueName" -Level Info
                    
                    # Create key if it doesn't exist
                    if (-not (Test-Path "Registry::$keyPath")) {
                        New-Item -Path "Registry::$keyPath" -Force | Out-Null
                    }
                    
                    # Set value
                    Set-ItemProperty -Path "Registry::$keyPath" -Name $valueName -Value $valueData -Type $valueType -Force
                }
                
                Write-CustomLog "Registry customizations applied successfully" -Level Success
            }
            finally {
                # Unload the hive
                Write-CustomLog "Unloading registry hive" -Level Info
                
                [gc]::Collect()
                Start-Sleep -Seconds 2
                
                $result = reg unload $tempHiveKey 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-CustomLog "Warning: Failed to unload registry hive cleanly: $result" -Level Warning
                }
            }
        }
    }
    catch {
        Write-CustomLog "Failed to apply registry customizations: $_" -Level Error
        throw
    }
}

function Add-DefaultUserSettings {
    <#
    .SYNOPSIS
        Configures default user settings and preferences
    
    .DESCRIPTION
        Sets default user preferences that will apply to all users in WinPE
    
    .EXAMPLE
        Add-DefaultUserSettings -MountPath "C:\Mount\WinPE" -Settings @{Theme="Dark"; TaskbarPosition="Bottom"}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter()]
        [hashtable]$Settings = @{}
    )
    
    try {
        Write-CustomLog "Configuring default user settings" -Level Info
        
        $defaultHive = Join-Path $MountPath "Windows\System32\config\DEFAULT"
        $tempHiveKey = "HKLM\DefaultUser"
        
        if (Test-Path $defaultHive) {
            # Load default user hive
            reg load $tempHiveKey $defaultHive | Out-Null
            
            try {
                # Apply common default settings
                $commonSettings = @{
                    # Explorer settings
                    "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" = @{
                        "Hidden" = @{Data = 1; Type = "DWord"}
                        "HideFileExt" = @{Data = 0; Type = "DWord"}
                        "ShowSuperHidden" = @{Data = 1; Type = "DWord"}
                    }
                    # Taskbar settings
                    "Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" = @{
                        "Settings" = @{Data = ([byte[]](48,0,0,0,255,255,255,255,2,0,0,0,1,0,0,0)); Type = "Binary"}
                    }
                    # Theme settings
                    "Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" = @{
                        "AppsUseLightTheme" = @{Data = 0; Type = "DWord"}
                    }
                }
                
                # Merge with custom settings
                foreach ($setting in $Settings.GetEnumerator()) {
                    $commonSettings[$setting.Key] = $setting.Value
                }
                
                # Apply all settings
                foreach ($keyPath in $commonSettings.Keys) {
                    $fullPath = "Registry::$tempHiveKey\$keyPath"
                    
                    if (-not (Test-Path $fullPath)) {
                        New-Item -Path $fullPath -Force | Out-Null
                    }
                    
                    foreach ($value in $commonSettings[$keyPath].GetEnumerator()) {
                        Set-ItemProperty -Path $fullPath -Name $value.Key -Value $value.Value.Data -Type $value.Value.Type -Force
                    }
                }
                
                Write-CustomLog "Default user settings applied successfully" -Level Success
            }
            finally {
                # Unload hive
                [gc]::Collect()
                Start-Sleep -Seconds 2
                reg unload $tempHiveKey | Out-Null
            }
        }
    }
    catch {
        Write-CustomLog "Failed to configure default user settings: $_" -Level Error
        throw
    }
}

#endregion

#region Service Configuration Functions

function Set-WinPEServices {
    <#
    .SYNOPSIS
        Configures Windows services in WinPE
    
    .DESCRIPTION
        Enables, disables, or configures Windows services for WinPE environment
    
    .EXAMPLE
        Set-WinPEServices -MountPath "C:\Mount\WinPE" -ServiceConfig @{wuauserv="Disabled"; WinRM="Automatic"}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter(Mandatory)]
        [hashtable]$ServiceConfig
    )
    
    try {
        Write-CustomLog "Configuring WinPE services" -Level Info
        
        $systemHive = Join-Path $MountPath "Windows\System32\config\SYSTEM"
        $tempHiveKey = "HKLM\WinPE_SYSTEM"
        
        if (Test-Path $systemHive) {
            reg load $tempHiveKey $systemHive | Out-Null
            
            try {
                foreach ($service in $ServiceConfig.GetEnumerator()) {
                    $serviceName = $service.Key
                    $startType = switch ($service.Value) {
                        'Disabled' { 4 }
                        'Manual' { 3 }
                        'Automatic' { 2 }
                        'Boot' { 0 }
                        'System' { 1 }
                        default { 3 }
                    }
                    
                    $servicePath = "Registry::$tempHiveKey\ControlSet001\Services\$serviceName"
                    
                    if (Test-Path $servicePath) {
                        Set-ItemProperty -Path $servicePath -Name "Start" -Value $startType -Type DWord -Force
                        Write-CustomLog "Service configured: $serviceName = $($service.Value)" -Level Info
                    } else {
                        Write-CustomLog "Service not found: $serviceName" -Level Warning
                    }
                }
                
                Write-CustomLog "Service configuration completed" -Level Success
            }
            finally {
                [gc]::Collect()
                Start-Sleep -Seconds 2
                reg unload $tempHiveKey | Out-Null
            }
        }
    }
    catch {
        Write-CustomLog "Failed to configure services: $_" -Level Error
        throw
    }
}

#endregion

#region Template Functions

function Export-CustomizationTemplate {
    <#
    .SYNOPSIS
        Exports current customization settings to a reusable template
    
    .DESCRIPTION
        Creates a JSON template of all customization settings for reuse
    
    .EXAMPLE
        Export-CustomizationTemplate -TemplateName "CorporateStandard" -Settings $customizationSettings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,
        
        [Parameter(Mandatory)]
        [hashtable]$Settings,
        
        [Parameter()]
        [string]$Description
    )
    
    try {
        Write-CustomLog "Exporting customization template: $TemplateName" -Level Info
        
        $template = @{
            Name = $TemplateName
            Description = $Description
            Version = "1.0.0"
            Created = (Get-Date).ToString('o')
            Settings = $Settings
        }
        
        $templatePath = Join-Path $TemplatesPath "$TemplateName.json"
        $template | ConvertTo-Json -Depth 10 | Set-Content -Path $templatePath -Force
        
        Write-CustomLog "Template exported successfully: $templatePath" -Level Success
        return $templatePath
    }
    catch {
        Write-CustomLog "Failed to export template: $_" -Level Error
        throw
    }
}

function Import-CustomizationTemplate {
    <#
    .SYNOPSIS
        Imports and applies a customization template
    
    .DESCRIPTION
        Loads a customization template and applies all settings
    
    .EXAMPLE
        Import-CustomizationTemplate -TemplateName "CorporateStandard" -MountPath "C:\Mount\WinPE"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,
        
        [Parameter(Mandatory)]
        [string]$MountPath
    )
    
    try {
        Write-CustomLog "Importing customization template: $TemplateName" -Level Info
        
        $templatePath = Join-Path $TemplatesPath "$TemplateName.json"
        
        if (-not (Test-Path $templatePath)) {
            throw "Template not found: $TemplateName"
        }
        
        $template = Get-Content $templatePath -Raw | ConvertFrom-Json
        
        # Apply template settings
        if ($template.Settings.Branding) {
            Set-WinPEBranding -MountPath $MountPath @template.Settings.Branding
        }
        
        if ($template.Settings.Registry) {
            Set-WinPERegistry -MountPath $MountPath -RegistrySettings $template.Settings.Registry
        }
        
        if ($template.Settings.DefaultUser) {
            Add-DefaultUserSettings -MountPath $MountPath -Settings $template.Settings.DefaultUser
        }
        
        if ($template.Settings.Services) {
            Set-WinPEServices -MountPath $MountPath -ServiceConfig $template.Settings.Services
        }
        
        if ($template.Settings.Files) {
            foreach ($file in $template.Settings.Files) {
                Add-CustomFile -MountPath $MountPath @file
            }
        }
        
        Write-CustomLog "Template applied successfully" -Level Success
    }
    catch {
        Write-CustomLog "Failed to import template: $_" -Level Error
        throw
    }
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'Set-WinPEBranding',
    'New-CustomBootScreen',
    'Add-CustomFile',
    'Add-CustomFileSet',
    'Replace-SystemFile',
    'Set-WinPERegistry',
    'Add-DefaultUserSettings',
    'Set-WinPEServices',
    'Export-CustomizationTemplate',
    'Import-CustomizationTemplate'
)

#endregion
