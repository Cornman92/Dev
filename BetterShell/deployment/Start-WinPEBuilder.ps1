#Requires -Version 7.4
#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("TUI","GUI")]
    [string]$Interface = "TUI",
    
    [Parameter(Mandatory=$false)]
    [switch]$NoLogo
)

$ErrorActionPreference = "Stop"
$ModulePath = Join-Path $PSScriptRoot "Modules"

Import-Module (Join-Path $ModulePath "Common-Functions.psm1") -Force
Import-Module (Join-Path $ModulePath "TUI-Framework.psm1") -Force
Import-Module (Join-Path $ModulePath "WinPE-Builder.psm1") -Force
Import-Module (Join-Path $ModulePath "Driver-Manager.psm1") -Force

function Show-Logo {
    $logo = @"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║   ██     ██ ██ ███    ██ ██████  ███████                             ║
║   ██     ██ ██ ████   ██ ██   ██ ██                                  ║
║   ██  █  ██ ██ ██ ██  ██ ██████  █████                               ║
║   ██ ███ ██ ██ ██  ██ ██ ██      ██                                  ║
║   ███ █ ███ ██ ██   ████ ██      ███████                             ║
║                                                                       ║
║              PowerBuilder Suite v2.0 Enhanced                         ║
║           Advanced WinPE Creation & Customization Toolkit             ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
"@
    Write-Host $logo -ForegroundColor Cyan
    Write-Host ""
}

function Show-MainMenu {
    Initialize-TUI
    
    $menu = [TUIMenu]::new(@(
        "1. Create New WinPE Image",
        "2. Manage Drivers",
        "3. Create ISO/USB",
        "4. Profile Manager",
        "5. Driver Repository",
        "6. System Information",
        "7. Settings",
        "8. Exit"
    ), 10, 8, 60)
    
    $window = [TUIWindow]::new(5, 5, 70, 20)
    $window.Title = "WinPE PowerBuilder Suite - Main Menu"
    $window.BorderColor = [ConsoleColor]::Cyan
    $window.Draw()
    
    $statusBar = [TUIStatusBar]::new([Console]::WindowHeight - 1)
    $statusBar.Update("Ready", "Use Arrow Keys to Navigate", "[Enter] Select | [Esc] Exit")
    
    while ($true) {
        $selection = $menu.HandleInput()
        
        switch ($selection) {
            0 { Invoke-CreateImage; break }
            1 { Invoke-ManageDrivers; break }
            2 { Invoke-CreateMedia; break }
            3 { Invoke-ProfileManager; break }
            4 { Invoke-DriverRepository; break }
            5 { Invoke-SystemInfo; break }
            6 { Invoke-Settings; break }
            7 { return }
            -1 { return }
        }
    }
}

function Invoke-CreateImage {
    [Console]::Clear()
    
    $window = [TUIWindow]::new(5, 2, 110, 35)
    $window.Title = "Create New WinPE Image"
    $window.Draw()
    
    $archMenu = [TUIMenu]::new(@("x86", "amd64", "arm64"), 10, 5, 30)
    [Console]::SetCursorPosition(10, 4)
    Write-Host "Select Architecture:" -ForegroundColor Cyan
    $archIndex = $archMenu.HandleInput()
    
    if ($archIndex -eq -1) { return }
    
    $arch = @("x86", "amd64", "arm64")[$archIndex]
    
    $progress = [TUIProgress]::new(10, 15, 90, 100)
    $progress.Label = "Creating WinPE Image..."
    $progress.BarColor = [ConsoleColor]::Green
    
    try {
        $progress.Update(10)
        $image = New-WinPEImage -Architecture $arch
        
        $progress.Update(50)
        
        $result = Show-TUIMessageBox -Title "Success" -Message "WinPE image created successfully!`n`nPath: $($image.WimPath)" -Buttons @("OK", "Open Folder")
        
        if ($result -eq 1) {
            explorer.exe (Split-Path -Parent $image.WimPath)
        }
        
        $progress.Complete()
    }
    catch {
        Show-TUIMessageBox -Title "Error" -Message "Failed to create image: $_" -Buttons @("OK")
    }
}

