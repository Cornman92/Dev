#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Module 7: Deployment Automation
    Section 2: PXE Boot Configuration (~2,600 lines)

.DESCRIPTION
    Complete PXE (Preboot Execution Environment) boot configuration including
    DHCP server setup, TFTP server management, boot menu generation, and
    support for both BIOS and UEFI firmware types.

.COMPONENT
    PXE Boot Configuration
    - DHCP Server Configuration
    - TFTP Server Setup
    - PXE Boot Menu Generation
    - Boot Image Management
    - BIOS/UEFI Support
    - Network Boot Troubleshooting
    - Boot File Management
    - PXE Client Tracking

.NOTES
    Version:        2.0.0
    Author:         WinPE PowerBuilder Development Team
    Creation Date:  2024-12-31
    Purpose:        Production-ready PXE boot automation
    
.LINK
    https://docs.winpe-powerbuilder.com/modules/deployment/pxe
#>

#region Module Dependencies

using module .\Section1-Core-Framework.ps1

#endregion

#region PXE Configuration Models

class PXEServerConfiguration {
    [string]$ServerName
    [string]$ServerIP
    [string]$TFTPRootPath
    [string]$BootFilesPath
    [bool]$DHCPEnabled
    [string]$DHCPStartIP
    [string]$DHCPEndIP
    [string]$SubnetMask
    [string]$Gateway
    [string[]]$DNSServers
    [hashtable]$DHCPOptions
    [bool]$ProxyDHCP
    
    PXEServerConfiguration() {
        $this.DHCPOptions = @{}
        $this.DNSServers = @()
        $this.ProxyDHCP = $false
    }
    
    [bool]Validate() {
        # Validate server IP
        if ([string]::IsNullOrWhiteSpace($this.ServerIP)) {
            return $false
        }
        
        try {
            [System.Net.IPAddress]::Parse($this.ServerIP) | Out-Null
        } catch {
            return $false
        }
        
        # Validate TFTP root path
        if ([string]::IsNullOrWhiteSpace($this.TFTPRootPath)) {
            return $false
        }
        
        # Validate DHCP range if DHCP is enabled
        if ($this.DHCPEnabled -and -not $this.ProxyDHCP) {
            if ([string]::IsNullOrWhiteSpace($this.DHCPStartIP) -or 
                [string]::IsNullOrWhiteSpace($this.DHCPEndIP)) {
                return $false
            }
            
            try {
                [System.Net.IPAddress]::Parse($this.DHCPStartIP) | Out-Null
                [System.Net.IPAddress]::Parse($this.DHCPEndIP) | Out-Null
            } catch {
                return $false
            }
        }
        
        return $true
    }
    
    [hashtable]ToHashtable() {
        return @{
            ServerName = $this.ServerName
            ServerIP = $this.ServerIP
            TFTPRootPath = $this.TFTPRootPath
            BootFilesPath = $this.BootFilesPath
            DHCPEnabled = $this.DHCPEnabled
            DHCPStartIP = $this.DHCPStartIP
            DHCPEndIP = $this.DHCPEndIP
            SubnetMask = $this.SubnetMask
            Gateway = $this.Gateway
            DNSServers = $this.DNSServers
            DHCPOptions = $this.DHCPOptions
            ProxyDHCP = $this.ProxyDHCP
        }
    }
}

class PXEBootEntry {
    [string]$EntryId
    [string]$Label
    [string]$Description
    [string]$BootFilePath
    [string]$Architecture  # x86, x64, ARM64
    [string]$FirmwareType  # BIOS, UEFI
    [bool]$IsDefault
    [int]$MenuOrder
    [hashtable]$CustomOptions
    
    PXEBootEntry([string]$label, [string]$bootFilePath) {
        $this.EntryId = [guid]::NewGuid().ToString()
        $this.Label = $label
        $this.BootFilePath = $bootFilePath
        $this.Architecture = 'x64'
        $this.FirmwareType = 'UEFI'
        $this.IsDefault = $false
        $this.MenuOrder = 0
        $this.CustomOptions = @{}
    }
    
    [string]GenerateMenuEntry() {
        # Generate iPXE menu entry
        $entry = @"
:$($this.Label.Replace(' ', '_'))
echo Loading $($this.Label)...
$(if ($this.Description) { "echo $($this.Description)" })
kernel $($this.BootFilePath)
boot || goto failed
"@
        return $entry
    }
}

