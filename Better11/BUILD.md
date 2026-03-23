# Better11 — Build and Test

This document describes how to build, test, and package Better11.

## Prerequisites

- **.NET 8 SDK** (or version specified in `global.json`).
- **Windows 10/11** (x64) with Windows SDK 10.0.22621 or later for WinUI 3 / MSIX.
- **PowerShell 5.1+** (or PowerShell Core 7+) for build scripts and Pester/PSScriptAnalyzer.

Optional for full pipeline:

- **Pester 5** — `Install-Module -Name Pester -Force -SkipPublisherCheck`
- **PSScriptAnalyzer** — `Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck`

## Solution layout

The primary solution is:

- **Better11\Better11\Better11.sln** — C# solution (Core, Services, ViewModels, App, and test projects).

Build from the solution directory:

```powershell
cd D:\Dev\Better11\Better11
```

## Build commands

### Restore and build

```powershell
dotnet restore Better11.sln
dotnet build Better11.sln --configuration Release
```

Warnings are treated as errors (`-warnaserror` in the build script). Use `--no-incremental` for a clean build.

### Build script (recommended)

From `Better11\Better11`:

```powershell
.\scripts\Build-Better11.ps1 -Configuration Release
.\scripts\Build-Better11.ps1 -Configuration Release -Test
.\scripts\Build-Better11.ps1 -Configuration Release -Test -Package
```

- **-Test**: Runs `dotnet test` with code coverage; results in `TestResults/`.
- **-Package**: Publishes the app and creates the MSIX package in `artifacts/`.

### Run tests

```powershell
dotnet test Better11.sln --configuration Release --verbosity normal
```

With code coverage (Coverlet):

```powershell
dotnet test Better11.sln --configuration Release --collect:"XPlat Code Coverage" --results-directory TestResults
```

Coverage results are written to `TestResults/**/coverage.cobertura.xml`. To fail the build when Core coverage drops below a threshold, use a coverage tool (e.g. ReportGenerator) or add a step in your pipeline that parses the report and exits non-zero if below 90%. See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution and test expectations.

### Single project

```powershell
dotnet build src\Better11.App\Better11.App.csproj -c Release
dotnet test tests\Better11.Services.Tests\Better11.Services.Tests.csproj -c Release
```

## PowerShell linting and tests

From the repo root (e.g. `D:\Dev\Better11`):

- **PSScriptAnalyzer** (zero violations required):

  ```powershell
  Invoke-ScriptAnalyzer -Path .\PowerShell\Modules -Recurse -Settings .\config\PSScriptAnalyzerSettings.psd1
  ```

- **Pester** (PowerShell module tests):

  ```powershell
  Invoke-Pester -Path .\PowerShell\Modules -Output Detailed
  ```

Paths may differ if PowerShell modules live under `modules\`; adjust accordingly.

## Packaging (MSIX)

1. Build in Release: `.\scripts\Build-Better11.ps1 -Configuration Release -Package`
2. Output: `Better11\Better11\artifacts\` (MSIX and dependencies).
3. Optional: Sign the MSIX (see RELEASE.md).

### Signing the MSIX (optional)

To sign the MSIX with the build script, use the `-Sign` switch (requires `-Package`). Set these environment variables before running:

| Variable | Description |
|----------|-------------|
| `CERT_PATH` | Path to your code-signing certificate (e.g. `.pfx` file). |
| `CERT_PASSWORD` | Password for the certificate (if applicable). |
| `SIGNTOOL_PATH` | Optional. Path to `signtool.exe`; if not set, `signtool.exe` is used from PATH. |

Example:

```powershell
$env:CERT_PATH = "C:\path\to\your\cert.pfx"
$env:CERT_PASSWORD = "YourPassword"
.\scripts\Build-Better11.ps1 -Configuration Release -Package -Sign
```

If `CERT_PATH` is not set or the file is missing, the script skips signing and reports that signing was skipped.

## CI/CD

A GitHub Actions workflow is defined in `.github/workflows/ci.yml`:

- **On push/PR** to `main` or `develop`: restore, build, run xUnit tests with code coverage, run PSScriptAnalyzer and Pester on PowerShell modules.
- **On push** to `main` or `release`: after build succeeds, create the MSIX package and upload it as an artifact. Signing can be added via secrets (e.g. `CERT_PATH`, `CERT_PASSWORD`) and a signing step if required.

See the workflow file for the exact steps. To run the same locally, use `.\scripts\Build-Better11.ps1 -Configuration Release -Test -Package` from `Better11\Better11`.

## Two source trees

This repo contains two C# source trees:

- **Better11\Better11\src** — Used by `Better11.sln` (solution under `Better11\Better11`).
- **Better11\src** — Alternate tree with additional pages (e.g. Backup & Restore, User Accounts). May be merged or kept in sync; see docs on consolidation.

When building from `Better11.sln`, only the `Better11\Better11\src` tree is built.

## Troubleshooting

- **Build fails with missing SDK**: Install .NET 8 SDK and ensure `global.json` (if present) matches.
- **WinUI / MSIX errors**: Ensure Windows SDK 10.0.22621+ is installed and platform is x64.
- **Tests fail**: Run `dotnet test` with `--verbosity detailed` and check TestResults for failures and coverage.
