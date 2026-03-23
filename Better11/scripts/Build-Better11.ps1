#Requires -Version 5.1
<#
.SYNOPSIS
    Build, test, and package Better11.
.DESCRIPTION
    Restore, build, optionally run tests and create MSIX package.
    Use -Sign to sign the MSIX (requires SignTool and certificate).
.PARAMETER Configuration
    Build configuration (Debug or Release).
.PARAMETER Package
    Create MSIX package after build.
.PARAMETER Test
    Run all tests (dotnet test with code coverage).
.PARAMETER Sign
    Sign the MSIX after packaging (requires -Package). Set env SIGNTOOL_PATH, CERT_PATH, CERT_PASSWORD if not using defaults.
.EXAMPLE
    .\Build-Better11.ps1 -Configuration Release -Test -Package
.EXAMPLE
    .\Build-Better11.ps1 -Configuration Release -Package -Sign
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    [switch]$Test,
    [switch]$Package,
    [switch]$Sign
)

$ErrorActionPreference = 'Stop'
$SolutionRoot = Split-Path $PSScriptRoot -Parent
$SolutionFile = Join-Path $SolutionRoot 'Better11.sln'
$AppProj = Join-Path $SolutionRoot "src\Better11.App\Better11.App.csproj"

# MSBuild is required for the WinUI App project (XAML compiler). Prefer Visual Studio's MSBuild.
$MsBuildExe = $env:MSBUILD_PATH
if (-not $MsBuildExe -or -not (Test-Path $MsBuildExe)) {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsPath = & $vswhere -latest -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' | Select-Object -First 1
        if ($vsPath) { $MsBuildExe = $vsPath }
    }
}
if (-not $MsBuildExe -or -not (Test-Path $MsBuildExe)) {
    $result = Get-ChildItem -Path "${env:ProgramFiles}\Microsoft Visual Studio" -Recurse -Filter 'MSBuild.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($result) { $MsBuildExe = $result.FullName }
}

Write-Host "Better11 Build Script" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration"
Write-Host "Platform: x64"
if ($Package) { Write-Host "Package: yes" }
if ($Sign) { Write-Host "Sign: yes (after package)" }
Write-Host ""

# Step 1: Restore
Write-Host "[1/4] Restoring packages..." -ForegroundColor Yellow
dotnet restore $SolutionFile --verbosity minimal
if ($LASTEXITCODE -ne 0) { throw "Restore failed" }

# Step 2: Build (use MSBuild with Platform=x64 for WinUI XAML; dotnet build can fail with XamlCompiler)
Write-Host "[2/4] Building solution..." -ForegroundColor Yellow
if ($MsBuildExe) {
    & $MsBuildExe $SolutionFile -p:Configuration=$Configuration -p:Platform=x64 -t:Build -v:minimal -nologo -warnaserror
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }
} else {
    Write-Host "  MSBuild not found; using dotnet build (may fail on WinUI XAML)." -ForegroundColor Yellow
    dotnet build $SolutionFile --configuration $Configuration -p:Platform=x64 --no-restore -warnaserror
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }
}
Write-Host "  Build succeeded" -ForegroundColor Green

# Step 3: Test (use Platform=x64 to match build output)
if ($Test) {
    Write-Host "[3/5] Running tests..." -ForegroundColor Yellow
    dotnet test $SolutionFile --configuration $Configuration -p:Platform=x64 --no-build --verbosity normal `
        --collect:"XPlat Code Coverage" `
        --results-directory (Join-Path $SolutionRoot 'TestResults')
    if ($LASTEXITCODE -ne 0) { throw "Tests failed" }
    Write-Host "  All tests passed" -ForegroundColor Green
} else {
    Write-Host "[3/5] Tests skipped (use -Test to run)" -ForegroundColor Gray
}

# Step 4: Package
$ArtifactsDir = Join-Path $SolutionRoot 'artifacts'
if ($Package) {
    Write-Host "[4/5] Creating MSIX package..." -ForegroundColor Yellow
    if (-not (Test-Path $AppProj)) { throw "App project not found: $AppProj" }
    dotnet publish $AppProj --configuration $Configuration `
        -p:Platform=x64 `
        -p:GenerateAppxPackageOnBuild=true `
        --output $ArtifactsDir
    if ($LASTEXITCODE -ne 0) { throw "Packaging failed" }
    $msix = Get-ChildItem -Path $ArtifactsDir -Filter '*.msix' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($msix) { Write-Host "  MSIX: $($msix.Name)" -ForegroundColor Green }
    Write-Host "  Output: $ArtifactsDir" -ForegroundColor Green
} else {
    Write-Host "[4/5] Packaging skipped (use -Package to create)" -ForegroundColor Gray
}

# Step 5: Sign (optional)
if ($Sign -and $Package) {
    Write-Host "[5/5] Signing MSIX..." -ForegroundColor Yellow
    $certPath = $env:CERT_PATH
    $certPass = $env:CERT_PASSWORD
    if (-not $certPath -or -not (Test-Path $certPath)) {
        Write-Host "  Sign skipped: set CERT_PATH (and CERT_PASSWORD) to sign, or use SignTool manually." -ForegroundColor Gray
    } else {
        $signtool = $env:SIGNTOOL_PATH
        if (-not $signtool) { $signtool = 'signtool.exe' }
        $msixPath = Get-ChildItem -Path $ArtifactsDir -Filter '*.msix' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        if ($msixPath) {
            $signArgs = @('sign', '/fd', 'SHA256', '/f', $certPath, '/tr', 'http://timestamp.digicert.com', '/td', 'SHA256')
            if ($certPass) { $signArgs += @('/p', $certPass) }
            $signArgs += $msixPath
            & $signtool @signArgs
            if ($LASTEXITCODE -eq 0) { Write-Host "  Signed successfully" -ForegroundColor Green } else { throw "Sign failed" }
        }
    }
} else {
    Write-Host "[5/5] Sign skipped" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Build complete!" -ForegroundColor Green
