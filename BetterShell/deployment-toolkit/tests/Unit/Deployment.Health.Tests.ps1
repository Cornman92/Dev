# Pester tests for Deployment.Health module

BeforeAll {
    $modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
    Import-Module Deployment.Core -Force
    Import-Module Deployment.Health -Force
}

Describe 'New-HealthSnapshot' {
    It 'Should create a health snapshot file' {
        $ctx = New-DeployRunContext
        $snapshot = New-HealthSnapshot -RunContext $ctx -Name 'TestSnapshot'
        
        $snapshot | Should -Not -BeNullOrEmpty
        $snapshot | Should -BeOfType [System.IO.FileInfo]
        Test-Path $snapshot.FullName | Should -Be $true
    }

    It 'Should include metadata in snapshot' {
        $ctx = New-DeployRunContext
        $snapshot = New-HealthSnapshot -RunContext $ctx -Name 'TestSnapshot'
        
        $content = Get-Content $snapshot.FullName -Raw | ConvertFrom-Json
        $content.metadata | Should -Not -BeNullOrEmpty
        $content.metadata.runId | Should -Be $ctx.RunId
        $content.metadata.machine | Should -Be $ctx.MachineName
    }

    It 'Should include system information' {
        $ctx = New-DeployRunContext
        $snapshot = New-HealthSnapshot -RunContext $ctx -Name 'TestSnapshot'
        
        $content = Get-Content $snapshot.FullName -Raw | ConvertFrom-Json
        $content.system | Should -Not -BeNullOrEmpty
        $content.system.osCaption | Should -Not -BeNullOrEmpty
    }

    It 'Should sanitize snapshot name' {
        $ctx = New-DeployRunContext
        $snapshot = New-HealthSnapshot -RunContext $ctx -Name 'Test/Snapshot:Name'
        
        $snapshot.Name | Should -Not -Match '[\/:]'
    }

    It 'Should create snapshots directory if it does not exist' {
        $ctx = New-DeployRunContext
        $snapDir = Join-Path (Split-Path -Parent $ctx.RunLogPath) 'snapshots'
        
        if (Test-Path $snapDir) {
            Remove-Item $snapDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        $snapshot = New-HealthSnapshot -RunContext $ctx -Name 'TestSnapshot'
        Test-Path $snapDir | Should -Be $true
    }

    It 'Should include timestamp in snapshot filename' {
        $ctx = New-DeployRunContext
        $snapshot = New-HealthSnapshot -RunContext $ctx -Name 'TestSnapshot'
        
        $snapshot.Name | Should -Match '^\d{8}-\d{6}-'
    }
}

Describe 'Compare-HealthSnapshot' {
    It 'Should compare two snapshots' {
        $ctx = New-DeployRunContext
        $snapshot1 = New-HealthSnapshot -RunContext $ctx -Name 'Snapshot1'
        Start-Sleep -Seconds 2
        $snapshot2 = New-HealthSnapshot -RunContext $ctx -Name 'Snapshot2'
        
        $comparison = Compare-HealthSnapshot -BaselinePath $snapshot1.FullName -CurrentPath $snapshot2.FullName
        
        $comparison | Should -Not -BeNullOrEmpty
        $comparison.PSObject.Properties.Name | Should -Contain 'BaselinePath'
        $comparison.PSObject.Properties.Name | Should -Contain 'CurrentPath'
        $comparison.PSObject.Properties.Name | Should -Contain 'AddedApps'
        $comparison.PSObject.Properties.Name | Should -Contain 'RemovedApps'
        $comparison.PSObject.Properties.Name | Should -Contain 'ChangedApps'
        $comparison.PSObject.Properties.Name | Should -Contain 'ServiceChanges'
    }

    It 'Should throw for non-existent baseline snapshot file' {
        $ctx = New-DeployRunContext
        $snapshot2 = New-HealthSnapshot -RunContext $ctx -Name 'Snapshot2'
        { Compare-HealthSnapshot -BaselinePath 'C:\nonexistent1.json' -CurrentPath $snapshot2.FullName } | Should -Throw
    }

    It 'Should throw for non-existent current snapshot file' {
        $ctx = New-DeployRunContext
        $snapshot1 = New-HealthSnapshot -RunContext $ctx -Name 'Snapshot1'
        { Compare-HealthSnapshot -BaselinePath $snapshot1.FullName -CurrentPath 'C:\nonexistent2.json' } | Should -Throw
    }
}

Describe 'New-SystemRestorePointSafe' {
    It 'Should return a result object' {
        $ctx = New-DeployRunContext
        $result = New-SystemRestorePointSafe -RunContext $ctx -Description 'Test Restore Point'
        
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'Success'
    }

    It 'Should handle errors gracefully' {
        $ctx = New-DeployRunContext
        # This might fail if system restore is disabled or insufficient permissions
        $result = New-SystemRestorePointSafe -RunContext $ctx -Description 'Test Restore Point'
        
        $result.Success | Should -BeOfType [bool]
    }
}

Describe 'Export-DeployDiagnostics' {
    It 'Should create diagnostics export file' {
        $ctx = New-DeployRunContext
        $result = Export-DeployDiagnostics -RunContext $ctx
        
        $result | Should -Not -BeNullOrEmpty
        Test-Path $result | Should -Be $true
        $result | Should -Match '\.zip$'
    }

    It 'Should create zip file in run directory' {
        $ctx = New-DeployRunContext
        $runDir = Split-Path -Parent $ctx.RunLogPath
        $expectedPath = Join-Path $runDir 'diagnostics.zip'
        
        $result = Export-DeployDiagnostics -RunContext $ctx
        
        $result | Should -Be $expectedPath
    }

    It 'Should overwrite existing diagnostics zip file' {
        $ctx = New-DeployRunContext
        $runDir = Split-Path -Parent $ctx.RunLogPath
        $zipPath = Join-Path $runDir 'diagnostics.zip'
        
        # Create first zip
        $result1 = Export-DeployDiagnostics -RunContext $ctx
        $firstWriteTime = (Get-Item $zipPath).LastWriteTime
        
        Start-Sleep -Seconds 1
        
        # Create second zip
        $result2 = Export-DeployDiagnostics -RunContext $ctx
        $secondWriteTime = (Get-Item $zipPath).LastWriteTime
        
        $secondWriteTime | Should -BeGreaterThan $firstWriteTime
    }
}