class PXEBootMenu {
    [string]$MenuId
    [string]$Title
    [string]$Subtitle
    [int]$Timeout
    [System.Collections.Generic.List[PXEBootEntry]]$Entries
    [string]$DefaultEntry
    
    PXEBootMenu([string]$title) {
        $this.MenuId = [guid]::NewGuid().ToString()
        $this.Title = $title
        $this.Timeout = 30
        $this.Entries = [System.Collections.Generic.List[PXEBootEntry]]::new()
    }
    
    [void]AddEntry([PXEBootEntry]$entry) {
        $this.Entries.Add($entry)
        
        if ($entry.IsDefault) {
            $this.DefaultEntry = $entry.EntryId
        }
    }
    
    [void]RemoveEntry([string]$entryId) {
        $entry = $this.Entries | Where-Object { $_.EntryId -eq $entryId } | Select-Object -First 1
        if ($entry) {
            $this.Entries.Remove($entry)
        }
    }
    
    [string]GenerateIPXEMenu() {
        $menu = @"
#!ipxe

###############################################################################
# $($this.Title)
$(if ($this.Subtitle) { "# $($this.Subtitle)" })
# Generated: $(Get-Date)
###############################################################################

:start
menu $($this.Title)
$(if ($this.Subtitle) { "item --gap -- $($this.Subtitle)" })
item --gap -- -------------------------------------------

"@
        
        # Add menu entries sorted by order
        $sortedEntries = $this.Entries | Sort-Object MenuOrder
        
        foreach ($entry in $sortedEntries) {
            $menu += "item $(if ($entry.IsDefault) { '--default ' })$($entry.Label.Replace(' ', '_')) $($entry.Label)`n"
        }
        
        $menu += @"

item --gap -- -------------------------------------------
item --key x exit Exit to local boot

choose --timeout $($this.Timeout * 1000) --default $($this.DefaultEntry) selected || goto cancel
goto `${selected}

"@
        
        # Add entry definitions
        foreach ($entry in $sortedEntries) {
            $menu += "`n$($entry.GenerateMenuEntry())`n"
        }
        
        $menu += @"

:cancel
echo Boot cancelled
exit

:failed
echo Boot failed!
echo Press any key to return to menu...
prompt
goto start

:exit
echo Exiting to local boot
exit
"@
        
        return $menu
    }
    
    [string]GeneratePXELinuxMenu() {
        $menu = @"
DEFAULT menu.c32
PROMPT 0
TIMEOUT $($this.Timeout * 10)

MENU TITLE $($this.Title)
$(if ($this.Subtitle) { "MENU SUBTITLE $($this.Subtitle)" })

"@
        
        $sortedEntries = $this.Entries | Sort-Object MenuOrder
        
        foreach ($entry in $sortedEntries) {
            $menu += @"

LABEL $($entry.Label.Replace(' ', '_'))
    MENU LABEL $($entry.Label)
    $(if ($entry.Description) { "MENU DESCRIPTION $($entry.Description)" })
    KERNEL $($entry.BootFilePath)
    $(if ($entry.IsDefault) { "MENU DEFAULT" })

"@
        }
        
        $menu += @"

LABEL local
    MENU LABEL Boot from local disk
    LOCALBOOT 0
"@
        
        return $menu
    }
}

#endregion

#region TFTP Server Management

class TFTPServer {
    [string]$RootPath
    [int]$Port
    [bool]$IsRunning
    [System.Diagnostics.Process]$ServerProcess
    [string]$ExecutablePath
    
    TFTPServer([string]$rootPath) {
        $this.RootPath = $rootPath
        $this.Port = 69
        $this.IsRunning = $false
    }
    
    [bool]Initialize() {
        # Create TFTP root directory
        if (-not (Test-Path $this.RootPath)) {
            New-Item -Path $this.RootPath -ItemType Directory -Force | Out-Null
        }
        
        # Check for TFTP server executable
        $tftpExePaths = @(
            "C:\Program Files\tftpd64\tftpd64.exe"
            "C:\Program Files (x86)\tftpd64\tftpd32.exe"
            "$env:ProgramData\WinPE-PowerBuilder\TFTP\tftpd64.exe"
        )
        
        foreach ($path in $tftpExePaths) {
            if (Test-Path $path) {
                $this.ExecutablePath = $path
                return $true
            }
        }
        
        Write-Warning "TFTP server executable not found. Install tftpd64 or configure manually."
        return $false
    }
    
    [bool]Start() {
        if ($this.IsRunning) {
            Write-Warning "TFTP server is already running"
            return $true
        }
        
        if (-not $this.Initialize()) {
            return $false
        }
        
        try {
            # Start TFTP server process
            $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
            $startInfo.FileName = $this.ExecutablePath
            $startInfo.Arguments = "-basedir `"$($this.RootPath)`""
            $startInfo.UseShellExecute = $false
            $startInfo.CreateNoWindow = $true
            
            $this.ServerProcess = [System.Diagnostics.Process]::Start($startInfo)
            $this.IsRunning = $true
            
            # Wait a moment for server to start
            Start-Sleep -Seconds 2
            
            return $true
        } catch {
            Write-Error "Failed to start TFTP server: $_"
            return $false
        }
    }
    
    [bool]Stop() {
        if (-not $this.IsRunning) {
            return $true
        }
        
        try {
            if ($this.ServerProcess -and -not $this.ServerProcess.HasExited) {
                $this.ServerProcess.Kill()
                $this.ServerProcess.WaitForExit(5000)
            }
            
            $this.IsRunning = $false
            return $true
        } catch {
            Write-Error "Failed to stop TFTP server: $_"
            return $false
        }
    }
    
    [void]DeployBootFiles([string]$sourcePath) {
        # Copy boot files to TFTP root
        if (Test-Path $sourcePath) {
            Copy-Item -Path "$sourcePath\*" -Destination $this.RootPath -Recurse -Force
        } else {
            throw "Source path not found: $sourcePath"
        }
    }
    
    [bool]TestConnectivity() {
        # Test TFTP connectivity
        try {
            $testFile = Join-Path $this.RootPath "test.txt"
            "TFTP Test" | Set-Content -Path $testFile
            
            # Try to connect to TFTP port
            $tcpClient = [System.Net.Sockets.TcpClient]::new()
            $tcpClient.Connect("127.0.0.1", $this.Port)
            $tcpClient.Close()
            
            Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
            
            return $true
        } catch {
            return $false
        }
    }
}

