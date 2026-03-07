#Requires -Module Pester

Describe 'B11.BetterShell.Watcher' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'SubModules' 'Watcher' 'B11.BetterShell.Watcher.psm1') -Force
        $testDir = Join-Path ([System.IO.Path]::GetTempPath()) "b11_watcher_test_$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        Get-B11FileWatcher | ForEach-Object { Remove-B11FileWatcher -Name $_.Name }
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context 'New-B11FileWatcher' {
        It 'Should create a watcher with default settings' {
            $w = New-B11FileWatcher -Path $testDir -Name 'test_default'
            $w | Should -Not -BeNullOrEmpty
            $w.Name | Should -Be 'test_default'
            $w.Status | Should -Be 'Created'
            Remove-B11FileWatcher -Name 'test_default'
        }

        It 'Should create a watcher with custom filter' {
            $w = New-B11FileWatcher -Path $testDir -Filter '*.log' -Name 'test_filter'
            $w.Filter | Should -Be '*.log' -Because 'custom filter should be applied' -ErrorAction SilentlyContinue
            Remove-B11FileWatcher -Name 'test_filter'
        }

        It 'Should fail on invalid path' {
            { New-B11FileWatcher -Path 'C:\nonexistent_path_xyz' -Name 'test_bad' } | Should -Throw
        }
    }

    Context 'Start/Stop-B11FileWatcher' {
        It 'Should start and stop a watcher' {
            New-B11FileWatcher -Path $testDir -Name 'test_startstop'
            $started = Start-B11FileWatcher -Name 'test_startstop'
            $started.Status | Should -Be 'Running'

            $stopped = Stop-B11FileWatcher -Name 'test_startstop'
            $stopped.Status | Should -Be 'Stopped'
            Remove-B11FileWatcher -Name 'test_startstop'
        }
    }

    Context 'Get-B11FileWatcher' {
        It 'Should list all watchers' {
            New-B11FileWatcher -Path $testDir -Name 'test_list1'
            New-B11FileWatcher -Path $testDir -Name 'test_list2'
            $all = Get-B11FileWatcher
            $all.Count | Should -BeGreaterOrEqual 2
            Remove-B11FileWatcher -Name 'test_list1'
            Remove-B11FileWatcher -Name 'test_list2'
        }

        It 'Should get a specific watcher by name' {
            New-B11FileWatcher -Path $testDir -Name 'test_specific'
            $w = Get-B11FileWatcher -Name 'test_specific'
            $w.Name | Should -Be 'test_specific'
            Remove-B11FileWatcher -Name 'test_specific'
        }
    }

    Context 'Add-B11WatcherAction' {
        It 'Should not throw when adding an action' {
            New-B11FileWatcher -Path $testDir -Name 'test_action'
            { Add-B11WatcherAction -Name 'test_action' -Action { Write-Verbose 'triggered' } } | Should -Not -Throw
            Remove-B11FileWatcher -Name 'test_action'
        }
    }

    Context 'Export/Import-B11WatcherConfig' {
        It 'Should export and import configuration' {
            New-B11FileWatcher -Path $testDir -Filter '*.txt' -Name 'test_export'
            $exportPath = Join-Path $testDir 'watcher-config.json'
            Export-B11WatcherConfig -Name 'test_export' -Path $exportPath
            Test-Path $exportPath | Should -BeTrue

            Remove-B11FileWatcher -Name 'test_export'
            $imported = Import-B11WatcherConfig -Path $exportPath
            $imported.Name | Should -Be 'test_export'
            Remove-B11FileWatcher -Name 'test_export'
        }
    }

    Context 'Test-B11WatcherHealth' {
        It 'Should report healthy for valid watcher' {
            New-B11FileWatcher -Path $testDir -Name 'test_health'
            Start-B11FileWatcher -Name 'test_health'
            $health = Test-B11WatcherHealth -Name 'test_health'
            $health.IsHealthy | Should -BeTrue
            Stop-B11FileWatcher -Name 'test_health'
            Remove-B11FileWatcher -Name 'test_health'
        }
    }

    Context 'Get-B11WatcherStatistics' {
        It 'Should return statistics object' {
            New-B11FileWatcher -Path $testDir -Name 'test_stats'
            $stats = Get-B11WatcherStatistics -Name 'test_stats'
            $stats | Should -Not -BeNullOrEmpty
            $stats.TotalEvents | Should -Be 0
            Remove-B11FileWatcher -Name 'test_stats'
        }
    }
}
