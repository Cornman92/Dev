# Prepare-DeploymentShare.ps1
# Validates and prepares deployment share for use

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $SharePath,

    [Parameter()]
    [switch] $ValidateWimFiles,

    [Parameter()]
    [switch] $ValidateDriverPacks,

    [Parameter()]
    [switch] $ValidateAppSources
)

$ErrorActionPreference = 'Stop'

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Prepare Deployment Share                 ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$sharePath = (Resolve-Path $SharePath).ProviderPath

if (-not (Test-Path $sharePath)) {
    throw "Deployment share path does not exist: $sharePath"
}

Write-Host "Validating deployment share: $sharePath" -ForegroundColor White
Write-Host ''

$errors = @()
$warnings = @()

# Check directory structure
Write-Host "Checking directory structure..." -ForegroundColor Yellow
$requiredDirs = @('Drivers', 'Apps', 'Images', 'Logs')
foreach ($dir in $requiredDirs) {
    $dirPath = Join-Path $sharePath $dir
    if (Test-Path $dirPath) {
        Write-Host "  ✓ $dir exists" -ForegroundColor Green
    }
    else {
        $errors += "Required directory missing: $dir"
        Write-Host "  ✗ $dir missing" -ForegroundColor Red
    }
}

# Validate WIM files
if ($ValidateWimFiles) {
    Write-Host ''
    Write-Host "Validating WIM files..." -ForegroundColor Yellow
    $imagesPath = Join-Path $sharePath 'Images'
    
    if (Test-Path $imagesPath) {
        $wimFiles = Get-ChildItem -Path $imagesPath -Filter '*.wim' -File
        
        if ($wimFiles.Count -eq 0) {
            $warnings += "No WIM files found in Images directory"
            Write-Host "  ⚠ No WIM files found" -ForegroundColor Yellow
        }
        else {
            foreach ($wim in $wimFiles) {
                Write-Host "  Checking $($wim.Name)..." -ForegroundColor Gray
                
                try {
                    $imageInfo = Get-WindowsImage -ImagePath $wim.FullName -ErrorAction Stop
                    Write-Host "    ✓ Valid WIM file with $($imageInfo.Count) image(s)" -ForegroundColor Green
                    
                    foreach ($img in $imageInfo) {
                        Write-Host "      - Index $($img.ImageIndex): $($img.ImageName) ($($img.ImageDescription))" -ForegroundColor Gray
                    }
                }
                catch {
                    $errors += "Invalid WIM file: $($wim.Name) - $($_.Exception.Message)"
                    Write-Host "    ✗ Invalid WIM file: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
}

# Validate driver packs
if ($ValidateDriverPacks) {
    Write-Host ''
    Write-Host "Validating driver packs..." -ForegroundColor Yellow
    $driversPath = Join-Path $sharePath 'Drivers'
    
    if (Test-Path $driversPath) {
        $driverDirs = Get-ChildItem -Path $driversPath -Directory -Recurse
        
        if ($driverDirs.Count -eq 0) {
            $warnings += "No driver pack directories found"
            Write-Host "  ⚠ No driver pack directories found" -ForegroundColor Yellow
        }
        else {
            $validPacks = 0
            foreach ($dir in $driverDirs) {
                $infFiles = Get-ChildItem -Path $dir.FullName -Filter '*.inf' -File -ErrorAction SilentlyContinue
                if ($infFiles.Count -gt 0) {
                    $validPacks++
                    Write-Host "  ✓ $($dir.FullName.Replace($driversPath, 'Drivers')) - $($infFiles.Count) INF file(s)" -ForegroundColor Green
                }
            }
            
            if ($validPacks -eq 0) {
                $warnings += "No valid driver packs found (no INF files)"
            }
        }
    }
}

# Validate app sources
if ($ValidateAppSources) {
    Write-Host ''
    Write-Host "Validating application sources..." -ForegroundColor Yellow
    $appsPath = Join-Path $sharePath 'Apps'
    
    if (Test-Path $appsPath) {
        $appFiles = Get-ChildItem -Path $appsPath -Include *.msi,*.exe,*.msix -File -Recurse
        
        if ($appFiles.Count -eq 0) {
            $warnings += "No application installers found"
            Write-Host "  ⚠ No application installers found" -ForegroundColor Yellow
        }
        else {
            Write-Host "  ✓ Found $($appFiles.Count) application installer(s)" -ForegroundColor Green
            
            $byType = $appFiles | Group-Object Extension
            foreach ($group in $byType) {
                Write-Host "    - $($group.Name): $($group.Count) file(s)" -ForegroundColor Gray
            }
        }
    }
}

# Summary
Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Validation Summary                       ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ Deployment share is ready!" -ForegroundColor Green
    exit 0
}
else {
    if ($errors.Count -gt 0) {
        Write-Host "Errors found:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  ✗ $error" -ForegroundColor Red
        }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  ⚠ $warning" -ForegroundColor Yellow
        }
    }
    
    if ($errors.Count -gt 0) {
        exit 1
    }
    else {
        exit 0
    }
}