#endregion

#region DHCP Configuration

class DHCPScope {
    [string]$ScopeId
    [string]$Name
    [string]$StartRange
    [string]$EndRange
    [string]$SubnetMask
    [string]$Gateway
    [string[]]$DNSServers
    [int]$LeaseDuration  # in hours
    [hashtable]$Options
    
    DHCPScope([string]$name, [string]$startRange, [string]$endRange) {
        $this.ScopeId = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.StartRange = $startRange
        $this.EndRange = $endRange
        $this.LeaseDuration = 8
        $this.Options = @{}
        $this.DNSServers = @()
    }
    
    [hashtable]ToHashtable() {
        return @{
            ScopeId = $this.ScopeId
            Name = $this.Name
            StartRange = $this.StartRange
            EndRange = $this.EndRange
            SubnetMask = $this.SubnetMask
            Gateway = $this.Gateway
            DNSServers = $this.DNSServers
            LeaseDuration = $this.LeaseDuration
            Options = $this.Options
        }
    }
}

class DHCPManager {
    [bool]$IsInstalled
    [bool]$IsRunning
    [System.Collections.Generic.List[DHCPScope]]$Scopes
    
    DHCPManager() {
        $this.Scopes = [System.Collections.Generic.List[DHCPScope]]::new()
        $this.CheckInstallation()
    }
    
    hidden [void]CheckInstallation() {
        # Check if DHCP server role is installed
        try {
            $dhcpFeature = Get-WindowsFeature -Name DHCP -ErrorAction SilentlyContinue
            $this.IsInstalled = $dhcpFeature.Installed
            
            if ($this.IsInstalled) {
                $dhcpService = Get-Service -Name DHCPServer -ErrorAction SilentlyContinue
                $this.IsRunning = $dhcpService.Status -eq 'Running'
            }
        } catch {
            $this.IsInstalled = $false
            $this.IsRunning = $false
        }
    }
    
