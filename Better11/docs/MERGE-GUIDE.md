# MERGE-GUIDE.md — Better11 Assembly Instructions

> **Version:** 3.0 (March 1, 2026)
> **Purpose:** Step-by-step guide to assemble Better11 from this unified package into a buildable solution.

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| .NET SDK | 8.0.x | Build C# projects |
| Visual Studio 2022 | 17.8+ | WinUI 3 / WinAppSDK tooling |
| Windows App SDK | 1.5+ | WinUI 3 runtime |
| PowerShell | 7.4+ | Module development & testing |
| Pester | 5.5+ | PowerShell test framework |
| PSScriptAnalyzer | 1.22+ | PowerShell static analysis |
| Node.js | 18+ | MCP server development |
| Git | 2.40+ | Version control |

---

## Step 1: Clone or Extract

```powershell
# If from ZIP
Expand-Archive -Path Better11-Unified.zip -DestinationPath C:\Dev\Better11
Set-Location C:\Dev\Better11

# If from Git
git clone https://github.com/{org}/better11.git
Set-Location better11
```

---

## Step 2: Restore & Build C# Solution

```powershell
# Restore NuGet packages
dotnet restore Better11.sln

# Build in Debug mode first
dotnet build Better11.sln -c Debug -v minimal

# Expected: Build succeeded. 0 Warning(s) 0 Error(s)
```

### Troubleshooting Build Errors

| Error | Fix |
|-------|-----|
| `NETSDK1045: .NET 8 not found` | Install .NET 8 SDK from dot.net |
| `WinAppSDK not found` | Install Windows App SDK via VS Installer |
| `StyleCop warning treated as error` | Fix the warning or add suppression |
| `CS8600 nullable reference` | Add null check or `!` assertion |

---

## Step 3: Run C# Tests

```powershell
dotnet test Better11.sln --collect:"XPlat Code Coverage" --results-directory ./TestResults

# View coverage report
reportgenerator -reports:./TestResults/**/coverage.cobertura.xml -targetdir:./CoverageReport -reporttypes:Html
```

---

## Step 4: Validate PowerShell Modules

```powershell
# Install dependencies
Install-Module -Name Pester -MinimumVersion 5.5.0 -Force -Scope CurrentUser
Install-Module -Name PSScriptAnalyzer -MinimumVersion 1.22.0 -Force -Scope CurrentUser

# Run PSScriptAnalyzer on all modules
$results = Invoke-ScriptAnalyzer -Path ./PowerShell/Modules -Recurse `
    -Settings ./config/PSScriptAnalyzerSettings.psd1
if ($results) {
    $results | Format-Table -AutoSize
    Write-Error "PSScriptAnalyzer found $($results.Count) issue(s)"
} else {
    Write-Host "PSScriptAnalyzer: PASS (0 issues)" -ForegroundColor Green
}

# Run Pester tests
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = './PowerShell/Modules'
$pesterConfig.Run.Passthru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = './PowerShell/Modules/**/*.psm1'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = './TestResults/pester-results.xml'
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

$result = Invoke-Pester -Configuration $pesterConfig
if ($result.FailedCount -gt 0) {
    Write-Error "$($result.FailedCount) Pester test(s) failed"
} else {
    Write-Host "Pester: PASS ($($result.PassedCount) tests)" -ForegroundColor Green
}
```

---

## Step 5: Verify Module Loading

```powershell
# Import each module and verify exports
$moduleErrors = @()
Get-ChildItem ./PowerShell/Modules -Directory | ForEach-Object {
    $manifestPath = Join-Path $_.FullName "$($_.Name).psd1"
    if (Test-Path $manifestPath) {
        try {
            Import-Module $manifestPath -Force -ErrorAction Stop
            $mod = Get-Module $_.Name
            Write-Host "  $($_.Name): $($mod.ExportedFunctions.Count) functions" -ForegroundColor Green
            Remove-Module $_.Name -Force
        } catch {
            $moduleErrors += "$($_.Name): $($_.Exception.Message)"
            Write-Host "  $($_.Name): FAILED" -ForegroundColor Red
        }
    }
}
if ($moduleErrors) {
    $moduleErrors | ForEach-Object { Write-Error $_ }
}
```

---

## Step 6: Full CI Build

```powershell
./build/Build-Better11.ps1 -Configuration Release -RunTests -RunAnalyzers
```

---

## Step 7: Package for Distribution

```powershell
# MSIX package
dotnet publish src/Better11.App -c Release -p:GenerateAppxPackageOnBuild=true

# Or standalone
dotnet publish src/Better11.App -c Release -r win-x64 --self-contained
```

---

## Conflict Resolution (Legacy Sessions)

If merging from old ZIP deliverables, these files have FINAL versions that supersede earlier drafts:

| File | Final Source | Notes |
|------|-------------|-------|
| App.xaml | Session 27 | DI container, all converters |
| App.xaml.cs | Session 27 | 7 singletons + 15 VMs |
| MainWindow.xaml | Session 27 | 14 nav items, shell UI |
| ShellViewModel.cs | Session 27 | Navigation, search, status |
| Result.cs | Foundation Fixes | Canonical Result<T> |
| BaseViewModel.cs | Foundation Fixes | CommunityToolkit base |
| PowerShellService.cs | Phase 4 | RunspacePool v3 |

---

## Expected Build Results

| Metric | Target |
|--------|--------|
| `dotnet build` errors | 0 |
| StyleCop warnings | 0 |
| PSScriptAnalyzer issues | 0 |
| xUnit tests passing | 200+ |
| Pester tests passing | 500+ |
| Code coverage (C#) | >90% |
| Code coverage (PS) | 100% |
