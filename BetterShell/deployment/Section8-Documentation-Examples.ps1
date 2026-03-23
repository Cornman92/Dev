#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Module 5: Recovery Environment Builder
    Section 8: Documentation & Examples (~900 lines)

.DESCRIPTION
    Comprehensive documentation and practical examples for the Recovery Environment
    Builder module. Includes usage guides, best practices, troubleshooting, and
    real-world scenario implementations.

.COMPONENT
    Documentation & Examples
    - Quick Start Guide
    - Detailed Usage Examples
    - Best Practices
    - Troubleshooting Guide
    - Performance Optimization
    - Security Considerations
    - Integration Examples
    - Advanced Scenarios

.NOTES
    Version:        2.0.0
    Author:         WinPE PowerBuilder Development Team
    Creation Date:  2024-12-31
    Purpose:        Production-ready recovery environment documentation
    
.LINK
    https://docs.winpe-powerbuilder.com/modules/recovery-environment/
#>

#region Quick Start Guide

<#
.SYNOPSIS
    Quick Start Guide for Recovery Environment Builder

.DESCRIPTION
    This quick start guide will help you create your first Windows Recovery Environment
    in minutes with sensible defaults.

.EXAMPLE - Basic WinPE Recovery Environment
    # Step 1: Initialize the Recovery Environment Builder
    Import-Module RecoveryEnvironment.Core
    
    $config = @{
        Name = 'MyRecoveryWinPE'
        Architecture = 'amd64'
        OutputPath = 'C:\RecoveryBuild'
        SourcePath = 'C:\WinPE_Source'
    }
    
    $builder = New-RecoveryEnvironmentBuilder @config
    
    # Step 2: Add essential packages
    $builder.AddPackage('WinPE-WMI')
    $builder.AddPackage('WinPE-NetFx')
    $builder.AddPackage('WinPE-PowerShell')
    $builder.AddPackage('WinPE-DismCmdlets')
    
    # Step 3: Configure recovery features
    $builder.EnableSystemRestore()
    $builder.EnableImageBackup()
    $builder.EnableBootRepair()
    
    # Step 4: Build the recovery environment
    $result = $builder.Build()
    
    # Step 5: Create bootable media
    $builder.CreateBootableISO("C:\RecoveryMedia\recovery.iso")
    
    Write-Host "Recovery environment created successfully!" -ForegroundColor Green
    Write-Host "ISO Location: C:\RecoveryMedia\recovery.iso" -ForegroundColor White

.EXAMPLE - Recovery Environment with Network Support
    # Create a network-enabled recovery environment
    Import-Module RecoveryEnvironment.Core
    Import-Module RecoveryEnvironment.NetworkRecovery
    
    $config = @{
        Name = 'NetworkRecoveryWinPE'
        Architecture = 'amd64'
        OutputPath = 'C:\NetworkRecovery'
        EnableNetworking = $true
    }
    
    $builder = New-RecoveryEnvironmentBuilder @config
    
    # Add network packages
    $builder.AddPackage('WinPE-WMI')
    $builder.AddPackage('WinPE-NetFx')
    $builder.AddPackage('WinPE-PowerShell')
    $builder.AddPackage('WinPE-RNDIS')
    
    # Configure network recovery
    $networkConfig = @{
        EnablePXE = $true
        DHCPServer = '192.168.1.1'
        TFTPPath = 'C:\TFTP'
    }
    
    Set-NetworkRecoveryConfiguration @networkConfig
    
    # Build and deploy
    $result = $builder.Build()
    Deploy-PXEBootEnvironment -WimPath $result.WimPath
    
.EXAMPLE - Automated System Recovery Workflow
    # Create a complete automated recovery workflow
    Import-Module RecoveryEnvironment.AutomatedRecovery
    
    $workflow = New-AutomatedRecoveryWorkflow -Name "DailyBackup"
    
    # Define recovery steps
    $workflow.AddStep({
        # Step 1: Create system restore point
        New-SystemRestorePoint -Description "Pre-recovery checkpoint"
    })
    
    $workflow.AddStep({
        # Step 2: Backup critical data
        Backup-SystemImage -Destination "\\backup-server\images"
    })
    
    $workflow.AddStep({
        # Step 3: Verify backup integrity
        Test-BackupIntegrity -Path "\\backup-server\images\latest.vhdx"
    })
    
    # Schedule workflow
    $workflow.Schedule("Daily", "02:00")
    
    # Execute immediately for testing
    $result = $workflow.Execute()

