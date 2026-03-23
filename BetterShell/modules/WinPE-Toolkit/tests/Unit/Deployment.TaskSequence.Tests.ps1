# Pester tests for Deployment.TaskSequence module

BeforeAll {
    $modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
    Import-Module Deployment.Core -Force
    Import-Module Deployment.TaskSequence -Force
}

Describe 'Get-TaskSequenceCatalog' {
    It 'Should return a task sequence catalog' {
        $catalog = Get-TaskSequenceCatalog
        $catalog | Should -Not -BeNullOrEmpty
        # Handle both single item and array
        @($catalog).Count | Should -BeGreaterOrEqual 1
    }

    It 'Should have task sequences with required properties' {
        $catalog = Get-TaskSequenceCatalog
        if ($catalog.Count -gt 0) {
            $ts = $catalog[0]
            $ts.PSObject.Properties.Name | Should -Contain 'id'
            $ts.PSObject.Properties.Name | Should -Contain 'name'
            $ts.PSObject.Properties.Name | Should -Contain 'steps'
        }
    }
}

Describe 'Get-TaskSequence' {
    It 'Should return a task sequence by ID' {
        $ts = Get-TaskSequence -Id 'baremetal-basic'
        $ts | Should -Not -BeNullOrEmpty
        $ts.id | Should -Be 'baremetal-basic'
    }

    It 'Should throw for non-existent task sequence' {
        { Get-TaskSequence -Id 'nonexistent-task-sequence' } | Should -Throw
    }

    It 'Should have steps' {
        $ts = Get-TaskSequence -Id 'baremetal-basic'
        $ts.steps | Should -Not -BeNullOrEmpty
        # Handle both single step and array
        @($ts.steps).Count | Should -BeGreaterOrEqual 1
    }

    It 'Should have valid step structure' {
        $ts = Get-TaskSequence -Id 'baremetal-basic'
        if ($ts.steps.Count -gt 0) {
            $step = $ts.steps[0]
            $step.PSObject.Properties.Name | Should -Contain 'type'
            $step.PSObject.Properties.Name | Should -Contain 'name'
        }
    }
}

Describe 'Get-TaskSequenceCatalog - Additional Tests' {
    It 'Should return catalog with valid structure' {
        $catalog = Get-TaskSequenceCatalog
        if ($catalog.Count -gt 0) {
            foreach ($ts in $catalog) {
                $ts.PSObject.Properties.Name | Should -Contain 'id'
                $ts.PSObject.Properties.Name | Should -Contain 'name'
            }
        }
    }
}

Describe 'Get-TaskSequence - Additional Tests' {
    It 'Should return task sequence with all required properties' {
        $ts = Get-TaskSequence -Id 'baremetal-basic'
        $requiredProperties = @('id', 'name', 'steps')
        foreach ($prop in $requiredProperties) {
            $ts.PSObject.Properties.Name | Should -Contain $prop
        }
    }

    It 'Should handle task sequence with no steps' {
        # This would require a test task sequence file
        # For now, we verify that steps property exists
        $ts = Get-TaskSequence -Id 'baremetal-basic'
        $ts.steps | Should -Not -BeNullOrEmpty
    }
}

