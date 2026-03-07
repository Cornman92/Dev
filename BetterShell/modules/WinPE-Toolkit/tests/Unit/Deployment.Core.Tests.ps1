# Pester tests for Deployment.Core module

BeforeAll {
    $modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
    Import-Module Deployment.Core -Force
}

Describe 'Get-DeployRoot' {
    It 'Should return a valid path' {
        $root = Get-DeployRoot
        $root | Should -Not -BeNullOrEmpty
        Test-Path $root | Should -Be $true
    }

    It 'Should return the same path on subsequent calls (caching)' {
        $root1 = Get-DeployRoot
        $root2 = Get-DeployRoot
        $root1 | Should -Be $root2
    }
}

Describe 'Get-DeployConfigPath' {
    It 'Should return a valid path for existing config' {
        $path = Get-DeployConfigPath -RelativePath 'configs\task_sequences'
        $path | Should -Not -BeNullOrEmpty
        Test-Path $path | Should -Be $true
    }

    It 'Should throw for non-existent path' {
        { Get-DeployConfigPath -RelativePath 'configs\nonexistent' } | Should -Throw
    }
}

Describe 'Resolve-DeployPath' {
    It 'Should resolve environment variables' {
        $env:TEST_VAR = 'TestValue'
        $result = Resolve-DeployPath -Path '%TEST_VAR%\subfolder'
        $result | Should -BeLike '*TestValue*'
        Remove-Item Env:\TEST_VAR
    }

    It 'Should handle relative paths' {
        $result = Resolve-DeployPath -Path '.\configs'
        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'New-DeployRunContext' {
    It 'Should create a valid run context' {
        $ctx = New-DeployRunContext
        $ctx | Should -Not -BeNullOrEmpty
        $ctx.RunId | Should -Not -BeNullOrEmpty
        $ctx.RootPath | Should -Not -BeNullOrEmpty
        $ctx.LogsRoot | Should -Not -BeNullOrEmpty
        Test-Path $ctx.RunLogPath | Should -Be $true
        Test-Path $ctx.EventsPath | Should -Be $true
    }

    It 'Should use provided RunId' {
        $runId = 'test-run-123'
        $ctx = New-DeployRunContext -RunId $runId
        $ctx.RunId | Should -Be $runId
    }
}

Describe 'Write-DeployEvent' {
    It 'Should write events to file' {
        $ctx = New-DeployRunContext
        $initialCount = if (Test-Path $ctx.EventsPath) { (Get-Content $ctx.EventsPath).Count } else { 0 }
        
        $ctx | Write-DeployEvent -Level 'Info' -Message 'Test event'
        
        $newCount = (Get-Content $ctx.EventsPath).Count
        $newCount | Should -BeGreaterThan $initialCount
    }

    It 'Should include correlation ID' {
        $ctx = New-DeployRunContext
        $ctx | Write-DeployEvent -Level 'Info' -Message 'Test' -CorrelationId 'test-correlation-123'
        
        # Events file is JSONL format (one JSON object per line)
        $lines = Get-Content $ctx.EventsPath
        $lastLine = $lines[-1]
        $content = $lastLine | ConvertFrom-Json
        $content.correlationId | Should -Be 'test-correlation-123'
    }
}

Describe 'Test-DeployAdmin' {
    It 'Should return a boolean' {
        $result = Test-DeployAdmin
        $result | Should -BeOfType [bool]
    }
}

Describe 'Invoke-DeployRetry' {
    It 'Should succeed on first attempt' {
        $ctx = New-DeployRunContext
        $result = Invoke-DeployRetry -ScriptBlock { return 'success' } -RunContext $ctx -OperationName 'test'
        $result | Should -Be 'success'
    }

    It 'Should retry on failure' {
        $ctx = New-DeployRunContext
        $attempts = 0
        $scriptBlock = {
            $script:attempts++
            if ($script:attempts -lt 2) {
                throw 'Temporary failure'
            }
            return 'success'
        }
        
        $result = Invoke-DeployRetry -ScriptBlock $scriptBlock -RunContext $ctx -OperationName 'test' -MaxAttempts 3 -DelaySeconds 1
        $result | Should -Be 'success'
        $attempts | Should -Be 2
    }

    It 'Should fail after max attempts' {
        $ctx = New-DeployRunContext
        $scriptBlock = { throw 'Always fails' }
        
        { Invoke-DeployRetry -ScriptBlock $scriptBlock -RunContext $ctx -OperationName 'test' -MaxAttempts 2 -DelaySeconds 1 } | Should -Throw
    }
}

Describe 'Export-DeployLogs' {
    It 'Should export to CSV format' {
        $ctx = New-DeployRunContext
        $ctx | Write-DeployEvent -Level 'Info' -Message 'Test event'
        
        $output = Export-DeployLogs -RunContext $ctx -Format 'CSV'
        Test-Path $output | Should -Be $true
        $output | Should -Match '\.csv$'
    }

    It 'Should export to HTML format' {
        $ctx = New-DeployRunContext
        $ctx | Write-DeployEvent -Level 'Info' -Message 'Test event'
        
        $output = Export-DeployLogs -RunContext $ctx -Format 'HTML'
        Test-Path $output | Should -Be $true
        $output | Should -Match '\.html$'
    }

    It 'Should export to JSON format' {
        $ctx = New-DeployRunContext
        $ctx | Write-DeployEvent -Level 'Info' -Message 'Test event'
        
        $output = Export-DeployLogs -RunContext $ctx -Format 'JSON'
        Test-Path $output | Should -Be $true
        $output | Should -Match '\.json$'
    }

    It 'Should use custom output path when provided' {
        $ctx = New-DeployRunContext
        $ctx | Write-DeployEvent -Level 'Info' -Message 'Test event'
        
        $customPath = Join-Path $env:TEMP "custom-export-$(Get-Random).csv"
        $output = Export-DeployLogs -RunContext $ctx -Format 'CSV' -OutputPath $customPath
        $output | Should -Be $customPath
        Test-Path $customPath | Should -Be $true
        Remove-Item $customPath -ErrorAction SilentlyContinue
    }

    It 'Should throw when events file does not exist' {
        $ctx = New-DeployRunContext
        $fakeEventsPath = Join-Path $env:TEMP "nonexistent-events.jsonl"
        $ctx.EventsPath = $fakeEventsPath
        
        { Export-DeployLogs -RunContext $ctx -Format 'CSV' } | Should -Throw
    }
}

Describe 'Write-DeployLog' {
    It 'Should write log message to file' {
        $ctx = New-DeployRunContext
        $initialContent = if (Test-Path $ctx.RunLogPath) { Get-Content $ctx.RunLogPath } else { @() }
        
        Write-DeployLog -RunContext $ctx -Message 'Test log message'
        
        $newContent = Get-Content $ctx.RunLogPath
        $newContent.Count | Should -BeGreaterThan $initialContent.Count
        $newContent[-1] | Should -Match 'Test log message'
    }

    It 'Should include timestamp in log message' {
        $ctx = New-DeployRunContext
        Write-DeployLog -RunContext $ctx -Message 'Timestamp test'
        
        $content = Get-Content $ctx.RunLogPath
        $lastLine = $content[-1]
        $lastLine | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}'
    }

    It 'Should handle empty message' {
        $ctx = New-DeployRunContext
        { Write-DeployLog -RunContext $ctx -Message '' } | Should -Throw
    }
}

Describe 'Write-DeployError' {
    It 'Should write error event to file' {
        $ctx = New-DeployRunContext
        $initialCount = if (Test-Path $ctx.EventsPath) { (Get-Content $ctx.EventsPath).Count } else { 0 }
        
        $exception = [System.Exception]::new('Test error message')
        $ctx | Write-DeployError -Exception $exception
        
        $newCount = (Get-Content $ctx.EventsPath).Count
        $newCount | Should -BeGreaterThan $initialCount
    }

    It 'Should include exception details in error data' {
        $ctx = New-DeployRunContext
        $exception = [System.ArgumentException]::new('Invalid argument')
        $ctx | Write-DeployError -Exception $exception -Context 'TestContext'
        
        $lines = Get-Content $ctx.EventsPath
        $lastLine = $lines[-1]
        $content = $lastLine | ConvertFrom-Json
        $content.level | Should -Be 'Error'
        $content.data.exceptionType | Should -Not -BeNullOrEmpty
        $content.data.exceptionMessage | Should -Be 'Invalid argument'
        $content.data.context | Should -Be 'TestContext'
    }

    It 'Should include additional data when provided' {
        $ctx = New-DeployRunContext
        $exception = [System.Exception]::new('Test error')
        $additionalData = @{
            CustomField = 'CustomValue'
            ErrorCode = 12345
        }
        $ctx | Write-DeployError -Exception $exception -AdditionalData $additionalData
        
        $lines = Get-Content $ctx.EventsPath
        $lastLine = $lines[-1]
        $content = $lastLine | ConvertFrom-Json
        $content.data.CustomField | Should -Be 'CustomValue'
        $content.data.ErrorCode | Should -Be 12345
    }
}

Describe 'Rotate-DeployLogs' {
    It 'Should not throw when logs directory does not exist' {
        { Rotate-DeployLogs } | Should -Not -Throw
    }

    It 'Should remove old log directories' {
        $root = Get-DeployRoot
        $logsRoot = Join-Path $root 'logs'
        if (-not (Test-Path $logsRoot)) {
            New-Item -ItemType Directory -Path $logsRoot | Out-Null
        }
        
        # Create a test log directory with old date
        $oldDir = Join-Path $logsRoot "old-test-$(Get-Random)"
        New-Item -ItemType Directory -Path $oldDir | Out-Null
        $oldDirInfo = Get-Item $oldDir
        $oldDirInfo.CreationTime = (Get-Date).AddDays(-35)
        
        Rotate-DeployLogs -RetentionDays 30
        
        Test-Path $oldDir | Should -Be $false
    }

    It 'Should keep recent log directories' {
        $root = Get-DeployRoot
        $logsRoot = Join-Path $root 'logs'
        if (-not (Test-Path $logsRoot)) {
            New-Item -ItemType Directory -Path $logsRoot | Out-Null
        }
        
        $recentDir = Join-Path $logsRoot "recent-test-$(Get-Random)"
        New-Item -ItemType Directory -Path $recentDir | Out-Null
        
        Rotate-DeployLogs -RetentionDays 30
        
        Test-Path $recentDir | Should -Be $true
        Remove-Item $recentDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Get-DeployConfigJson' {
    It 'Should parse valid JSON configuration file' {
        $result = Get-DeployConfigJson -RelativePath 'configs\task_sequences\baremetal-basic.json'
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'id'
    }

    It 'Should throw for non-existent file' {
        { Get-DeployConfigJson -RelativePath 'configs\nonexistent.json' } | Should -Throw
    }

    It 'Should throw for invalid JSON' {
        # This test would require creating a test file with invalid JSON
        # For now, we'll test that it handles JSON parsing errors
        $root = Get-DeployRoot
        $testConfigPath = Join-Path $root 'configs\test-invalid.json'
        try {
            Set-Content -Path $testConfigPath -Value '{ invalid json }' -ErrorAction Stop
            { Get-DeployConfigJson -RelativePath 'configs\test-invalid.json' } | Should -Throw
        }
        finally {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'Confirm-DestructiveAction' {
    It 'Should return true when Force switch is used' {
        $ctx = New-DeployRunContext
        $result = Confirm-DestructiveAction -RunContext $ctx -ActionDescription 'Test action' -Force
        $result | Should -Be $true
    }

    It 'Should log warning when Force is used' {
        $ctx = New-DeployRunContext
        $initialCount = (Get-Content $ctx.EventsPath).Count
        
        Confirm-DestructiveAction -RunContext $ctx -ActionDescription 'Test action' -Force
        
        $newCount = (Get-Content $ctx.EventsPath).Count
        $newCount | Should -BeGreaterThan $initialCount
        $lines = Get-Content $ctx.EventsPath
        $lastLine = $lines[-1]
        $content = $lastLine | ConvertFrom-Json
        $content.message | Should -Match 'auto-confirmed'
    }
}

Describe 'Write-ProgressDeploy' {
    It 'Should write progress with percent complete' {
        { Write-ProgressDeploy -Activity 'Test Activity' -Status 'Testing' -PercentComplete 50 } | Should -Not -Throw
    }

    It 'Should calculate percent from current and total operations' {
        { Write-ProgressDeploy -Activity 'Test Activity' -Status 'Testing' -CurrentOperation 5 -TotalOperations 10 } | Should -Not -Throw
    }

    It 'Should write progress without percent when not specified' {
        { Write-ProgressDeploy -Activity 'Test Activity' -Status 'Testing' } | Should -Not -Throw
    }
}

Describe 'Resolve-DeployPath - Additional Tests' {
    It 'Should resolve ${VAR} style environment variables' {
        $env:TEST_VAR2 = 'TestValue2'
        $result = Resolve-DeployPath -Path '${TEST_VAR2}\subfolder'
        $result | Should -BeLike '*TestValue2*'
        Remove-Item Env:\TEST_VAR2
    }

    It 'Should handle missing environment variables' {
        $result = Resolve-DeployPath -Path '%NONEXISTENT_VAR%\path'
        $result | Should -BeLike '*%NONEXISTENT_VAR%*'
    }

    It 'Should resolve relative paths starting with .\' {
        $root = Get-DeployRoot
        $result = Resolve-DeployPath -Path '.\configs'
        $result | Should -BeLike "*$root*"
    }
}

Describe 'Invoke-DeployRetry - Additional Tests' {
    It 'Should use exponential backoff when specified' {
        $ctx = New-DeployRunContext
        $attempts = 0
        $scriptBlock = {
            $script:attempts++
            if ($script:attempts -lt 3) {
                throw 'Temporary failure'
            }
            return 'success'
        }
        
        $startTime = Get-Date
        $result = Invoke-DeployRetry -ScriptBlock $scriptBlock -RunContext $ctx -OperationName 'test' -MaxAttempts 3 -DelaySeconds 1 -ExponentialBackoff
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        $result | Should -Be 'success'
        # With exponential backoff, delay should be 1s then 2s = at least 3 seconds
        $duration | Should -BeGreaterThan 2
    }

    It 'Should throw when MaxAttempts is less than 1' {
        $ctx = New-DeployRunContext
        { Invoke-DeployRetry -ScriptBlock { return 'test' } -RunContext $ctx -MaxAttempts 0 } | Should -Throw
    }

    It 'Should log retry attempts' {
        $ctx = New-DeployRunContext
        $attempts = 0
        $scriptBlock = {
            $script:attempts++
            if ($script:attempts -lt 2) {
                throw 'Temporary failure'
            }
            return 'success'
        }
        
        $initialCount = (Get-Content $ctx.EventsPath).Count
        Invoke-DeployRetry -ScriptBlock $scriptBlock -RunContext $ctx -OperationName 'test' -MaxAttempts 3 -DelaySeconds 1
        $newCount = (Get-Content $ctx.EventsPath).Count
        
        $newCount | Should -BeGreaterThan $initialCount
    }
}

