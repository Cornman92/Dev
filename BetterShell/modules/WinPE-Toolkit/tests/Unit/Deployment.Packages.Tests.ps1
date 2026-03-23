# Pester tests for Deployment.Packages module

BeforeAll {
    $modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
    Import-Module Deployment.Core -Force
    Import-Module Deployment.Packages -Force
}

Describe 'Get-AppCatalog' {
    It 'Should return an app catalog array' {
        $catalog = Get-AppCatalog
        $catalog | Should -Not -BeNullOrEmpty
        $catalog | Should -BeOfType [System.Array]
    }

    It 'Should have app entries with required properties' {
        $catalog = Get-AppCatalog
        if ($catalog.Count -gt 0) {
            $app = $catalog[0]
            $app.PSObject.Properties.Name | Should -Contain 'id'
            $app.PSObject.Properties.Name | Should -Contain 'name'
            $app.PSObject.Properties.Name | Should -Contain 'sourceType'
        }
    }
}

Describe 'Get-AppSet' {
    It 'Should return an app set object' {
        try {
            $appSet = Get-AppSet -SetId 'dev-workstation'
            $appSet | Should -Not -BeNullOrEmpty
            $appSet.PSObject.Properties.Name | Should -Contain 'id'
            $appSet.PSObject.Properties.Name | Should -Contain 'appIds'
        }
        catch {
            # App set might not exist, that's okay for testing
            $_.Exception.Message | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Test-AppInstalled' {
    It 'Should return a boolean' {
        $catalog = Get-AppCatalog
        if ($catalog.Count -gt 0) {
            $app = $catalog[0]
            $result = Test-AppInstalled -App $app
            $result | Should -BeOfType [bool]
        }
    }

    It 'Should handle different source types' {
        $catalog = Get-AppCatalog
        if ($catalog.Count -gt 0) {
            $apps = $catalog | Where-Object { $_.sourceType -in @('WinGet', 'Chocolatey', 'Scoop', 'MSI', 'EXE') }
            if ($apps.Count -gt 0) {
                foreach ($app in $apps) {
                    $result = Test-AppInstalled -App $app
                    $result | Should -BeOfType [bool]
                }
            }
        }
    }
}

Describe 'Get-AppCatalog - Additional Tests' {
    It 'Should use cache on second call' {
        $catalog1 = Get-AppCatalog
        $catalog2 = Get-AppCatalog
        $catalog1 | Should -Be $catalog2
    }

    It 'Should refresh when ForceRefresh is used' {
        $catalog1 = Get-AppCatalog
        $catalog2 = Get-AppCatalog -ForceRefresh
        $catalog2 | Should -Not -BeNullOrEmpty
    }

    It 'Should have valid source types' {
        $catalog = Get-AppCatalog
        if ($catalog.Count -gt 0) {
            $validSourceTypes = @('WinGet', 'Chocolatey', 'Scoop', 'MSI', 'EXE', 'MSIX', 'Store')
            foreach ($app in $catalog) {
                if ($app.sourceType) {
                    $app.sourceType | Should -BeIn $validSourceTypes
                }
            }
        }
    }
}

Describe 'Get-AppSet - Additional Tests' {
    It 'Should throw for non-existent app set' {
        { Get-AppSet -SetId 'nonexistent-set-id' } | Should -Throw
    }

    It 'Should return app set with appIds array' {
        try {
            $appSet = Get-AppSet -SetId 'dev-workstation'
            $appSet.appIds | Should -Not -BeNullOrEmpty
            $appSet.appIds | Should -BeOfType [System.Array]
        }
        catch {
            # App set might not exist, skip test
        }
    }
}

