BeforeAll {
    . "$PSScriptRoot\..\Functions\Get-FileHashBatch.ps1"
}

Describe 'Get-FileHashBatch' {
    BeforeAll {
        # Create temp test files
        $testDir = Join-Path $env:TEMP 'FileHashBatchTests'
        if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        $testFile1 = Join-Path $testDir 'file1.txt'
        $testFile2 = Join-Path $testDir 'file2.ps1'
        $subDir = Join-Path $testDir 'sub'
        New-Item -ItemType Directory -Path $subDir -Force | Out-Null
        $testFile3 = Join-Path $subDir 'file3.txt'

        Set-Content -Path $testFile1 -Value 'Hello World' -Encoding UTF8
        Set-Content -Path $testFile2 -Value 'Write-Host "test"' -Encoding UTF8
        Set-Content -Path $testFile3 -Value 'Nested file content' -Encoding UTF8
    }

    AfterAll {
        $testDir = Join-Path $env:TEMP 'FileHashBatchTests'
        if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
    }

    Context 'Single file hashing' {
        It 'Returns a result for a single file' {
            $testFile = Join-Path $env:TEMP 'FileHashBatchTests\file1.txt'
            $result = Get-FileHashBatch -Path $testFile
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
        }

        It 'Result contains expected properties' {
            $testFile = Join-Path $env:TEMP 'FileHashBatchTests\file1.txt'
            $result = Get-FileHashBatch -Path $testFile
            $result[0].PSObject.Properties.Name | Should -Contain 'Path'
            $result[0].PSObject.Properties.Name | Should -Contain 'Name'
            $result[0].PSObject.Properties.Name | Should -Contain 'Algorithm'
            $result[0].PSObject.Properties.Name | Should -Contain 'Hash'
            $result[0].PSObject.Properties.Name | Should -Contain 'SizeKB'
        }

        It 'Default algorithm is SHA256' {
            $testFile = Join-Path $env:TEMP 'FileHashBatchTests\file1.txt'
            $result = Get-FileHashBatch -Path $testFile
            $result[0].Algorithm | Should -Be 'SHA256'
        }

        It 'Hash is a valid hex string' {
            $testFile = Join-Path $env:TEMP 'FileHashBatchTests\file1.txt'
            $result = Get-FileHashBatch -Path $testFile
            $result[0].Hash | Should -Match '^[A-F0-9]{64}$'
        }
    }

    Context 'Directory hashing' {
        It 'Hashes all files in a directory (non-recursive)' {
            $testDir = Join-Path $env:TEMP 'FileHashBatchTests'
            $result = Get-FileHashBatch -Path $testDir
            $result.Count | Should -Be 2  # file1.txt and file2.ps1 (not sub/)
        }

        It 'Hashes files recursively with -Recurse' {
            $testDir = Join-Path $env:TEMP 'FileHashBatchTests'
            $result = Get-FileHashBatch -Path $testDir -Recurse
            $result.Count | Should -Be 3  # All 3 files
        }
    }

    Context 'Filter parameter' {
        It 'Filters by file pattern' {
            $testDir = Join-Path $env:TEMP 'FileHashBatchTests'
            $result = Get-FileHashBatch -Path $testDir -Filter '*.txt' -Recurse
            $result.Count | Should -Be 2  # file1.txt and file3.txt
        }

        It 'Returns no results for non-matching filter' {
            $testDir = Join-Path $env:TEMP 'FileHashBatchTests'
            $result = Get-FileHashBatch -Path $testDir -Filter '*.csv'
            $result.Count | Should -Be 0
        }
    }

    Context 'Algorithm parameter' {
        It 'Supports MD5 algorithm' {
            $testFile = Join-Path $env:TEMP 'FileHashBatchTests\file1.txt'
            $result = Get-FileHashBatch -Path $testFile -Algorithm MD5
            $result[0].Algorithm | Should -Be 'MD5'
            $result[0].Hash | Should -Match '^[A-F0-9]{32}$'
        }

        It 'Supports SHA512 algorithm' {
            $testFile = Join-Path $env:TEMP 'FileHashBatchTests\file1.txt'
            $result = Get-FileHashBatch -Path $testFile -Algorithm SHA512
            $result[0].Algorithm | Should -Be 'SHA512'
            $result[0].Hash | Should -Match '^[A-F0-9]{128}$'
        }
    }

    Context 'Consistent results' {
        It 'Returns the same hash for the same file content' {
            $testFile = Join-Path $env:TEMP 'FileHashBatchTests\file1.txt'
            $result1 = Get-FileHashBatch -Path $testFile
            $result2 = Get-FileHashBatch -Path $testFile
            $result1[0].Hash | Should -Be $result2[0].Hash
        }
    }

    Context 'Error handling' {
        It 'Warns for non-existent paths without throwing' {
            { Get-FileHashBatch -Path 'C:\NonExistent\FakePath\NoFile.txt' -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }
}
