$src = "C:\Users\C-Man\OneDrive\Dev"
$dst = "D:\Dev"
$log = "D:\Dev\migration.log"

$excludeDirNames = @('.venv','node_modules','.nuget','__pycache__','packages','obj','bin','.quarantine_20251120-191327','.quarantine_20251120-191327(1)')
$excludeExts = @('.wim','.img','.iso','.vhd','.vhdx')
$excludeFiles = @('SoftPerfect.RamDisk-12GB.img','github-recovery-codes.txt','2FA-AccessToken.txt','Session3-PowerShellService.tar.gz')

function Copy-Dir {
    param([string]$SrcDir, [string]$DstDir)
    if (-not (Test-Path $DstDir)) { New-Item -ItemType Directory -Path $DstDir -Force | Out-Null }
    foreach ($item in Get-ChildItem -Path $SrcDir -Force -ErrorAction SilentlyContinue) {
        if ($item.PSIsContainer) {
            if ($item.Name -notin $excludeDirNames) {
                Copy-Dir $item.FullName (Join-Path $DstDir $item.Name)
            }
        } else {
            $skip = $false
            foreach ($e in $excludeExts) {
                if ($item.Name.EndsWith($e, [System.StringComparison]::OrdinalIgnoreCase)) { $skip = $true; break }
            }
            if ($item.Name -in $excludeFiles) { $skip = $true }
            if (-not $skip) { Copy-Item $item.FullName $DstDir -Force -ErrorAction SilentlyContinue }
        }
    }
}

$dirs = @(
    'PowerShell','ProfileMega','dev-dashboard','My-WinPE-RE','Skills','Skills-MCP',
    'scripts','modules','claude-agents','data',
    'project-scaffolder-mcp-server','code-analysis-mcp-server','dotnet-cli-mcp-server',
    'nuget-mcp-server','powershell-mcp-server','system-info-mcp-server','winget-mcp-server',
    'docs','Config','configs','deployment','deployment-toolkit','GoldenImage',
    'platform','TUI','PostInstall','PSModules','PSColor','tests','subagent-system',
    'onedrive-cleanup','GitHub','enhanced-catalog','EnvConfig','FunctionCatalog',
    'maintenance','manifest','Manifests','Onboarding','PluginRegistry','Journal',
    'CMan-Projects-Consolidated','apps','OwnershipToolkit','ISOBuilder','Shared',
    'Documentation','bootstrap','misc','DeploymentPipeline_USB'
)

foreach ($dir in $dirs) {
    $s = Join-Path $src $dir
    $d = Join-Path $dst $dir
    if (Test-Path $s) {
        "[$(Get-Date -Format 'HH:mm:ss')] Copying $dir..." | Out-File $log -Append -Encoding UTF8
        Copy-Dir $s $d
        "[$(Get-Date -Format 'HH:mm:ss')] Done $dir" | Out-File $log -Append -Encoding UTF8
    }
}

# Root-level files
$rootExts = @('.ps1','.psm1','.psd1','.reg','.cmd','.bat','.py','.json','.md','.txt','.xml','.yml','.yaml','.csv','.ini')
Get-ChildItem -Path $src -File -Force | Where-Object {
    $_.Name -notin $excludeFiles -and $_.Extension -in $rootExts
} | ForEach-Object {
    $dstFile = Join-Path $dst $_.Name
    if (-not (Test-Path $dstFile)) { Copy-Item $_.FullName $dstFile -Force -ErrorAction SilentlyContinue }
}

"[$(Get-Date -Format 'HH:mm:ss')] ALL DONE" | Out-File $log -Append -Encoding UTF8