function Invoke-ManageDrivers {
    [Console]::Clear()
    
    $window = [TUIWindow]::new(5, 2, 110, 35)
    $window.Title = "Driver Manager"
    $window.Draw()
    
    $menu = [TUIMenu]::new(@(
        "Scan for Drivers",
        "Install Drivers to WinPE",
        "View Driver Report",
        "Hardware Information",
        "Back"
    ), 10, 5, 50)
    
    $selection = $menu.HandleInput()
    
    switch ($selection) {
        0 {
            $path = Read-TUIInput -X 10 -Y 15 -Width 80 -Label "Enter driver path:"
            if ($path) {
                $drivers = Find-WinPEDriver -SearchPath $path -Recurse
                Show-TUIMessageBox -Title "Scan Complete" -Message "Found $($drivers.Count) drivers" -Buttons @("OK")
            }
        }
        1 {
            $mountPath = Read-TUIInput -X 10 -Y 15 -Width 80 -Label "Enter WinPE mount path:"
            $driverPath = Read-TUIInput -X 10 -Y 18 -Width 80 -Label "Enter driver source path:"
            
            if ($mountPath -and $driverPath) {
                $result = Install-WinPEDriverBulk -MountPath $mountPath -DriverPath $driverPath
                Show-TUIMessageBox -Title "Installation Complete" -Message "Installed: $($result.Installed)`nFailed: $($result.Failed)" -Buttons @("OK")
            }
        }
        2 {
            $hwInfo = Get-WinPEHardwareInfo
            $missing = Get-WinPEMissingDrivers
            Show-TUIMessageBox -Title "Hardware Info" -Message "Missing Drivers: $($missing.Count)" -Buttons @("OK")
        }
    }
}

function Invoke-CreateMedia {
    [Console]::Clear()
    
    $window = [TUIWindow]::new(5, 2, 110, 30)
    $window.Title = "Create Bootable Media"
    $window.Draw()
    
    $menu = [TUIMenu]::new(@("Create ISO", "Create Bootable USB", "Back"), 10, 5, 40)
    $selection = $menu.HandleInput()
    
    switch ($selection) {
        0 {
            $sourcePath = Read-TUIInput -X 10 -Y 12 -Width 80 -Label "WinPE media folder:"
            $isoPath = Read-TUIInput -X 10 -Y 15 -Width 80 -Label "Output ISO path:"
            
            if ($sourcePath -and $isoPath) {
                try {
                    New-WinPEISO -SourcePath $sourcePath -ISOPath $isoPath
                    Show-TUIMessageBox -Title "Success" -Message "ISO created: $isoPath" -Buttons @("OK")
                }
                catch {
                    Show-TUIMessageBox -Title "Error" -Message $_.Exception.Message -Buttons @("OK")
                }
            }
        }
        1 {
            Show-TUIMessageBox -Title "Warning" -Message "This will ERASE the selected drive!`nContinue?" -Buttons @("Yes", "No")
        }
    }
}

function Invoke-ProfileManager {
    [Console]::Clear()
    
    $window = [TUIWindow]::new(5, 2, 110, 30)
    $window.Title = "Profile Manager"
    $window.Draw()
    
    $menu = [TUIMenu]::new(@("Recovery Profile", "Deployment Profile", "Diagnostics Profile", "Network Profile", "Back"), 10, 5, 40)
    $selection = $menu.HandleInput()
    
    if ($selection -ge 0 -and $selection -le 3) {
        $profiles = @("Recovery", "Deployment", "Diagnostics", "Network")
        $archMenu = [TUIMenu]::new(@("x86", "amd64", "arm64"), 10, 12, 30)
        $archIndex = $archMenu.HandleInput()
        
        if ($archIndex -ne -1) {
            $arch = @("x86", "amd64", "arm64")[$archIndex]
            $outputPath = Read-TUIInput -X 10 -Y 18 -Width 80 -Label "Output ISO path (optional):"
            
            try {
                New-WinPEProfile -ProfileType $profiles[$selection] -Architecture $arch -OutputPath $outputPath
                Show-TUIMessageBox -Title "Success" -Message "Profile created successfully!" -Buttons @("OK")
            }
            catch {
                Show-TUIMessageBox -Title "Error" -Message $_.Exception.Message -Buttons @("OK")
            }
        }
    }
}