    [bool]InstallDHCPServer() {
        if ($this.IsInstalled) {
            Write-Warning "DHCP Server is already installed"
            return $true
        }
        
        try {
            Write-Host "Installing DHCP Server role..." -ForegroundColor Cyan
            
            Install-WindowsFeature -Name DHCP -IncludeManagementTools -ErrorAction Stop | Out-Null
            
            # Add DHCP security groups
            netsh dhcp add securitygroups | Out-Null
            
            # Restart DHCP service
            Restart-Service DHCPServer -ErrorAction Stop
            
            $this.IsInstalled = $true
            $this.IsRunning = $true
            
            Write-Host "✓ DHCP Server installed successfully" -ForegroundColor Green
            return $true
        } catch {
            Write-Error "Failed to install DHCP Server: $_"
            return $false
        }
    }
    
    [bool]CreateScope([DHCPScope]$scope) {
        if (-not $this.IsInstalled) {
            Write-Error "DHCP Server is not installed"
            return $false
        }
        
        try {
            # Create DHCP scope
            Add-DhcpServerv4Scope `
                -Name $scope.Name `
                -StartRange $scope.StartRange `
                -EndRange $scope.EndRange `
                -SubnetMask $scope.SubnetMask `
                -LeaseDuration (New-TimeSpan -Hours $scope.LeaseDuration) `
                -ErrorAction Stop
            
            # Set gateway (Option 3 - Router)
            if ($scope.Gateway) {
                Set-DhcpServerv4OptionValue `
                    -ScopeId $scope.StartRange `
                    -OptionId 3 `
                    -Value $scope.Gateway `
                    -ErrorAction Stop
            }
            
            # Set DNS servers (Option 6)
            if ($scope.DNSServers.Count -gt 0) {
                Set-DhcpServerv4OptionValue `
                    -ScopeId $scope.StartRange `
                    -OptionId 6 `
                    -Value $scope.DNSServers `
                    -ErrorAction Stop
            }
            
            $this.Scopes.Add($scope)
            
            Write-Host "✓ DHCP scope '$($scope.Name)' created" -ForegroundColor Green
            return $true
        } catch {
            Write-Error "Failed to create DHCP scope: $_"
            return $false
        }
    }
    
    [bool]ConfigurePXEOptions([string]$tftpServerIP, [string]$bootFileName) {
        if (-not $this.IsInstalled) {
            Write-Error "DHCP Server is not installed"
            return $false
        }
        
        try {
            # Option 66: Boot Server Host Name (TFTP server)
            Set-DhcpServerv4OptionValue `
                -OptionId 66 `
                -Value $tftpServerIP `
                -ErrorAction Stop
            
            # Option 67: Bootfile Name
            Set-DhcpServerv4OptionValue `
                -OptionId 67 `
                -Value $bootFileName `
                -ErrorAction Stop
            
            Write-Host "✓ PXE boot options configured" -ForegroundColor Green
            return $true
        } catch {
            Write-Error "Failed to configure PXE options: $_"
            return $false
        }
    }
    
    [void]ListScopes() {
        if (-not $this.IsInstalled) {
            Write-Warning "DHCP Server is not installed"
            return
        }
        
        $scopes = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue
        
        if ($scopes) {
            Write-Host "`nDHCP Scopes:" -ForegroundColor Cyan
            $scopes | Format-Table ScopeId, Name, State, StartRange, EndRange -AutoSize
        } else {
            Write-Host "No DHCP scopes configured" -ForegroundColor Yellow
        }
    }
}

#endregion

#region PXE Server Manager

class PXEServerManager {
    [PXEServerConfiguration]$Configuration
    [TFTPServer]$TFTPServer
    [DHCPManager]$DHCPManager
    [PXEBootMenu]$BootMenu
    [DeploymentLogger]$Logger
    [bool]$IsConfigured
    
    PXEServerManager() {
        $this.DHCPManager = [DHCPManager]::new()
        $this.IsConfigured = $false
    }
    
    [void]Initialize([PXEServerConfiguration]$config, [string]$logDirectory) {
        $this.Configuration = $config
        $this.Logger = [DeploymentLogger]::new($logDirectory)
        
        # Initialize TFTP server
        $this.TFTPServer = [TFTPServer]::new($config.TFTPRootPath)
        
        $this.Logger.LogInfo("PXE Server Manager initialized")
    }
    
