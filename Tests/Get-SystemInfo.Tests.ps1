BeforeAll {
    . "$PSScriptRoot\..\Functions\Get-SystemInfo.ps1"
}

Describe 'Get-SystemInfo' {
    Context 'Basic output' {
        It 'Returns a PSCustomObject' {
            $result = Get-SystemInfo
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Contains required properties' {
            $result = Get-SystemInfo
            $result.PSObject.Properties.Name | Should -Contain 'ComputerName'
            $result.PSObject.Properties.Name | Should -Contain 'OS'
            $result.PSObject.Properties.Name | Should -Contain 'CPU'
            $result.PSObject.Properties.Name | Should -Contain 'TotalMemoryGB'
            $result.PSObject.Properties.Name | Should -Contain 'Disks'
            $result.PSObject.Properties.Name | Should -Contain 'UptimeDisplay'
            $result.PSObject.Properties.Name | Should -Contain 'Timestamp'
        }

        It 'ComputerName matches environment variable' {
            $result = Get-SystemInfo
            $result.ComputerName | Should -Be $env:COMPUTERNAME
        }

        It 'UserName matches environment variable' {
            $result = Get-SystemInfo
            $result.UserName | Should -Be $env:USERNAME
        }

        It 'TotalMemoryGB is a positive number' {
            $result = Get-SystemInfo
            $result.TotalMemoryGB | Should -BeGreaterThan 0
        }

        It 'UptimeDays is non-negative' {
            $result = Get-SystemInfo
            $result.UptimeDays | Should -BeGreaterOrEqual 0
        }

        It 'Timestamp is a valid date string' {
            $result = Get-SystemInfo
            { [datetime]::ParseExact($result.Timestamp, 'yyyy-MM-dd HH:mm:ss', $null) } | Should -Not -Throw
        }
    }

    Context 'Disks property' {
        It 'Returns disk information as array' {
            $result = Get-SystemInfo
            $result.Disks | Should -Not -BeNullOrEmpty
        }

        It 'Each disk has Drive, SizeGB, FreeGB, UsedPct' {
            $result = Get-SystemInfo
            $firstDisk = $result.Disks | Select-Object -First 1
            $firstDisk.PSObject.Properties.Name | Should -Contain 'Drive'
            $firstDisk.PSObject.Properties.Name | Should -Contain 'SizeGB'
            $firstDisk.PSObject.Properties.Name | Should -Contain 'FreeGB'
            $firstDisk.PSObject.Properties.Name | Should -Contain 'UsedPct'
        }
    }

    Context 'Detailed switch' {
        It 'Adds RunningProcesses property when -Detailed is used' {
            $result = Get-SystemInfo -Detailed
            $result.PSObject.Properties.Name | Should -Contain 'RunningProcesses'
        }

        It 'Adds RunningServices property when -Detailed is used' {
            $result = Get-SystemInfo -Detailed
            $result.PSObject.Properties.Name | Should -Contain 'RunningServices'
        }

        It 'Adds RecentHotfixes property when -Detailed is used' {
            $result = Get-SystemInfo -Detailed
            $result.PSObject.Properties.Name | Should -Contain 'RecentHotfixes'
        }

        It 'Adds NetworkAdapters property when -Detailed is used' {
            $result = Get-SystemInfo -Detailed
            $result.PSObject.Properties.Name | Should -Contain 'NetworkAdapters'
        }

        It 'RunningProcesses is a positive number' {
            $result = Get-SystemInfo -Detailed
            $result.RunningProcesses | Should -BeGreaterThan 0
        }

        It 'Does not include Detailed properties in basic mode' {
            $result = Get-SystemInfo
            $result.PSObject.Properties.Name | Should -Not -Contain 'RunningProcesses'
            $result.PSObject.Properties.Name | Should -Not -Contain 'NetworkAdapters'
        }
    }
}
