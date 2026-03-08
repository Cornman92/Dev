# Better11 — Build and Test

This document describes how to build, test, and package Better11.

Current verified baseline: on 2026-03-08, the repo-root solution built successfully through `.\scripts\Build-Better11.ps1 -Configuration Release`, the app launched successfully from the Release/x64 output, and the 7 in-solution projects passed through `dotnet test Better11.sln -c Release -p:Platform=x64`.

## Prerequisites

- **.NET 8 SDK** (or version specified in `global.json`).
- **Windows 10/11** (x64) with Windows SDK 10.0.22621 or later for WinUI 3 / MSIX.
- **PowerShell 5.1+** (or PowerShell Core 7+) for build scripts and Pester/PSScriptAnalyzer.

Optional for full pipeline:

- **Pester 5** — `Install-Module -Name Pester -Force -SkipPublisherCheck`
- **PSScriptAnalyzer** — `Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck`

## Solution layout

The primary solution is:

- **Better11.sln** — Repo-root C# solution (Core, Services, ViewModels, App, and test projects).

Build from the solution directory:

```powershell
cd D:\Dev\Better11
```

## Build commands

### Restore and build

```powershell
dotnet restore Better11.sln
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" Better11.sln -p:Configuration=Release -p:Platform=x64 -t:Build -v:minimal -nologo
```

Warnings are treated as errors (`-warnaserror` in the build script). For the WinUI app, prefer the MSBuild/x64 path above or the build script below; `dotnet build Better11.sln` is not the canonical app build workflow for this repo.

### Build script (recommended)

From the repo root:

```powershell
.\scripts\Build-Better11.ps1 -Configuration Release
.\scripts\Build-Better11.ps1 -Configuration Release -Test
.\scripts\Build-Better11.ps1 -Configuration Release -Test -Package
```

- **-Test**: Runs `dotnet test` with code coverage; results in `TestResults/`.
- **-Package**: Publishes the app and creates the MSIX package in `artifacts/`.

### Run tests

```powershell
dotnet test Better11.sln --configuration Release -p:Platform=x64 --verbosity normal
```

With code coverage (Coverlet):

```powershell
dotnet test Better11.sln --configuration Release -p:Platform=x64 --collect:"XPlat Code Coverage" --results-directory TestResults
```

Coverage results are written to `TestResults/**/coverage.cobertura.xml`. To fail the build when Core coverage drops below a threshold, use a coverage tool (e.g. ReportGenerator) or add a step in your pipeline that parses the report and exits non-zero if below 90%. See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution and test expectations.

### Single project

```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" src\Better11.App\Better11.App.csproj -p:Configuration=Release -p:Platform=x64 -t:Build -v:minimal -nologo
dotnet test tests\Better11.Services.Tests\Better11.Services.Tests.csproj -c Release -p:Platform=x64
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
2. Output: `artifacts\` (MSIX and dependencies).
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

See the workflow file for the exact steps. To run the same locally, use `.\scripts\Build-Better11.ps1 -Configuration Release -Test -Package` from the repo root.

## Two source trees

This repo contains two C# source trees:

- **src\** — Canonical tree used by `Better11.sln`.
- **Better11\src\** — Alternate tree kept for reference. It is not built by the repo-root solution during this stabilization pass.

When building from `Better11.sln`, only `src\` is built.

## Test scope notes

- `Better11.sln` currently contains 7 projects: 4 production projects and 3 xUnit test projects.
- The repo also contains `tests\TUI\*.cs`, but those tests are not referenced by `Better11.sln` and remain deferred for now.

## Troubleshooting

- **Build fails with missing SDK**: Install .NET 8 SDK and ensure `global.json` (if present) matches.
- **WinUI / MSIX errors**: Ensure Windows SDK 10.0.22621+ is installed and platform is x64.
- **Tests fail**: Run `dotnet test Better11.sln -c Release -p:Platform=x64 --verbosity detailed` and check TestResults for failures and coverage.