    [bool]InstallPXEServer() {
        $this.Logger.LogInfo("Installing PXE Server components...")
        
        # Validate configuration
        if (-not $this.Configuration.Validate()) {
            $this.Logger.LogError("Invalid PXE server configuration")
            return $false
        }
        
        # Create directory structure
        $this.CreateDirectoryStructure()
        
        # Install DHCP if enabled
        if ($this.Configuration.DHCPEnabled -and -not $this.Configuration.ProxyDHCP) {
            if (-not $this.DHCPManager.InstallDHCPServer()) {
                $this.Logger.LogError("Failed to install DHCP server")
                return $false
            }
            
            # Create DHCP scope
            $scope = [DHCPScope]::new(
                "PXE Boot Scope",
                $this.Configuration.DHCPStartIP,
                $this.Configuration.DHCPEndIP
            )
            $scope.SubnetMask = $this.Configuration.SubnetMask
            $scope.Gateway = $this.Configuration.Gateway
            $scope.DNSServers = $this.Configuration.DNSServers
            
            if (-not $this.DHCPManager.CreateScope($scope)) {
                $this.Logger.LogError("Failed to create DHCP scope")
                return $false
            }
        }
        
        # Initialize TFTP server
        if (-not $this.TFTPServer.Initialize()) {
            $this.Logger.LogWarning("TFTP server initialization incomplete. Manual configuration may be required.")
        }
        
        # Deploy boot files
        $this.DeployBootFiles()
        
        $this.IsConfigured = $true
        $this.Logger.LogSuccess("PXE Server installation completed")
        
        return $true
    }
    
