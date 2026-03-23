# Aurora.Integrity
function Get-AuroraFileHash {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Path not found: $Path" }
    $h = Get-FileHash -Algorithm SHA256 -LiteralPath $Path
    [pscustomobject]@{ Path = (Resolve-Path -LiteralPath $Path).ProviderPath; Sha256 = $h.Hash; Length = (Get-Item -LiteralPath $Path).Length }
}

function New-AuroraIntegrityManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$OutFile
    )
    $files = Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction Stop
    $entries = foreach ($f in $files) { Get-AuroraFileHash -Path $f.FullName }
    $manifest = [pscustomobject]@{
        Generated = (Get-Date -Format o)
        Root = (Resolve-Path -LiteralPath $Root).ProviderPath
        Files = $entries
    }
    $json = $manifest | ConvertTo-Json -Depth 6
    $outDir = Split-Path -Parent $OutFile
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
    $json | Set-Content -LiteralPath $OutFile -Encoding UTF8
    return $OutFile
}

function Test-AuroraIntegrityManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Manifest)
    if (-not (Test-Path -LiteralPath $Manifest)) { throw "Manifest not found: $Manifest" }
    $obj = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
    $mismatch = @()
    foreach ($f in $obj.Files) {
        if (-not (Test-Path -LiteralPath $f.Path)) { $mismatch += [pscustomobject]@{ Path=$f.Path; Issue='Missing' }; continue }
        $h = Get-FileHash -Algorithm SHA256 -LiteralPath $f.Path
        if ($h.Hash -ne $f.Sha256) { $mismatch += [pscustomobject]@{ Path=$f.Path; Issue='HashMismatch' } }
    }
    [pscustomobject]@{ Pass = ($mismatch.Count -eq 0); Issues = $mismatch }
}

Export-ModuleMember -Function Get-AuroraFileHash, New-AuroraIntegrityManifest, Test-AuroraIntegrityManifest
