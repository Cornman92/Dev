---
description: Develop PowerShell modules with proper structure, testing, and publishing
---

# PowerShell Module Development Workflow

Complete workflow for developing professional PowerShell modules following PSFramework patterns used in this workspace.

## Prerequisites
- PowerShell 5.1+ or PowerShell 7+
- VS Code with PowerShell extension
- Pester module installed (`Install-Module Pester -Force`)
- PSScriptAnalyzer installed (`Install-Module PSScriptAnalyzer -Force`)

## Steps

### 1. Create Module Structure
// turbo
```powershell
# Create module directory
$moduleName = "[ModuleName]"
$modulePath = "e:\OneDrive\Dev\modules\$moduleName"
New-Item -Path $modulePath -ItemType Directory -Force

# Create subfolder structure
@('Public', 'Private', 'Classes', 'Data') | ForEach-Object {
    New-Item -Path "$modulePath\$_" -ItemType Directory -Force
}
```

### 2. Create Module Manifest
```powershell
$manifestParams = @{
    Path              = "$modulePath\$moduleName.psd1"
    RootModule        = "$moduleName.psm1"
    ModuleVersion     = '1.0.0'
    Author            = 'Your Name'
    Description       = 'Module description'
    PowerShellVersion = '5.1'
    FunctionsToExport = @()  # Will be auto-populated
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
New-ModuleManifest @manifestParams
```

### 3. Create Module Loader (.psm1)
Create `[ModuleName].psm1` with this template:
```powershell
# Module loader
$Public  = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName
```

### 4. Create Functions
Template for public functions in `Public/`:
```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief description
    .DESCRIPTION
        Detailed description
    .PARAMETER ParameterName
        Parameter description
    .EXAMPLE
        Verb-Noun -ParameterName Value
    .OUTPUTS
        Output type
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParameterName
    )
    
    begin {
        # Initialization
    }
    
    process {
        # Main logic
    }
    
    end {
        # Cleanup
    }
}
```

### 5. Create Pester Tests
Create `tests\[ModuleName].Tests.ps1`:
```powershell
BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "..\modules\$moduleName\$moduleName.psd1"
    Import-Module $modulePath -Force
}

Describe '[ModuleName] Module' {
    Context 'Module Import' {
        It 'Should import without errors' {
            { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
        }
        
        It 'Should export expected functions' {
            $exported = Get-Module $moduleName | Select-Object -ExpandProperty ExportedFunctions
            $exported.Keys | Should -Contain 'Verb-Noun'
        }
    }
    
    Context 'Verb-Noun' {
        It 'Should return expected output' {
            $result = Verb-Noun -ParameterName 'Test'
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
```

// turbo
### 6. Run PSScriptAnalyzer
```powershell
Invoke-ScriptAnalyzer -Path "e:\OneDrive\Dev\modules\[ModuleName]" -Recurse
```

// turbo
### 7. Run Pester Tests
```powershell
Invoke-Pester -Path "e:\OneDrive\Dev\tests\[ModuleName].Tests.ps1" -Output Detailed
```

### 8. Update Manifest Exports
```powershell
# Get all public functions and update manifest
$functions = (Get-ChildItem -Path "$modulePath\Public\*.ps1").BaseName
Update-ModuleManifest -Path "$modulePath\$moduleName.psd1" -FunctionsToExport $functions
```

### 9. Publish to PowerShell Gallery (Optional)
```powershell
# Ensure you have an API key from powershellgallery.com
Publish-Module -Path $modulePath -NuGetApiKey $env:NUGET_API_KEY
```

## Best Practices

- **Use approved verbs**: Run `Get-Verb` to see valid PowerShell verbs
- **Follow naming conventions**: Verb-Noun format (e.g., `Get-UserProfile`, `Set-Configuration`)
- **Include comment-based help**: Every public function needs `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
- **Add error handling**: Use `try/catch` and proper error streams
- **Validate parameters**: Use `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, etc.
- **Support pipeline**: Add `[Parameter(ValueFromPipeline)]` where appropriate
- **Keep private functions private**: Put internal functions in `Private/` folder

## Project Structure Reference
```
modules/
└── [ModuleName]/
    ├── [ModuleName].psd1    # Module manifest
    ├── [ModuleName].psm1    # Module loader
    ├── Public/              # Exported functions
    │   ├── Get-Something.ps1
    │   └── Set-Something.ps1
    ├── Private/             # Internal functions
    │   └── Helper-Function.ps1
    ├── Classes/             # PowerShell classes
    └── Data/                # Configuration files, templates
```

## Quick Commands
```powershell
# Import module for testing
Import-Module .\modules\[ModuleName]\[ModuleName].psd1 -Force

# List exported functions
Get-Command -Module [ModuleName]

# Get function help
Get-Help Verb-Noun -Full
```