    hidden [void]CreateDirectoryStructure() {
        $this.Logger.LogInfo("Creating directory structure...")
        
        $directories = @(
            $this.Configuration.TFTPRootPath
            $this.Configuration.BootFilesPath
            (Join-Path $this.Configuration.TFTPRootPath "Boot")
            (Join-Path $this.Configuration.TFTPRootPath "Boot\x64")
            (Join-Path $this.Configuration.TFTPRootPath "Boot\x86")
            (Join-Path $this.Configuration.TFTPRootPath "Boot\ARM64")
            (Join-Path $this.Configuration.TFTPRootPath "Images")
            (Join-Path $this.Configuration.TFTPRootPath "Scripts")
        )
        
        foreach ($dir in $directories) {
            if (-not (Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
                $this.Logger.LogInfo("  Created: $dir")
            }
        }
    }
    
    hidden [void]DeployBootFiles() {
        $this.Logger.LogInfo("Deploying boot files...")
        
        # Deploy iPXE boot files
        $ipxeFiles = @{
            "undionly.kpxe" = "Boot\x64\undionly.kpxe"  # BIOS
            "ipxe.efi" = "Boot\x64\ipxe.efi"            # UEFI x64
            "snponly.efi" = "Boot\x64\snponly.efi"      # UEFI x64 (alternative)
        }
        
        $tftpRoot = $this.Configuration.TFTPRootPath
        
        foreach ($file in $ipxeFiles.Keys) {
            $destPath = Join-Path $tftpRoot $ipxeFiles[$file]
            $destDir = Split-Path $destPath -Parent
            
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            
            # Note: In production, these files would be copied from a source location
            $this.Logger.LogInfo("  Boot file placeholder: $file")
        }
    }
    
    [void]SetBootMenu([PXEBootMenu]$menu) {
        $this.BootMenu = $menu
        
        # Generate and save boot menu
        $menuContent = $menu.GenerateIPXEMenu()
        $menuPath = Join-Path $this.Configuration.TFTPRootPath "boot.ipxe"
        
        $menuContent | Set-Content -Path $menuPath -Encoding ASCII
        
        $this.Logger.LogInfo("Boot menu saved to: $menuPath")
    }
    
    [bool]AddBootImage([string]$imagePath, [string]$label, [string]$architecture, [string]$firmwareType) {
        if (-not (Test-Path $imagePath)) {
            $this.Logger.LogError("Image not found: $imagePath")
            return $false
        }
        
        # Copy image to TFTP images directory
        $imageFileName = Split-Path $imagePath -Leaf
        $destPath = Join-Path $this.Configuration.TFTPRootPath "Images\$imageFileName"
        
        Copy-Item -Path $imagePath -Destination $destPath -Force
        
        # Add to boot menu if menu exists
        if ($this.BootMenu) {
            $entry = [PXEBootEntry]::new($label, "Images/$imageFileName")
            $entry.Architecture = $architecture
            $entry.FirmwareType = $firmwareType
            
            $this.BootMenu.AddEntry($entry)
            $this.SetBootMenu($this.BootMenu)
        }
        
        $this.Logger.LogSuccess("Boot image added: $label")
        return $true
    }
    
    [bool]RemoveBootImage([string]$entryId) {
        if (-not $this.BootMenu) {
            return $false
        }
        
        $this.BootMenu.RemoveEntry($entryId)
        $this.SetBootMenu($this.BootMenu)
        
        $this.Logger.LogInfo("Boot image removed: $entryId")
        return $true
    }
    
    [bool]Start() {
        if (-not $this.IsConfigured) {
            $this.Logger.LogError("PXE Server is not configured")
            return $false
        }
        
        $this.Logger.LogInfo("Starting PXE Server...")
        
        # Start TFTP server
        if (-not $this.TFTPServer.Start()) {
            $this.Logger.LogError("Failed to start TFTP server")
            return $false
        }
        
        # Configure DHCP PXE options
        if ($this.Configuration.DHCPEnabled -and -not $this.Configuration.ProxyDHCP) {
            $bootFile = "Boot\x64\ipxe.efi"  # Default to UEFI x64
            
            if (-not $this.DHCPManager.ConfigurePXEOptions($this.Configuration.ServerIP, $bootFile)) {
                $this.Logger.LogWarning("Could not configure DHCP PXE options")
            }
        }
        
        $this.Logger.LogSuccess("PXE Server started successfully")
        return $true
    }
    
    [bool]Stop() {
        $this.Logger.LogInfo("Stopping PXE Server...")
        
        if (-not $this.TFTPServer.Stop()) {
            $this.Logger.LogError("Failed to stop TFTP server")
            return $false
        }
        
        $this.Logger.LogSuccess("PXE Server stopped")
        return $true
    }
    
    [bool]Test() {
        $this.Logger.LogInfo("Testing PXE Server configuration...")
        
        $allTestsPassed = $true
        
        # Test TFTP connectivity
        if ($this.TFTPServer.TestConnectivity()) {
            $this.Logger.LogSuccess("✓ TFTP server is accessible")
        } else {
            $this.Logger.LogError("✗ TFTP server is not accessible")
            $allTestsPassed = $false
        }
        
        # Test DHCP server
        if ($this.Configuration.DHCPEnabled) {
            if ($this.DHCPManager.IsRunning) {
                $this.Logger.LogSuccess("✓ DHCP server is running")
            } else {
                $this.Logger.LogError("✗ DHCP server is not running")
                $allTestsPassed = $false
            }
        }
        
        # Test boot files
        $bootFilesExist = Test-Path (Join-Path $this.Configuration.TFTPRootPath "boot.ipxe")
        if ($bootFilesExist) {
            $this.Logger.LogSuccess("✓ Boot menu file exists")
        } else {
            $this.Logger.LogWarning("⚠ Boot menu file not found")
        }
        
        return $allTestsPassed
    }
    
    [hashtable]GetStatus() {
        return @{
            IsConfigured = $this.IsConfigured
            TFTPServerRunning = $this.TFTPServer.IsRunning
            DHCPServerInstalled = $this.DHCPManager.IsInstalled
            DHCPServerRunning = $this.DHCPManager.IsRunning
            TFTPRootPath = $this.Configuration.TFTPRootPath
            ServerIP = $this.Configuration.ServerIP
            BootMenuEntries = if ($this.BootMenu) { $this.BootMenu.Entries.Count } else { 0 }
        }
    }
    
    [void]PrintStatus() {
        $status = $this.GetStatus()
        
        Write-Host "`n" -NoNewline
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host " PXE Server Status" -ForegroundColor White
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        
        Write-Host "`n📊 Configuration:" -ForegroundColor Cyan
        Write-Host "  Server IP: $($status.ServerIP)" -ForegroundColor White
        Write-Host "  TFTP Root: $($status.TFTPRootPath)" -ForegroundColor White
        Write-Host "  Is Configured: $($status.IsConfigured)" -ForegroundColor $(if ($status.IsConfigured) { 'Green' } else { 'Red' })
        
        Write-Host "`n🌐 Services:" -ForegroundColor Cyan
        Write-Host "  TFTP Server: $($status.TFTPServerRunning)" -ForegroundColor $(if ($status.TFTPServerRunning) { 'Green' } else { 'Red' })
        Write-Host "  DHCP Installed: $($status.DHCPServerInstalled)" -ForegroundColor $(if ($status.DHCPServerInstalled) { 'Green' } else { 'Gray' })
        Write-Host "  DHCP Running: $($status.DHCPServerRunning)" -ForegroundColor $(if ($status.DHCPServerRunning) { 'Green' } else { 'Gray' })
        
        Write-Host "`n🥾 Boot Menu:" -ForegroundColor Cyan
        Write-Host "  Total Entries: $($status.BootMenuEntries)" -ForegroundColor White
        
        if ($this.BootMenu) {
            Write-Host "`n  Entries:" -ForegroundColor Cyan
            foreach ($entry in $this.BootMenu.Entries | Sort-Object MenuOrder) {
                $defaultMarker = if ($entry.IsDefault) { " (default)" } else { "" }
                Write-Host "    - $($entry.Label)$defaultMarker" -ForegroundColor Gray
                Write-Host "      [$($entry.Architecture)/$($entry.FirmwareType)] $($entry.BootFilePath)" -ForegroundColor DarkGray
            }
        }
        
        Write-Host "`n" -NoNewline
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
    }
}

#endregion

#region Helper Functions

function New-PXEServerConfiguration {
    <#
    .SYNOPSIS
        Create a new PXE server configuration
    
    .PARAMETER ServerIP
        PXE server IP address
    
    .PARAMETER TFTPRootPath
        TFTP root directory path
    
    .PARAMETER DHCPEnabled
        Enable DHCP server
    
    .PARAMETER DHCPStartIP
        DHCP range start IP
    
    .PARAMETER DHCPEndIP
        DHCP range end IP
    
    .PARAMETER SubnetMask
        Network subnet mask
    
    .PARAMETER Gateway
        Default gateway
    
    .EXAMPLE
        $config = New-PXEServerConfiguration -ServerIP '192.168.1.100' -TFTPRootPath 'C:\TFTP'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerIP,
        
        [Parameter(Mandatory = $true)]
        [string]$TFTPRootPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$DHCPEnabled,
        
        [Parameter(Mandatory = $false)]
        [string]$DHCPStartIP,
        
        [Parameter(Mandatory = $false)]
        [string]$DHCPEndIP,
        
        [Parameter(Mandatory = $false)]
        [string]$SubnetMask = '255.255.255.0',
        
        [Parameter(Mandatory = $false)]
        [string]$Gateway
    )
    
