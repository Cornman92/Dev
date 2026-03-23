#Requires -Module Pester

Describe 'B11.BetterShell.Scheduler' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'SubModules' 'Scheduler' 'B11.BetterShell.Scheduler.psm1') -Force
    }

    AfterAll {
        Stop-B11AllScheduledTasks
    }

    Context 'New-B11ScheduledTask' {
        It 'Should create a task with interval' {
            $task = New-B11ScheduledTask -Name 'test_interval' -Action { 1 + 1 } -Interval ([timespan]::FromSeconds(60))
            $task.Name | Should -Be 'test_interval'
            $task.Status | Should -Be 'Created'
            Remove-B11ScheduledTask -Name 'test_interval'
        }

        It 'Should create a one-shot delayed task' {
            $task = New-B11ScheduledTask -Name 'test_delay' -Action { 1 + 1 } -Delay ([timespan]::FromSeconds(300))
            $task | Should -Not -BeNullOrEmpty
            Remove-B11ScheduledTask -Name 'test_delay'
        }
    }

    Context 'Enable/Disable-B11ScheduledTask' {
        It 'Should enable and disable a task' {
            New-B11ScheduledTask -Name 'test_toggle' -Action { 1 + 1 } -Interval ([timespan]::FromMinutes(5))
            $enabled = Enable-B11ScheduledTask -Name 'test_toggle'
            $enabled.Status | Should -Be 'Running'

            $disabled = Disable-B11ScheduledTask -Name 'test_toggle'
            $disabled.Status | Should -Be 'Disabled'
            Remove-B11ScheduledTask -Name 'test_toggle'
        }
    }

    Context 'Invoke-B11ScheduledTask' {
        It 'Should run a task immediately and record history' {
            New-B11ScheduledTask -Name 'test_invoke' -Action { 'hello' } -Interval ([timespan]::FromMinutes(5))
            $result = Invoke-B11ScheduledTask -Name 'test_invoke'
            $result.Success | Should -BeTrue

            $history = Get-B11TaskHistory -Name 'test_invoke'
            $history | Should -Not -BeNullOrEmpty
            Remove-B11ScheduledTask -Name 'test_invoke'
        }
    }

    Context 'Get-B11SchedulerStatistics' {
        It 'Should return scheduler statistics' {
            New-B11ScheduledTask -Name 'test_stats1' -Action { 1 } -Interval ([timespan]::FromMinutes(5))
            $stats = Get-B11SchedulerStatistics
            $stats.TotalTasks | Should -BeGreaterOrEqual 1
            Remove-B11ScheduledTask -Name 'test_stats1'
        }
    }

    Context 'Test-B11TaskDependencies' {
        It 'Should detect missing dependencies' {
            New-B11ScheduledTask -Name 'test_dep' -Action { 1 } -Interval ([timespan]::FromMinutes(5)) -DependsOn @('nonexistent')
            $check = Test-B11TaskDependencies -Name 'test_dep'
            $check.AllSatisfied | Should -BeFalse
            $check.Issues.Count | Should -BeGreaterThan 0
            Remove-B11ScheduledTask -Name 'test_dep'
        }
    }

    Context 'Export/Import-B11SchedulerConfig' {
        It 'Should export configuration' {
            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "scheduler_config_$(Get-Random).json"
            New-B11ScheduledTask -Name 'test_export_sched' -Action { 1 } -Interval ([timespan]::FromMinutes(5))
            { Export-B11SchedulerConfig -Path $tempFile } | Should -Not -Throw
            Test-Path $tempFile | Should -BeTrue
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            Remove-B11ScheduledTask -Name 'test_export_sched'
        }
    }
}
