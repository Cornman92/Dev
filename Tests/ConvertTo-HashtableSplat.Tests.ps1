BeforeAll {
    . "$PSScriptRoot\..\Functions\ConvertTo-HashtableSplat.ps1"
}

Describe 'ConvertTo-HashtableSplat' {
    Context 'Null value removal' {
        It 'Removes keys with null values' {
            $params = @{ Path = 'C:\Temp'; Filter = $null; Recurse = $true }
            $result = ConvertTo-HashtableSplat -Parameters $params
            $result.Keys | Should -Not -Contain 'Filter'
            $result.Keys | Should -Contain 'Path'
            $result.Keys | Should -Contain 'Recurse'
        }

        It 'Returns empty hashtable when all values are null' {
            $params = @{ A = $null; B = $null }
            $result = ConvertTo-HashtableSplat -Parameters $params
            $result.Count | Should -Be 0
        }

        It 'Returns all keys when no values are null' {
            $params = @{ A = 1; B = 'hello'; C = $true }
            $result = ConvertTo-HashtableSplat -Parameters $params
            $result.Count | Should -Be 3
        }
    }

    Context 'RemoveEmpty switch' {
        It 'Keeps empty strings by default' {
            $params = @{ Name = ''; Value = 'test' }
            $result = ConvertTo-HashtableSplat -Parameters $params
            $result.Keys | Should -Contain 'Name'
        }

        It 'Removes empty strings when -RemoveEmpty is specified' {
            $params = @{ Name = ''; Value = 'test' }
            $result = ConvertTo-HashtableSplat -Parameters $params -RemoveEmpty
            $result.Keys | Should -Not -Contain 'Name'
            $result.Keys | Should -Contain 'Value'
        }

        It 'Removes whitespace-only strings when -RemoveEmpty is specified' {
            $params = @{ Name = '   '; Value = 'test' }
            $result = ConvertTo-HashtableSplat -Parameters $params -RemoveEmpty
            $result.Keys | Should -Not -Contain 'Name'
        }
    }

    Context 'CommandName validation' {
        It 'Filters to valid parameters for a known command' {
            $params = @{ Path = 'C:\Temp'; Recurse = $true; FakeParam = 'test' }
            $result = ConvertTo-HashtableSplat -Parameters $params -CommandName 'Get-ChildItem'
            $result.Keys | Should -Contain 'Path'
            $result.Keys | Should -Contain 'Recurse'
            $result.Keys | Should -Not -Contain 'FakeParam'
        }

        It 'Warns but keeps all params for unknown command' {
            $params = @{ A = 1; B = 2 }
            $result = ConvertTo-HashtableSplat -Parameters $params -CommandName 'Totally-FakeCommand' -WarningAction SilentlyContinue
            $result.Count | Should -Be 2
        }
    }

    Context 'Return type' {
        It 'Returns a hashtable' {
            $params = @{ Path = 'C:\Temp' }
            $result = ConvertTo-HashtableSplat -Parameters $params
            $result | Should -BeOfType [hashtable]
        }
    }

    Context 'Edge cases' {
        It 'Handles empty input hashtable' {
            $params = @{}
            $result = ConvertTo-HashtableSplat -Parameters $params
            $result.Count | Should -Be 0
        }

        It 'Preserves non-string non-null values' {
            $params = @{ Count = 0; Flag = $false; Items = @(1, 2, 3) }
            $result = ConvertTo-HashtableSplat -Parameters $params
            $result['Count'] | Should -Be 0
            $result['Flag'] | Should -Be $false
            $result['Items'].Count | Should -Be 3
        }
    }
}