function Invoke-DriverRepository {
    [Console]::Clear()
    
    $window = [TUIWindow]::new(5, 2, 110, 30)
    $window.Title = "Driver Repository Manager"
    $window.Draw()
    
    $menu = [TUIMenu]::new(@(
        "Create New Repository",
        "Add Drivers to Repository",
        "Compress Repository",
        "View Repository",
        "Optimize Drivers",
        "Back"
    ), 10, 5, 50)
    
    $selection = $menu.HandleInput()
    
    switch ($selection) {
        0 {
            $path = Read-TUIInput -X 10 -Y 12 -Width 80 -Label "Repository path:"
            if ($path) {
                New-WinPEDriverRepository -RepositoryPath $path
                Show-TUIMessageBox -Title "Success" -Message "Repository created: $path" -Buttons @("OK")
            }
        }
        4 {
            $sourcePath = Read-TUIInput -X 10 -Y 12 -Width 80 -Label "Source driver path:"
            $outputPath = Read-TUIInput -X 10 -Y 15 -Width 80 -Label "Output path:"
            
            if ($sourcePath -and $outputPath) {
                $result = Optimize-WinPEDrivers -SourcePath $sourcePath -OutputPath $outputPath
                Show-TUIMessageBox -Title "Optimization Complete" -Message "Original: $($result.Original)`nOptimized: $($result.Optimized)`nReduction: $($result.SizeReduction)%" -Buttons @("OK")
            }
        }
    }
}

function Invoke-SystemInfo {
    [Console]::Clear()
    
    $window = [TUIWindow]::new(5, 2, 110, 35)
    $window.Title = "System Information"
    $window.Draw()
    
    $info = Get-WinPEHardwareInfo
    
    $y = 5
    [Console]::SetCursorPosition(10, $y++)
    Write-Host "Computer: $($info.Computer.Manufacturer) $($info.Computer.Model)" -ForegroundColor Cyan
    [Console]::SetCursorPosition(10, $y++)
    Write-Host "CPU: $($info.CPU.Name)" -ForegroundColor Cyan
    [Console]::SetCursorPosition(10, $y++)
    Write-Host "Memory: $([math]::Round($info.Memory, 2)) GB" -ForegroundColor Cyan
    
    $missing = Get-WinPEMissingDrivers
    [Console]::SetCursorPosition(10, $y++ + 2)
    Write-Host "Missing Drivers: $($missing.Count)" -ForegroundColor Yellow
    
    [Console]::SetCursorPosition(10, [Console]::WindowHeight - 3)
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
}

function Invoke-Settings {
    [Console]::Clear()
    
    $window = [TUIWindow]::new(5, 2, 110, 25)
    $window.Title = "Settings"
    $window.Draw()
    
    $menu = [TUIMenu]::new(@("Change Theme", "Configure Paths", "Log Level", "Back"), 10, 5, 40)
    $selection = $menu.HandleInput()
    
    switch ($selection) {
        0 {
            $themeMenu = [TUIMenu]::new(@("Dark", "Light"), 10, 12, 30)
            $themeIndex = $themeMenu.HandleInput()
            if ($themeIndex -ne -1) {
                Set-TUITheme -ThemeName @("Dark", "Light")[$themeIndex]
            }
        }
        2 {
            $levelMenu = [TUIMenu]::new(@("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"), 10, 12, 30)
            $levelIndex = $levelMenu.HandleInput()
            if ($levelIndex -ne -1) {
                Set-LogLevel -Level @("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")[$levelIndex]
                Show-TUIMessageBox -Title "Log Level" -Message "Log level updated" -Buttons @("OK")
            }
        }
    }
}

try {
    if (-not $NoLogo) {
        Show-Logo
        Start-Sleep -Seconds 1
    }
    
    Initialize-LogFile
    Write-LogMessage "Application started" -Component "Main"
    
    if ($Interface -eq "TUI") {
        Show-MainMenu
    } else {
        Write-Host "GUI interface not yet implemented. Launching TUI..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        Show-MainMenu
    }
    
    Write-LogMessage "Application closed normally" -Component "Main"
}
catch {
    Write-LogMessage "Application crashed: $_" -Level "CRITICAL" -Component "Main" -Exception $_.Exception
    Write-Host "Fatal error: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
finally {
    [Console]::CursorVisible = $true
    [Console]::Clear()
}
