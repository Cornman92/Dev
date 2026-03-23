# Test Improvement Guide

## Current Status

- **Tests Passing**: 29/43 (67.4%)
- **Code Coverage**: 15.39%
- **Target**: 80%+ coverage, 100% tests passing

## Improvement Strategy

### Phase 1: Fix Existing Tests (Priority: High)

1. **Identify Failing Tests**
   ```powershell
   .\tests\Unit\Run-AllUnitTests.ps1 -CodeCoverage
   ```

2. **Common Issues to Fix**:
   - Missing `process {}` blocks in pipeline functions
   - Uninitialized cache variables
   - JSON parsing errors (JSONL vs JSON)
   - Missing property existence checks
   - Path handling issues (forward vs backslashes)

### Phase 2: Add Missing Tests (Priority: High)

1. **Modules Without Tests**:
   - Check `Test-Improvement-Plan.ps1` output
   - Create test files for missing modules
   - Follow existing test patterns

2. **Low Coverage Modules**:
   - Identify functions with < 2 tests
   - Add edge case tests
   - Add error handling tests

### Phase 3: Enhance Coverage (Priority: Medium)

1. **Target 2+ Tests Per Function**:
   - Happy path test
   - Error path test
   - Edge case test (if applicable)

2. **Integration Tests**:
   - Test module interactions
   - Test end-to-end workflows
   - Test with real data (where safe)

## Running Tests

### Run All Tests
```powershell
.\tests\Unit\Run-AllUnitTests.ps1
```

### Run with Coverage
```powershell
.\tests\Unit\Run-AllUnitTests.ps1 -CodeCoverage
```

### Run Specific Test File
```powershell
Invoke-Pester .\tests\Unit\Deployment.Core.Tests.ps1
```

### Analyze Coverage
```powershell
.\tests\Unit\Test-Improvement-Plan.ps1 -GenerateReport
```

## Test Writing Guidelines

### Structure
```powershell
BeforeAll {
    # Setup: Import module, create test data
    Import-Module Deployment.Core -Force
}

Describe 'Function-Name' {
    It 'Should do something specific' {
        # Arrange
        $input = "test"
        
        # Act
        $result = Function-Name -Input $input
        
        # Assert
        $result | Should -Be "expected"
    }
    
    It 'Should handle errors gracefully' {
        # Test error cases
        { Function-Name -InvalidInput } | Should -Throw
    }
}
```

### Best Practices

1. **Use Descriptive Test Names**: "Should return valid path" not "Test1"
2. **Test One Thing Per Test**: Each `It` block should test one behavior
3. **Arrange-Act-Assert Pattern**: Clear separation of setup, execution, assertion
4. **Test Edge Cases**: Null, empty, invalid inputs
5. **Test Error Handling**: Verify exceptions are thrown appropriately
6. **Clean Up**: Use `AfterAll` to clean up test artifacts

## Common Fixes

### Pipeline Support
```powershell
# Before (broken)
function Write-DeployEvent {
    param(
        [Parameter(ValueFromPipeline)]
        [object]$InputObject
    )
    # Missing process block
}

# After (fixed)
function Write-DeployEvent {
    param(
        [Parameter(ValueFromPipeline)]
        [object]$InputObject
    )
    process {
        # Process each piped item
    }
}
```

### Cache Initialization
```powershell
# Add at module level
$script:DriverCatalogCache = $null
```

### JSONL Parsing
```powershell
# Correct way to parse JSONL (one JSON per line)
$lines = Get-Content $eventsPath
$lastLine = $lines[-1]
$event = $lastLine | ConvertFrom-Json
```

## Next Steps

1. Run `Test-Improvement-Plan.ps1` to identify gaps
2. Fix failing tests one module at a time
3. Add tests for untested functions
4. Aim for 2+ tests per function
5. Run coverage report regularly to track progress

## Resources

- [Pester Documentation](https://pester.dev/docs/quick-start)
- [PowerShell Testing Best Practices](https://github.com/pester/Pester/wiki)
- Existing test files in `tests/Unit/` for reference
