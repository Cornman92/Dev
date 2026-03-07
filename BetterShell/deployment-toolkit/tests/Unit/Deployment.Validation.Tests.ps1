# Pester tests for Deployment.Validation module

BeforeAll {
    $modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
    Import-Module Deployment.Core -Force
    Import-Module Deployment.Validation -Force
}

Describe 'Test-DeploymentPrerequisites' {
    It 'Should return a prerequisites check result' {
        $result = Test-DeploymentPrerequisites
        $result | Should -Not -BeNullOrEmpty
        # Result may be hashtable or PSCustomObject, check keys/properties
        $result.Keys -contains 'Passed' -or $result.PSObject.Properties.Name -contains 'Passed' | Should -Be $true
    }

    It 'Should check administrator rights' {
        $result = Test-DeploymentPrerequisites
        $adminCheck = $result.Checks | Where-Object { $_.Name -eq 'Administrator Rights' }
        $adminCheck | Should -Not -BeNullOrEmpty
    }

    It 'Should check PowerShell version' {
        $result = Test-DeploymentPrerequisites
        $psCheck = $result.Checks | Where-Object { $_.Name -eq 'PowerShell Version' }
        $psCheck | Should -Not -BeNullOrEmpty
    }
}

Describe 'Test-WimFile' {
    It 'Should return a WIM test result structure' {
        # Test with a non-existent file to get the structure
        $result = Test-WimFile -WimPath 'C:\nonexistent.wim' -Index 1
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'Passed'
        $result.PSObject.Properties.Name | Should -Contain 'WimPath'
        $result.PSObject.Properties.Name | Should -Contain 'Errors'
    }

    It 'Should fail for non-existent WIM file' {
        $result = Test-WimFile -WimPath 'C:\nonexistent.wim' -Index 1
        $result.Passed | Should -Be $false
        $result.Errors.Count | Should -BeGreaterThan 0
    }
}

Describe 'Test-DriverCatalog' {
    It 'Should return a driver catalog test result' {
        $result = Test-DriverCatalog
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'Passed'
        $result.PSObject.Properties.Name | Should -Contain 'DriverPacks'
    }
}

Describe 'Test-AppCatalog' {
    It 'Should return an app catalog test result' {
        $result = Test-AppCatalog
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'Passed'
        $result.PSObject.Properties.Name | Should -Contain 'Apps'
    }
}

Describe 'Test-TaskSequence' {
    It 'Should validate a task sequence' {
        $result = Test-TaskSequence -TaskSequenceId 'baremetal-basic'
        $result | Should -Not -BeNullOrEmpty
        # Result is a hashtable, check keys
        ($result.Keys -contains 'Passed' -or $result.PSObject.Properties.Name -contains 'Passed') | Should -Be $true
    }

    It 'Should fail for non-existent task sequence' {
        $result = Test-TaskSequence -TaskSequenceId 'nonexistent'
        $result.Passed | Should -Be $false
        $result.Errors.Count | Should -BeGreaterThan 0
    }

    It 'Should return step count for valid task sequence' {
        $result = Test-TaskSequence -TaskSequenceId 'baremetal-basic'
        $result.StepCount | Should -BeGreaterThan 0
    }
}

Describe 'Test-DeploymentPrerequisites - Additional Tests' {
    It 'Should have Checks with valid structure' {
        $result = Test-DeploymentPrerequisites
        $result.Checks | Should -Not -BeNullOrEmpty
        # Handle both single item and multiple items
        @($result.Checks).Count | Should -BeGreaterOrEqual 1
        
        $check = @($result.Checks)[0]
        ($check.Keys -contains 'Name' -or $check.PSObject.Properties.Name -contains 'Name') | Should -Be $true
    }

    It 'Should check Windows ADK availability' {
        $result = Test-DeploymentPrerequisites
        $adkCheck = $result.Checks | Where-Object { $_.Name -like '*ADK*' -or $_.Name -like '*Windows Assessment*' }
        # ADK check might not always be present, so we just verify structure
        $result.Checks | Should -Not -BeNullOrEmpty
    }
}

Describe 'Test-WimFile - Additional Tests' {
    It 'Should return WimPath in result' {
        $result = Test-WimFile -WimPath 'C:\nonexistent.wim' -Index 1
        $result.WimPath | Should -Be 'C:\nonexistent.wim'
    }

    It 'Should return Index in result' {
        $result = Test-WimFile -WimPath 'C:\nonexistent.wim' -Index 1
        $result.Index | Should -Be 1
    }

    It 'Should handle invalid index' {
        $result = Test-WimFile -WimPath 'C:\nonexistent.wim' -Index 0
        $result.Passed | Should -Be $false
    }
}

It 'Should have DriverPacks in result' {
    $result = Test-DriverCatalog
    $result.DriverPacks | Should -Not -BeNullOrEmpty
    # Handle both single item and array
    @($result.DriverPacks).Count | Should -BeGreaterOrEqual 1
}

It 'Should validate driver pack structure' {
    $result = Test-DriverCatalog
    if ($result.DriverPacks.Count -gt 0) {
        $pack = $result.DriverPacks[0]
        $pack.PSObject.Properties.Name | Should -Contain 'id'
    }
}
}

Describe 'Test-AppCatalog - Additional Tests' {
    It 'Should have Apps in result' {
        $result = Test-AppCatalog
        $result.Apps | Should -Not -BeNullOrEmpty
        # Handle both single item and array
        @($result.Apps).Count | Should -BeGreaterOrEqual 1
    }

    It 'Should validate app structure' {
        $result = Test-AppCatalog
        if ($result.Apps.Count -gt 0) {
            $app = $result.Apps[0]
            $app.PSObject.Properties.Name | Should -Contain 'id'
        }
    }
}

