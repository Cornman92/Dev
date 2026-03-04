<#
.SYNOPSIS
    Pester tests for the Write-Log function.

.DESCRIPTION
    Validates the Write-Log function handles all log levels,
    file output, and parameter combinations correctly.

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Write-Log.Tests.ps1
#>

BeforeAll {
    . "$PSScriptRoot\..\Functions\Write-Log.ps1"
}

Describe 'Write-Log' {

    Context 'Console Output' {
        It 'Should write Info level without error' {
            { Write-Log -Message 'Test info message' } | Should -Not -Throw
        }

        It 'Should write Warning level without error' {
            { Write-Log -Message 'Test warning' -Level Warning } | Should -Not -Throw
        }

        It 'Should write Error level without error' {
            { Write-Log -Message 'Test error' -Level Error } | Should -Not -Throw
        }

        It 'Should write Debug level without error' {
            { Write-Log -Message 'Test debug' -Level Debug } | Should -Not -Throw
        }
    }

    Context 'File Output' {
        BeforeAll {
            $testLogFile = Join-Path $TestDrive 'test.log'
        }

        It 'Should create log file when LogFile parameter is specified' {
            Write-Log -Message 'File test' -LogFile $testLogFile
            $testLogFile | Should -Exist
        }

        It 'Should write formatted log entry to file' {
            Write-Log -Message 'Formatted test' -Level Warning -LogFile $testLogFile
            $content = Get-Content $testLogFile -Tail 1
            $content | Should -Match '\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[WRN\] Formatted test'
        }

        It 'Should append to existing log file' {
            Write-Log -Message 'Line 1' -LogFile $testLogFile
            Write-Log -Message 'Line 2' -LogFile $testLogFile
            $lines = Get-Content $testLogFile
            $lines.Count | Should -BeGreaterThan 1
        }

        It 'Should create parent directory if it does not exist' {
            $nestedLog = Join-Path $TestDrive 'sub\dir\nested.log'
            { Write-Log -Message 'Nested dir test' -LogFile $nestedLog } | Should -Not -Throw
            $nestedLog | Should -Exist
        }
    }

    Context 'NoConsole Switch' {
        It 'Should not throw when NoConsole is specified' {
            { Write-Log -Message 'Silent test' -NoConsole } | Should -Not -Throw
        }
    }

    Context 'Parameter Validation' {
        It 'Should require Message parameter' {
            { Write-Log } | Should -Throw
        }

        It 'Should reject invalid Level values' {
            { Write-Log -Message 'test' -Level 'Invalid' } | Should -Throw
        }
    }
}
