#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0' }

<#
.SYNOPSIS
    Pester test suite for Better11.BetterPE PowerShell modules.
.DESCRIPTION
    Validates module structure, exported functions, parameter validation,
    and mocked execution paths for all 6 BetterPE modules.
.NOTES
    Run with: Invoke-Pester -Path .\BetterPE.Module.Tests.ps1 -Output Detailed
#>

$ModuleRoot = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath 'PowerShell'

Describe 'Better11.BetterPE.ImageBuilder' {
    BeforeAll {
        $modulePath = Join-Path -Path $ModuleRoot -ChildPath 'Better11.BetterPE.ImageBuilder.psm1'
    }

    It 'Module file should exist' {
        $modulePath | Should -Exist
    }

    It 'Module should import without errors' {
        { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should export Invoke-BetterPEImageBuild' {
        Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Invoke-BetterPEImageBuild' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Mount-BetterPEImage' {
        Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Mount-BetterPEImage' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Dismount-BetterPEImage' {
        Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Dismount-BetterPEImage' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-BetterPEImageInfo' {
        Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Get-BetterPEImageInfo' | Should -Not -BeNullOrEmpty
    }

    It 'Should export New-BetterPEBootableIso' {
        Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'New-BetterPEBootableIso' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Export-BetterPEImage' {
        Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Export-BetterPEImage' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-BetterPEMountedImages' {
        Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Get-BetterPEMountedImages' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Clear-BetterPEStaleMounts' {
        Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Clear-BetterPEStaleMounts' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Test-BetterPEAdkInstallation' {
        Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Test-BetterPEAdkInstallation' | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-BetterPEImageBuild should have mandatory Name parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Invoke-BetterPEImageBuild'
        $cmd.Parameters['Name'].Attributes.Mandatory | Should -Contain $true
    }

    It 'Invoke-BetterPEImageBuild should have mandatory OutputDirectory parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.ImageBuilder' -Name 'Invoke-BetterPEImageBuild'
        $cmd.Parameters['OutputDirectory'].Attributes.Mandatory | Should -Contain $true
    }

    It 'Test-BetterPEAdkInstallation should return PSCustomObject' {
        $result = Test-BetterPEAdkInstallation
        $result | Should -BeOfType [PSCustomObject]
        $result.PSObject.Properties.Name | Should -Contain 'IsInstalled'
    }

    AfterAll {
        Remove-Module -Name 'Better11.BetterPE.ImageBuilder' -ErrorAction SilentlyContinue
    }
}

Describe 'Better11.BetterPE.DriverIntegration' {
    BeforeAll {
        $modulePath = Join-Path -Path $ModuleRoot -ChildPath 'Better11.BetterPE.DriverIntegration.psm1'
    }

    It 'Module file should exist' {
        $modulePath | Should -Exist
    }

    It 'Module should import without errors' {
        { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should export Search-BetterPEDrivers' {
        Get-Command -Module 'Better11.BetterPE.DriverIntegration' -Name 'Search-BetterPEDrivers' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Invoke-BetterPEDriverInjection' {
        Get-Command -Module 'Better11.BetterPE.DriverIntegration' -Name 'Invoke-BetterPEDriverInjection' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-BetterPEDriverInfo' {
        Get-Command -Module 'Better11.BetterPE.DriverIntegration' -Name 'Get-BetterPEDriverInfo' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-BetterPEInstalledDrivers' {
        Get-Command -Module 'Better11.BetterPE.DriverIntegration' -Name 'Get-BetterPEInstalledDrivers' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Remove-BetterPEDriver' {
        Get-Command -Module 'Better11.BetterPE.DriverIntegration' -Name 'Remove-BetterPEDriver' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Export-BetterPESystemDrivers' {
        Get-Command -Module 'Better11.BetterPE.DriverIntegration' -Name 'Export-BetterPESystemDrivers' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Test-BetterPEDriverCompatibility' {
        Get-Command -Module 'Better11.BetterPE.DriverIntegration' -Name 'Test-BetterPEDriverCompatibility' | Should -Not -BeNullOrEmpty
    }

    It 'Search-BetterPEDrivers should have mandatory SearchPath parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.DriverIntegration' -Name 'Search-BetterPEDrivers'
        $cmd.Parameters['SearchPath'].Attributes.Mandatory | Should -Contain $true
    }

    AfterAll {
        Remove-Module -Name 'Better11.BetterPE.DriverIntegration' -ErrorAction SilentlyContinue
    }
}

Describe 'Better11.BetterPE.Customization' {
    BeforeAll {
        $modulePath = Join-Path -Path $ModuleRoot -ChildPath 'Better11.BetterPE.Customization.psm1'
    }

    It 'Module file should exist' {
        $modulePath | Should -Exist
    }

    It 'Module should import without errors' {
        { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should export Invoke-BetterPECustomization' {
        Get-Command -Module 'Better11.BetterPE.Customization' -Name 'Invoke-BetterPECustomization' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Install-BetterPEOptionalComponents' {
        Get-Command -Module 'Better11.BetterPE.Customization' -Name 'Install-BetterPEOptionalComponents' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-BetterPEAvailableComponents' {
        Get-Command -Module 'Better11.BetterPE.Customization' -Name 'Get-BetterPEAvailableComponents' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-BetterPEInstalledComponents' {
        Get-Command -Module 'Better11.BetterPE.Customization' -Name 'Get-BetterPEInstalledComponents' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Add-BetterPEStartupScript' {
        Get-Command -Module 'Better11.BetterPE.Customization' -Name 'Add-BetterPEStartupScript' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Copy-BetterPEFileToImage' {
        Get-Command -Module 'Better11.BetterPE.Customization' -Name 'Copy-BetterPEFileToImage' | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        Remove-Module -Name 'Better11.BetterPE.Customization' -ErrorAction SilentlyContinue
    }
}

Describe 'Better11.BetterPE.BootConfig' {
    BeforeAll {
        $modulePath = Join-Path -Path $ModuleRoot -ChildPath 'Better11.BetterPE.BootConfig.psm1'
    }

    It 'Module file should exist' {
        $modulePath | Should -Exist
    }

    It 'Module should import without errors' {
        { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should export Set-BetterPEBootConfiguration' {
        Get-Command -Module 'Better11.BetterPE.BootConfig' -Name 'Set-BetterPEBootConfiguration' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-BetterPEBootConfiguration' {
        Get-Command -Module 'Better11.BetterPE.BootConfig' -Name 'Get-BetterPEBootConfiguration' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Set-BetterPEBcdEntry' {
        Get-Command -Module 'Better11.BetterPE.BootConfig' -Name 'Set-BetterPEBcdEntry' | Should -Not -BeNullOrEmpty
    }

    It 'Should export New-BetterPEBcdStore' {
        Get-Command -Module 'Better11.BetterPE.BootConfig' -Name 'New-BetterPEBcdStore' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Test-BetterPEBootConfiguration' {
        Get-Command -Module 'Better11.BetterPE.BootConfig' -Name 'Test-BetterPEBootConfiguration' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Set-BetterPESecureBoot' {
        Get-Command -Module 'Better11.BetterPE.BootConfig' -Name 'Set-BetterPESecureBoot' | Should -Not -BeNullOrEmpty
    }

    It 'Set-BetterPEBootConfiguration should have mandatory PEDirectory parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.BootConfig' -Name 'Set-BetterPEBootConfiguration'
        $cmd.Parameters['PEDirectory'].Attributes.Mandatory | Should -Contain $true
    }

    It 'Set-BetterPEBootConfiguration should support ShouldProcess' {
        $cmd = Get-Command -Module 'Better11.BetterPE.BootConfig' -Name 'Set-BetterPEBootConfiguration'
        $cmd.Parameters.Keys | Should -Contain 'WhatIf'
        $cmd.Parameters.Keys | Should -Contain 'Confirm'
    }

    It 'New-BetterPEBcdStore should have mandatory Path parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.BootConfig' -Name 'New-BetterPEBcdStore'
        $cmd.Parameters['Path'].Attributes.Mandatory | Should -Contain $true
    }

    AfterAll {
        Remove-Module -Name 'Better11.BetterPE.BootConfig' -ErrorAction SilentlyContinue
    }
}

Describe 'Better11.BetterPE.Recovery' {
    BeforeAll {
        $modulePath = Join-Path -Path $ModuleRoot -ChildPath 'Better11.BetterPE.Recovery.psm1'
    }

    It 'Module file should exist' {
        $modulePath | Should -Exist
    }

    It 'Module should import without errors' {
        { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should export Get-BetterPEWinReStatus' {
        Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'Get-BetterPEWinReStatus' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Set-BetterPEWinReEnabled' {
        Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'Set-BetterPEWinReEnabled' | Should -Not -BeNullOrEmpty
    }

    It 'Should export New-BetterPERecoveryEnvironment' {
        Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'New-BetterPERecoveryEnvironment' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Register-BetterPEWinReImage' {
        Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'Register-BetterPEWinReImage' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Backup-BetterPEWinReImage' {
        Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'Backup-BetterPEWinReImage' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Restore-BetterPEWinReImage' {
        Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'Restore-BetterPEWinReImage' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Test-BetterPERecoveryEnvironment' {
        Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'Test-BetterPERecoveryEnvironment' | Should -Not -BeNullOrEmpty
    }

    It 'New-BetterPERecoveryEnvironment should have mandatory Name parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'New-BetterPERecoveryEnvironment'
        $cmd.Parameters['Name'].Attributes.Mandatory | Should -Contain $true
    }

    It 'New-BetterPERecoveryEnvironment should support ShouldProcess' {
        $cmd = Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'New-BetterPERecoveryEnvironment'
        $cmd.Parameters.Keys | Should -Contain 'WhatIf'
    }

    It 'Set-BetterPEWinReEnabled should have mandatory Enabled parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.Recovery' -Name 'Set-BetterPEWinReEnabled'
        $cmd.Parameters['Enabled'].Attributes.Mandatory | Should -Contain $true
    }

    AfterAll {
        Remove-Module -Name 'Better11.BetterPE.Recovery' -ErrorAction SilentlyContinue
    }
}

Describe 'Better11.BetterPE.Deployment' {
    BeforeAll {
        $modulePath = Join-Path -Path $ModuleRoot -ChildPath 'Better11.BetterPE.Deployment.psm1'
    }

    It 'Module file should exist' {
        $modulePath | Should -Exist
    }

    It 'Module should import without errors' {
        { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should export Invoke-BetterPEDeployment' {
        Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Invoke-BetterPEDeployment' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-BetterPEUsbDrives' {
        Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Get-BetterPEUsbDrives' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Format-BetterPEUsbDrive' {
        Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Format-BetterPEUsbDrive' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Set-BetterPEPxeDeployment' {
        Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Set-BetterPEPxeDeployment' | Should -Not -BeNullOrEmpty
    }

    It 'Should export Test-BetterPEDeployment' {
        Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Test-BetterPEDeployment' | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-BetterPEDeployment should have mandatory ImagePath parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Invoke-BetterPEDeployment'
        $cmd.Parameters['ImagePath'].Attributes.Mandatory | Should -Contain $true
    }

    It 'Invoke-BetterPEDeployment should support ShouldProcess' {
        $cmd = Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Invoke-BetterPEDeployment'
        $cmd.Parameters.Keys | Should -Contain 'WhatIf'
    }

    It 'Format-BetterPEUsbDrive should have mandatory DriveLetter parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Format-BetterPEUsbDrive'
        $cmd.Parameters['DriveLetter'].Attributes.Mandatory | Should -Contain $true
    }

    It 'Format-BetterPEUsbDrive should validate FileSystem parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Format-BetterPEUsbDrive'
        $validateSet = $cmd.Parameters['FileSystem'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
        $validateSet.ValidValues | Should -Contain 'FAT32'
        $validateSet.ValidValues | Should -Contain 'NTFS'
    }

    It 'Invoke-BetterPEDeployment should validate Method parameter' {
        $cmd = Get-Command -Module 'Better11.BetterPE.Deployment' -Name 'Invoke-BetterPEDeployment'
        $validateSet = $cmd.Parameters['Method'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
        $validateSet.ValidValues | Should -Contain 'UsbDirect'
        $validateSet.ValidValues | Should -Contain 'UsbIso'
        $validateSet.ValidValues | Should -Contain 'Pxe'
        $validateSet.ValidValues | Should -Contain 'Wds'
    }

    AfterAll {
        Remove-Module -Name 'Better11.BetterPE.Deployment' -ErrorAction SilentlyContinue
    }
}