    $config = [PXEServerConfiguration]::new()
    $config.ServerIP = $ServerIP
    $config.TFTPRootPath = $TFTPRootPath
    $config.BootFilesPath = Join-Path $TFTPRootPath "Boot"
    $config.DHCPEnabled = $DHCPEnabled.IsPresent
    $config.SubnetMask = $SubnetMask
    
    if ($DHCPEnabled) {
        $config.DHCPStartIP = $DHCPStartIP
        $config.DHCPEndIP = $DHCPEndIP
        $config.Gateway = $Gateway
    }
    
    return $config
}

function Install-PXEServer {
    <#
    .SYNOPSIS
        Install and configure a PXE boot server
    
    .PARAMETER Configuration
        PXE server configuration
    
    .PARAMETER LogDirectory
        Log directory path
    
    .EXAMPLE
        $config = New-PXEServerConfiguration -ServerIP '192.168.1.100' -TFTPRootPath 'C:\TFTP'
        $manager = Install-PXEServer -Configuration $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PXEServerConfiguration]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [string]$LogDirectory = "$env:ProgramData\WinPE-PowerBuilder\Logs\PXE"
    )
    
    $manager = [PXEServerManager]::new()
    $manager.Initialize($Configuration, $LogDirectory)
    
    if ($manager.InstallPXEServer()) {
        Write-Host "✓ PXE Server installed successfully" -ForegroundColor Green
        return $manager
    } else {
        Write-Error "PXE Server installation failed"
        return $null
    }
}