#>

#endregion

#region Detailed Usage Examples

function Show-RecoveryEnvironmentExamples {
    [CmdletBinding()]
    param()
    
    $examples = @{
        'Basic Recovery Environment' = {
            <#
            .DESCRIPTION
                Creates a basic Windows PE recovery environment with essential tools
            #>
            
            # Initialize builder
            $builder = New-RecoveryEnvironmentBuilder -Name 'BasicRecovery' -Architecture 'amd64'
            
            # Add core packages
            @('WinPE-WMI', 'WinPE-NetFx', 'WinPE-PowerShell', 'WinPE-DismCmdlets') | ForEach-Object {
                $builder.AddPackage($_)
            }
            
            # Configure basic recovery features
            $builder.EnableSystemRestore()
            $builder.EnableBootRepair()
            
            # Build
            $result = $builder.Build()
            
            # Create bootable media
            $builder.CreateBootableUSB("E:\")  # USB drive letter
            
            return $result
        }
        
        'Enterprise Multi-Site Recovery' = {
            <#
            .DESCRIPTION
                Creates an enterprise-grade recovery environment for multi-site deployment
            #>
            
            # Define enterprise configuration
            $enterpriseConfig = @{
                Name = 'EnterpriseRecovery'
                Architecture = 'amd64'
                Sites = @('HQ', 'Branch1', 'Branch2', 'DataCenter')
                CentralBackupServer = '\\backup.contoso.com\recovery'
                EnableAD = $true
                EnableBitLocker = $true
            }
            
            # Create site-specific builders
            foreach ($site in $enterpriseConfig.Sites) {
                $siteBuilder = New-RecoveryEnvironmentBuilder -Name "Recovery-$site"
                
                # Add enterprise packages
                @(
                    'WinPE-WMI'
                    'WinPE-NetFx'
                    'WinPE-PowerShell'
                    'WinPE-DismCmdlets'
                    'WinPE-SecureStartup'  # BitLocker
                    'WinPE-EnhancedStorage'
                ) | ForEach-Object {
                    $siteBuilder.AddPackage($_)
                }
                
                # Configure site-specific settings
                $siteBuilder.SetCustomProperty('Site', $site)
                $siteBuilder.SetCustomProperty('BackupServer', $enterpriseConfig.CentralBackupServer)
                
                # Add site-specific scripts
                $startupScript = @"
# Site: $site Startup Script
Write-Host "Initializing recovery environment for site: $site"

# Mount network share
net use Z: $($enterpriseConfig.CentralBackupServer) /persistent:no

# Load site configuration
`$config = Import-Clixml Z:\Config\$site-config.xml

# Apply site-specific settings
"@
                $siteBuilder.AddStartupScript($startupScript)
                
                # Build site recovery environment
                $result = $siteBuilder.Build()
                
                # Deploy to site server
                Copy-Item -Path $result.WimPath -Destination "\\$site-server\Recovery\" -Force
            }
        }
        
        'Disaster Recovery with Bare Metal Restore' = {
            <#
            .DESCRIPTION
                Implements comprehensive disaster recovery with full bare-metal restore capability
            #>
            
            # Create DR builder
            $drBuilder = New-RecoveryEnvironmentBuilder -Name 'DisasterRecovery' -Architecture 'amd64'
            
            # Add all necessary packages
            $drPackages = @(
                'WinPE-WMI'
                'WinPE-NetFx'
                'WinPE-PowerShell'
                'WinPE-DismCmdlets'
                'WinPE-SecureStartup'
                'WinPE-WDS-Tools'
                'WinPE-StorageWMI'
                'WinPE-Scripting'
            )
            
            $drPackages | ForEach-Object { $drBuilder.AddPackage($_) }
            
            # Configure comprehensive recovery
            $drBuilder.EnableSystemRestore()
            $drBuilder.EnableImageBackup()
            $drBuilder.EnableBootRepair()
            $drBuilder.EnableNetworkRecovery()
            
            # Add bare metal recovery script
            $bareMetalScript = @'
<#
.SYNOPSIS
    Bare Metal Recovery Script
    
.DESCRIPTION
    Performs complete system recovery from backup image
#>

param(
    [string]$BackupServer = '\\backup-server\images',
    [string]$TargetDisk = 0
)

Write-Host "Starting Bare Metal Recovery Process..." -ForegroundColor Cyan

# Step 1: Identify and prepare target disk
Write-Host "Preparing target disk..." -ForegroundColor Yellow
$disk = Get-Disk -Number $TargetDisk
$disk | Clear-Disk -RemoveData -Confirm:$false
$disk | Initialize-Disk -PartitionStyle GPT

# Step 2: Create partitions
Write-Host "Creating partitions..." -ForegroundColor Yellow
$systemPartition = New-Partition -DiskNumber $TargetDisk -Size 500MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
$systemPartition | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "System" -Force

$osPartition = New-Partition -DiskNumber $TargetDisk -UseMaximumSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
$osPartition | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" -Force

# Step 3: Restore system image
Write-Host "Restoring system image..." -ForegroundColor Yellow
$latestBackup = Get-ChildItem -Path $BackupServer -Filter "*.vhdx" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($latestBackup) {
    Mount-DiskImage -ImagePath $latestBackup.FullName
    $backupDrive = (Get-DiskImage -ImagePath $latestBackup.FullName | Get-Disk | Get-Partition | Get-Volume).DriveLetter
    
    # Copy system files
    robocopy "${backupDrive}:\" "$($osPartition.DriveLetter):\" /E /COPYALL /R:3 /W:10
    
    Dismount-DiskImage -ImagePath $latestBackup.FullName
} else {
    Write-Error "No backup image found!"
    exit 1
}

# Step 4: Rebuild BCD
Write-Host "Rebuilding boot configuration..." -ForegroundColor Yellow
bcdboot "$($osPartition.DriveLetter):\Windows" /s "$($systemPartition.DriveLetter):" /f UEFI

Write-Host "Bare Metal Recovery completed successfully!" -ForegroundColor Green
Write-Host "Please remove recovery media and restart the system." -ForegroundColor White
'@
            
            $drBuilder.AddScript('BareMetalRecover.ps1', $bareMetalScript)
            
            # Build disaster recovery environment
            $result = $drBuilder.Build()
            
            # Create multiple media types
            $drBuilder.CreateBootableISO("C:\DR\recovery.iso")
            $drBuilder.CreateBootableUSB("E:\")
            $drBuilder.CreatePXEBootImage("C:\PXE\")
            
            return $result
        }
        
        'Automated Daily Backup System' = {
            <#
            .DESCRIPTION
                Sets up automated daily backup with rotation and verification
            #>
            
            # Define backup configuration
            $backupConfig = @{
                Schedule = 'Daily'
                Time = '02:00'
                RetentionDays = 30
                BackupPath = 'D:\Backups'
                VerifyBackups = $true
                EmailNotification = $true
                EmailTo = 'admin@contoso.com'
            }
            
            # Create automated workflow
            $workflow = New-AutomatedRecoveryWorkflow -Name 'DailyBackup'
            
            # Pre-backup tasks
            $workflow.AddStep({
                Write-Log "Starting daily backup process..."
                
                # Create dated backup folder
                $backupFolder = Join-Path $using:backupConfig.BackupPath (Get-Date -Format 'yyyy-MM-dd')
                New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
                
                return @{ BackupFolder = $backupFolder }
            })
            
            # System state backup
            $workflow.AddStep({
                param($context)
                
                Write-Log "Backing up system state..."
                
                $systemStateBackup = Join-Path $context.BackupFolder "SystemState.xml"
                
                # Export system configuration
                $systemState = @{
                    Hostname = $env:COMPUTERNAME
                    OSVersion = (Get-CimInstance Win32_OperatingSystem).Version
                    InstalledUpdates = (Get-HotFix | Select-Object HotFixID, InstalledOn)
                    Services = (Get-Service | Where-Object StartType -eq 'Automatic' | Select-Object Name, Status)
                    FirewallRules = (Get-NetFirewallRule | Select-Object Name, Enabled, Direction)
                }
                
                $systemState | Export-Clixml -Path $systemStateBackup
                
                $context.SystemStateBackup = $systemStateBackup
                return $context
            })
            
            # File backup
            $workflow.AddStep({
                param($context)
                
                Write-Log "Backing up user data..."
                
                $userDataBackup = Join-Path $context.BackupFolder "UserData.zip"
                
                # Compress user data
                $sourcePathspaths = @(
                    'C:\Users\*\Documents'
                    'C:\Users\*\Desktop'
                    'C:\Users\*\Pictures'
                )
                
                Compress-Archive -Path $sourcePaths -DestinationPath $userDataBackup -CompressionLevel Optimal
                
                $context.UserDataBackup = $userDataBackup
                return $context
            })
            
            # System image backup
            $workflow.AddStep({
                param($context)
                
                Write-Log "Creating system image..."
                
                $systemImage = Join-Path $context.BackupFolder "SystemImage.vhdx"
                
                # Create system image using Windows Backup
                wbadmin start backup -backupTarget:$systemImage -include:C: -allCritical -quiet
                
                $context.SystemImage = $systemImage
                return $context
            })
            
            # Verification
            if ($backupConfig.VerifyBackups) {
                $workflow.AddStep({
                    param($context)
                    
                    Write-Log "Verifying backups..."
                    
                    $verification = @{
                        SystemState = Test-Path $context.SystemStateBackup
                        UserData = Test-Path $context.UserDataBackup
                        SystemImage = Test-Path $context.SystemImage
                    }
                    
                    if ($verification.SystemImage) {
                        # Mount and verify image
                        $mounted = Mount-DiskImage -ImagePath $context.SystemImage -PassThru
                        $valid = $null -ne $mounted
                        Dismount-DiskImage -ImagePath $context.SystemImage
                        $verification.SystemImageValid = $valid
                    }
                    
                    $context.Verification = $verification
                    return $context
                })
            }
            
            # Cleanup old backups
            $workflow.AddStep({
                param($context)
                
                Write-Log "Cleaning up old backups..."
                
                $cutoffDate = (Get-Date).AddDays(-$using:backupConfig.RetentionDays)
                
                Get-ChildItem -Path $using:backupConfig.BackupPath -Directory | 
                    Where-Object { $_.CreationTime -lt $cutoffDate } |
                    Remove-Item -Recurse -Force
                
                return $context
            })
            
            # Email notification
            if ($backupConfig.EmailNotification) {
                $workflow.AddStep({
                    param($context)
                    
                    $emailBody = @"
Daily Backup Report
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')

Backup Location: $($context.BackupFolder)

Files Created:
- System State: $($context.SystemStateBackup)
- User Data: $($context.UserDataBackup)
- System Image: $($context.SystemImage)

Verification Results:
- System State Valid: $($context.Verification.SystemState)
- User Data Valid: $($context.Verification.UserData)
- System Image Valid: $($context.Verification.SystemImageValid)

Status: SUCCESS
"@
                    
                    Send-MailMessage -To $using:backupConfig.EmailTo `
                        -From "backup@$env:COMPUTERNAME" `
                        -Subject "Daily Backup Report - $(Get-Date -Format 'yyyy-MM-dd')" `
                        -Body $emailBody `
                        -SmtpServer "smtp.contoso.com"
                    
                    return $context
                })
            }
            
            # Schedule workflow
            $workflow.Schedule($backupConfig.Schedule, $backupConfig.Time)
            
            Write-Host "Automated daily backup configured successfully!" -ForegroundColor Green
            Write-Host "Next execution: $(($workflow.GetNextRunTime()))" -ForegroundColor White
            
            return $workflow
        }
    }
    
    return $examples
}

#endregion

#region Best Practices Guide

<#
.SYNOPSIS
    Best Practices for Recovery Environment Builder

.DESCRIPTION
    Comprehensive guide to best practices when building and deploying
    Windows Recovery Environments

.SECTION Package Selection
    
    Essential Packages:
    - WinPE-WMI: Required for most WMI-based tools
    - WinPE-NetFx: .NET Framework support
    - WinPE-PowerShell: PowerShell scripting support
    - WinPE-DismCmdlets: DISM cmdlets for image management
    
    Network Recovery:
    - WinPE-WDS-Tools: Windows Deployment Services
    - WinPE-RNDIS: USB network adapter support
    - WinPE-Dot3Svc: Wired networking support
    
    Storage Management:
    - WinPE-StorageWMI: Advanced storage management
    - WinPE-SecureStartup: BitLocker support
    - WinPE-EnhancedStorage: Enhanced storage devices
    
    Best Practice: Start with minimal packages and add only what you need.
    Each package increases WinPE size and boot time.

.SECTION Driver Management
    
    Critical Drivers:
    1. Storage Controllers (RAID, NVMe, SATA)
    2. Network Adapters (Wired and Wireless)
    3. Chipset Drivers
    4. Graphics (for GUI tools)
    
    Best Practices:
    - Test drivers in a VM before adding to production WinPE
    - Keep driver packages updated quarterly
    - Maintain separate driver sets for different hardware models
    - Use driver injection sparingly to minimize image size
    
    Example:
        $builder.AddDriver("C:\Drivers\Intel\Network", $true)  # Recursive
        $builder.AddDriver("C:\Drivers\NVMe\samsung.inf")      # Specific

.SECTION Performance Optimization
    
    Boot Time Optimization:
    1. Minimize package count
    2. Remove unnecessary drivers
    3. Use file compression wisely
    4. Optimize startup scripts
    5. Pre-cache frequently used files
    
    Example Configuration:
        $perfConfig = @{
            Compression = 'Maximum'      # Smaller size, slower boot
            PreloadFiles = @(            # Files to load into memory
                '\Windows\System32\*.dll'
                '\Windows\System32\drivers\*.sys'
            )
            ScratchSpace = 512MB         # RAM disk size
        }

.SECTION Security Hardening
    
    Security Best Practices:
    1. Disable unnecessary services
    2. Implement BitLocker for sensitive data
    3. Use secure network protocols (HTTPS, FTPS)
    4. Implement access controls
    5. Enable audit logging
    6. Regular security updates
    
    Example Hardening:
        # Disable AutoRun
        $builder.SetRegistryValue('HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer', 
                                   'NoDriveTypeAutoRun', 255, 'DWord')
        
        # Enable Windows Firewall
        $builder.EnableWindowsFirewall()
        
        # Restrict PowerShell execution
        $builder.SetPowerShellExecutionPolicy('AllSigned')

.SECTION Testing Strategy
    
    Recommended Testing Phases:
    
    Phase 1 - Virtual Machine Testing:
        - Test basic boot
        - Verify all packages load
        - Check driver functionality
        - Test recovery scripts
    
    Phase 2 - Physical Hardware Testing:
        - Test on target hardware models
        - Verify driver compatibility
        - Test network connectivity
        - Validate storage access
    
    Phase 3 - Integration Testing:
        - Test with backup systems
        - Verify network deployment
        - Test automated workflows
        - Validate failover scenarios
    
    Phase 4 - User Acceptance Testing:
        - IT staff validation
        - Documentation review
        - Process verification
        - Performance baseline

.SECTION Deployment Strategies
    
    USB Deployment:
        Pros: Portable, fast, offline capable
        Cons: Physical media management, limited distribution
        Best For: Small deployments, emergency recovery
    
    ISO/CD Deployment:
        Pros: Standardized, easy to distribute
        Cons: Read-only, slow boot
        Best For: Documentation, archival, occasional use
    
    Network (PXE) Deployment:
        Pros: No physical media, centralized, automatic
        Cons: Requires network infrastructure
        Best For: Enterprise environments, data centers
    
    VHD/VHDX Deployment:
        Pros: Fast boot, easy updates, space efficient
        Cons: Requires compatible hardware
        Best For: Modern UEFI systems, frequent use

.SECTION Maintenance Schedule
    
    Weekly:
        - Review backup logs
        - Verify automated workflows
        - Check storage capacity
    
    Monthly:
        - Test recovery procedures
        - Update documentation
        - Review security logs
        - Performance analysis
    
    Quarterly:
        - Update drivers
        - Patch Windows PE
        - Test new hardware
        - Update recovery scripts
        - Security audit
    
    Annually:
        - Full environment rebuild
        - Comprehensive testing
        - Process review
        - Training refresh

#>

#endregion

#region Troubleshooting Guide

function Get-RecoveryTroubleshootingGuide {
    [CmdletBinding()]
    param()
    
    return @{
        'Boot Failures' = @{
            Description = 'WinPE fails to boot or boots with errors'
            CommonCauses = @(
                'Missing or corrupt boot files'
                'Incompatible boot mode (BIOS vs UEFI)'
                'Bad media (USB/CD damage)'
                'Incorrect BCD configuration'
            )
            Solutions = @(
                @{
                    Issue = 'Boot Manager Missing'
                    Solution = @'
1. Verify boot files exist:
   - bootmgr (BIOS)
   - bootmgr.efi / bootx64.efi (UEFI)

2. Rebuild boot configuration:
   bcdedit /createstore C:\Boot\BCD
   bcdedit /store C:\Boot\BCD /create {bootmgr}
   bcdedit /store C:\Boot\BCD /set {bootmgr} device boot
'@
                }
                @{
                    Issue = 'BSOD on Boot'
                    Solution = @'
1. Check driver compatibility
2. Remove recently added drivers
3. Boot with minimal driver set
4. Check hardware compatibility list
5. Review Windows PE log: X:\Windows\Panther\setupact.log
'@
                }
            )
        }
        
        'Network Issues' = @{
            Description = 'Network connectivity problems in WinPE'
            CommonCauses = @(
                'Missing network drivers'
                'Network packages not installed'
                'DHCP configuration issues'
                'Firewall blocking connections'
            )
            Solutions = @(
                @{
                    Issue = 'No Network Connectivity'
                    Solution = @'
1. Verify network packages:
   dism /image:C:\mount /Get-Packages | findstr WinPE-WDS

2. Check network adapter:
   wpeinit  # Initialize network
   ipconfig /all

3. Manually configure if DHCP fails:
   netsh interface ip set address "Ethernet" static 192.168.1.100 255.255.255.0 192.168.1.1
   netsh interface ip set dns "Ethernet" static 8.8.8.8

4. Test connectivity:
   ping 8.8.8.8
   ping google.com
'@
                }
            )
        }
        
        'Performance Issues' = @{
            Description = 'Slow boot times or sluggish performance'
            CommonCauses = @(
                'Insufficient RAM'
                'Too many packages/drivers'
                'Slow boot media'
                'Fragmented image file'
            )
            Solutions = @(
                @{
                    Issue = 'Slow Boot Time'
                    Solution = @'
1. Optimize image size:
   - Remove unnecessary packages
   - Clean up temp files
   - Optimize driver set

2. Increase scratch space:
   wpeinit -scratchsize:512

3. Use faster boot media:
   - USB 3.0 instead of USB 2.0
   - SSD instead of HDD

4. Pre-load critical files to RAM:
   xcopy /e C:\Critical X:\PreLoad\
'@
                }
            )
        }
        
        'Storage Access Issues' = @{
            Description = 'Cannot access hard drives or storage devices'
            CommonCauses = @(
                'Missing storage controller drivers'
                'BitLocker encrypted volumes'
                'Corrupted partition table'
                'Dynamic disks'
            )
            Solutions = @(
                @{
                    Issue = 'Disks Not Visible'
                    Solution = @'
1. Check for storage devices:
   diskpart
   list disk
   list volume

2. Load storage drivers:
   drvload C:\Drivers\RaidController.inf

3. Rescan for hardware:
   diskpart
   rescan

4. Check disk status:
   Get-Disk
   Get-Partition
   Get-Volume
'@
                }
                @{
                    Issue = 'BitLocker Encrypted Volume'
                    Solution = @'
1. Unlock BitLocker volume:
   manage-bde -unlock C: -recoverypassword YOUR-RECOVERY-KEY

2. Alternative: Use recovery key file
   manage-bde -unlock C: -recoverykey E:\BitLocker-Recovery-Key.bek

3. Mount volume:
   assign letter=C:
'@
                }
            )
        }
    }
}

#endregion

#region Integration Examples

<#
.SYNOPSIS
    Integration Examples for Recovery Environment Builder

.EXAMPLE - Integration with Microsoft Endpoint Configuration Manager (MECM)
    
    # Create WinPE for MECM task sequences
    $mecmBuilder = New-RecoveryEnvironmentBuilder -Name 'MECM-WinPE' -Architecture 'amd64'
    
    # Add MECM-required packages
    $mecmPackages = @(
        'WinPE-WMI'
        'WinPE-NetFx'
        'WinPE-PowerShell'
        'WinPE-DismCmdlets'
        'WinPE-SecureStartup'  # For BitLocker
        'WinPE-WDS-Tools'
    )
    
    $mecmPackages | ForEach-Object { $mecmBuilder.AddPackage($_) }
    
    # Add network drivers for PXE boot
    $mecmBuilder.AddDriversFromFolder('C:\Drivers\Network', $true)
    
    # Configure for MECM integration
    $mecmConfig = @{
        ServerName = 'sccm.contoso.com'
        SiteCode = 'PS1'
        ManagementPoint = 'https://sccm.contoso.com/SMS_MP'
    }
    
    $mecmBuilder.SetCustomProperty('MECM', $mecmConfig)
    
    # Build and export to MECM
    $result = $mecmBuilder.Build()
    Copy-Item -Path $result.WimPath -Destination "\\sccm.contoso.com\SMS_PS1\OSD\boot\x64\boot.wim" -Force

.EXAMPLE - Integration with Veeam Backup & Replication
    
    # Create recovery environment with Veeam support
    $veeamBuilder = New-RecoveryEnvironmentBuilder -Name 'Veeam-Recovery' -Architecture 'amd64'
    
    # Add required packages
    $veeamBuilder.AddPackage('WinPE-WMI')
    $veeamBuilder.AddPackage('WinPE-NetFx')
    $veeamBuilder.AddPackage('WinPE-PowerShell')
    
    # Add Veeam recovery tools
    $veeamTools = @{
        VeeamRecoveryMedia = 'C:\Program Files\Veeam\Backup and Replication\Backup\VeeamRecoveryMedia.iso'
        VeeamAgentPath = 'C:\ProgramData\Veeam\VeeamAgent'
    }
    
    # Extract Veeam tools and add to WinPE
    Mount-DiskImage -ImagePath $veeamTools.VeeamRecoveryMedia
    $veeamDrive = (Get-DiskImage -ImagePath $veeamTools.VeeamRecoveryMedia | Get-Volume).DriveLetter
    
    $veeamBuilder.AddFilesToImage("${veeamDrive}:\Veeam", '\Program Files\Veeam')
    
    Dismount-DiskImage -ImagePath $veeamTools.VeeamRecoveryMedia
    
    # Build recovery environment
    $result = $veeamBuilder.Build()

.EXAMPLE - Integration with Active Directory
    
    # Create AD-integrated recovery environment
    $adBuilder = New-RecoveryEnvironmentBuilder -Name 'AD-Recovery' -Architecture 'amd64'
    
    # Add AD integration script
    $adScript = @'
param(
    [string]$Domain = 'contoso.com',
    [string]$DCServer = 'dc01.contoso.com'
)

# Initialize network
wpeinit

# Get credentials
$cred = Get-Credential -Message "Enter domain credentials"

# Join temporary computer account
$computerName = "RECOVERY-$(Get-Random -Maximum 9999)"
Add-Computer -DomainName $Domain -Credential $cred -Server $DCServer `
             -Options JoinWithNewName, AccountCreate -Force

# Authenticate to domain
# This allows access to domain resources during recovery
'@
    
    $adBuilder.AddScript('AD-Init.ps1', $adScript)
    $adBuilder.AddStartupScript('PowerShell.exe -ExecutionPolicy Bypass -File X:\Scripts\AD-Init.ps1')
    
    $result = $adBuilder.Build()

#>

#endregion

#region Module Documentation

<#
.SYNOPSIS
    Complete Module Documentation

.DESCRIPTION
    This section provides complete documentation for the Recovery Environment Builder module.

.SECTION Architecture Overview
    
    The Recovery Environment Builder is structured in multiple layers:
    
    Layer 1 - Core Foundation:
        - RecoveryEnvironment.Core
        - Base classes and utilities
        - Configuration management
        - Error handling
    
    Layer 2 - Feature Modules:
        - SystemRestore: Restore point management
        - ImageBackup: System image backup/restore
        - BCDManagement: Boot configuration
        - EmergencyBoot: Emergency boot media
        - AutomatedRecovery: Workflow automation
        - NetworkRecovery: Network-based recovery
    
    Layer 3 - Testing & Validation:
        - Build validation
        - Integration testing
        - Performance benchmarking
        - Automated test suites
    
    Layer 4 - Documentation & Examples:
        - Usage guides
        - Best practices
        - Troubleshooting
        - Integration examples

.SECTION API Reference
    
    Core Functions:
        - New-RecoveryEnvironmentBuilder
        - Build-RecoveryEnvironment
        - Test-RecoveryEnvironment
        - Deploy-RecoveryEnvironment
    
    System Restore Functions:
        - New-SystemRestorePoint
        - Get-SystemRestorePoints
        - Restore-SystemFromPoint
        - Remove-SystemRestorePoint
    
    Image Backup Functions:
        - Backup-SystemImage
        - Restore-SystemImage
        - Test-BackupIntegrity
        - Mount-BackupImage
    
    BCD Management Functions:
        - Get-BootConfiguration
        - Set-BootConfiguration
        - Repair-BootConfiguration
        - Backup-BootConfiguration
    
    Network Recovery Functions:
        - Enable-PXEBoot
        - Deploy-NetworkRecovery
        - Configure-MulticastDeployment
    
    For complete API documentation, see:
    https://docs.winpe-powerbuilder.com/api/recovery-environment

.SECTION Performance Metrics
    
    Typical Performance Benchmarks:
    
    Build Times (varies by configuration):
        - Minimal WinPE: 2-5 minutes
        - Standard Recovery: 5-10 minutes
        - Enterprise Full: 15-30 minutes
    
    Boot Times:
        - USB 3.0: 30-60 seconds
        - USB 2.0: 60-120 seconds
        - PXE Network: 45-90 seconds
        - Virtual Machine: 20-40 seconds
    
    Image Sizes:
        - Minimal WinPE: 250-400 MB
        - Standard Recovery: 500-800 MB
        - Enterprise Full: 1-2 GB
    
    Recovery Times:
        - System Restore: 5-15 minutes
        - Bare Metal (100GB): 30-60 minutes
        - Network Recovery: +10-20 minutes

.SECTION Support & Resources
    
    Documentation:
        - Online docs: https://docs.winpe-powerbuilder.com
        - API reference: https://docs.winpe-powerbuilder.com/api
        - Video tutorials: https://docs.winpe-powerbuilder.com/videos
    
    Community:
        - GitHub: https://github.com/winpe-powerbuilder
        - Forums: https://community.winpe-powerbuilder.com
        - Discord: https://discord.gg/winpe-powerbuilder
    
    Support:
        - Email: support@winpe-powerbuilder.com
        - Knowledge base: https://support.winpe-powerbuilder.com
        - Training: https://training.winpe-powerbuilder.com

#>

#endregion

#region Module Initialization

# Display module information when loaded
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " WinPE PowerBuilder Suite v2.0" -ForegroundColor White
Write-Host " Module 5: Recovery Environment Builder" -ForegroundColor White
Write-Host " Section 8: Documentation & Examples" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`nDocumentation module loaded successfully!" -ForegroundColor Green
Write-Host "`nAvailable commands:" -ForegroundColor Yellow
Write-Host "  - Show-RecoveryEnvironmentExamples" -ForegroundColor White
Write-Host "  - Get-RecoveryTroubleshootingGuide" -ForegroundColor White
Write-Host "`nFor complete documentation, visit:" -ForegroundColor Yellow
Write-Host "  https://docs.winpe-powerbuilder.com`n" -ForegroundColor White

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Show-RecoveryEnvironmentExamples'
    'Get-RecoveryTroubleshootingGuide'
)

#endregion