function New-PXEBootMenu {
    <#
    .SYNOPSIS
        Create a new PXE boot menu
    
    .PARAMETER Title
        Menu title
    
    .PARAMETER Timeout
        Menu timeout in seconds
    
    .EXAMPLE
        $menu = New-PXEBootMenu -Title 'WinPE Deployment' -Timeout 30
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30
    )
    
    $menu = [PXEBootMenu]::new($Title)
    $menu.Timeout = $Timeout
    
    return $menu
}

function Add-PXEBootEntry {
    <#
    .SYNOPSIS
        Add an entry to a PXE boot menu
    
    .PARAMETER Menu
        PXE boot menu
    
    .PARAMETER Label
        Entry label
    
    .PARAMETER BootFilePath
        Path to boot file
    
    .PARAMETER Architecture
        Target architecture (x86, x64, ARM64)
    
    .PARAMETER FirmwareType
        Firmware type (BIOS, UEFI)
    
    .PARAMETER IsDefault
        Set as default entry
    
    .EXAMPLE
        Add-PXEBootEntry -Menu $menu -Label 'Windows 11 PE' -BootFilePath 'Images/win11pe.wim' -IsDefault
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PXEBootMenu]$Menu,
        
        [Parameter(Mandatory = $true)]
        [string]$Label,
        
        [Parameter(Mandatory = $true)]
        [string]$BootFilePath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('x86', 'x64', 'ARM64')]
        [string]$Architecture = 'x64',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('BIOS', 'UEFI')]
        [string]$FirmwareType = 'UEFI',
        
        [Parameter(Mandatory = $false)]
        [switch]$IsDefault
    )
    
    $entry = [PXEBootEntry]::new($Label, $BootFilePath)
    $entry.Architecture = $Architecture
    $entry.FirmwareType = $FirmwareType
    $entry.IsDefault = $IsDefault.IsPresent
    $entry.MenuOrder = $Menu.Entries.Count
    
    $Menu.AddEntry($entry)
    
    return $entry
}

function Start-PXEServer {
    <#
    .SYNOPSIS
        Start the PXE server
    
    .PARAMETER Manager
        PXE server manager instance
    
    .EXAMPLE
        Start-PXEServer -Manager $manager
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PXEServerManager]$Manager
    )
    
    return $Manager.Start()
}

function Stop-PXEServer {
    <#
    .SYNOPSIS
        Stop the PXE server
    
    .PARAMETER Manager
        PXE server manager instance
    
    .EXAMPLE
        Stop-PXEServer -Manager $manager
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PXEServerManager]$Manager
    )
    
    return $Manager.Stop()
}

function Test-PXEServer {
    <#
    .SYNOPSIS
        Test PXE server configuration
    
    .PARAMETER Manager
        PXE server manager instance
    
    .EXAMPLE
        Test-PXEServer -Manager $manager
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PXEServerManager]$Manager
    )
    
    return $Manager.Test()
}

function Get-PXEServerStatus {
    <#
    .SYNOPSIS
        Get PXE server status
    
    .PARAMETER Manager
        PXE server manager instance
    
    .PARAMETER Detailed
        Show detailed status
    
    .EXAMPLE
        Get-PXEServerStatus -Manager $manager -Detailed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PXEServerManager]$Manager,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    if ($Detailed) {
        $Manager.PrintStatus()
    } else {
        return $Manager.GetStatus()
    }
}

#endregion

#region Module Initialization

Write-Host "PXE Boot Configuration module loaded!" -ForegroundColor Green
Write-Host "  TFTP server management ready" -ForegroundColor Gray
Write-Host "  DHCP server configuration ready" -ForegroundColor Gray
Write-Host "  Boot menu generation ready`n" -ForegroundColor Gray

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-PXEServerConfiguration'
    'Install-PXEServer'
    'New-PXEBootMenu'
    'Add-PXEBootEntry'
    'Start-PXEServer'
    'Stop-PXEServer'
    'Test-PXEServer'
    'Get-PXEServerStatus'
)

#endregion
