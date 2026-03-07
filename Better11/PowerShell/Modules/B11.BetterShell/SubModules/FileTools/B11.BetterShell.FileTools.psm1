#Requires -Version 7.0
using namespace System.Collections.Generic

function Find-B11File { [CmdletBinding()][OutputType([System.IO.FileInfo[]])] param([Parameter(Mandatory)][string]$Path, [string]$Pattern = '*', [switch]$Recurse, [long]$MinSizeBytes, [long]$MaxSizeBytes, [datetime]$ModifiedAfter, [datetime]$ModifiedBefore, [int]$MaxDepth = 10)
    $searchOption = if ($Recurse) { [System.IO.SearchOption]::AllDirectories } else { [System.IO.SearchOption]::TopDirectoryOnly }
    $files = [System.IO.Directory]::EnumerateFiles($Path, $Pattern, $searchOption)
    foreach ($f in $files) { $fi = [System.IO.FileInfo]::new($f)
        if ($MinSizeBytes -and $fi.Length -lt $MinSizeBytes) { continue }
        if ($MaxSizeBytes -and $fi.Length -gt $MaxSizeBytes) { continue }
        if ($ModifiedAfter -and $fi.LastWriteTime -lt $ModifiedAfter) { continue }
        if ($ModifiedBefore -and $fi.LastWriteTime -gt $ModifiedBefore) { continue }
        $fi } }

function Get-B11FileHash { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory,ValueFromPipeline)][string[]]$Path, [ValidateSet('SHA256','SHA1','MD5')][string]$Algorithm = 'SHA256')
    process { foreach ($p in $Path) { $hash = Get-FileHash -Path $p -Algorithm $Algorithm; [PSCustomObject]@{ PSTypeName = 'B11.FileHash'; Path = $p; Algorithm = $Algorithm; Hash = $hash.Hash; Size = (Get-Item $p).Length } } } }

function Compare-B11Directories { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory)][string]$ReferencePath, [Parameter(Mandatory)][string]$DifferencePath, [switch]$IncludeContent)
    $refFiles = Get-ChildItem -Path $ReferencePath -Recurse -File | ForEach-Object { @{ Relative = $_.FullName.Substring($ReferencePath.Length); Size = $_.Length; Modified = $_.LastWriteTime } }
    $diffFiles = Get-ChildItem -Path $DifferencePath -Recurse -File | ForEach-Object { @{ Relative = $_.FullName.Substring($DifferencePath.Length); Size = $_.Length; Modified = $_.LastWriteTime } }
    $refLookup = @{}; $refFiles | ForEach-Object { $refLookup[$_.Relative] = $_ }
    $diffLookup = @{}; $diffFiles | ForEach-Object { $diffLookup[$_.Relative] = $_ }
    $onlyInRef = $refLookup.Keys | Where-Object { -not $diffLookup.ContainsKey($_) }
    $onlyInDiff = $diffLookup.Keys | Where-Object { -not $refLookup.ContainsKey($_) }
    $modified = $refLookup.Keys | Where-Object { $diffLookup.ContainsKey($_) -and $refLookup[$_].Size -ne $diffLookup[$_].Size }
    [PSCustomObject]@{ PSTypeName = 'B11.DirComparison'; OnlyInReference = @($onlyInRef); OnlyInDifference = @($onlyInDiff); Modified = @($modified); ReferenceCount = $refFiles.Count; DifferenceCount = $diffFiles.Count } }

function Get-B11DuplicateFiles { [CmdletBinding()][OutputType([PSCustomObject[]])] param([Parameter(Mandatory)][string]$Path, [switch]$Recurse, [long]$MinSize = 1)
    $files = Get-ChildItem -Path $Path -Recurse:$Recurse -File | Where-Object { $_.Length -ge $MinSize }
    $sizeGroups = $files | Group-Object -Property Length | Where-Object { $_.Count -gt 1 }
    foreach ($group in $sizeGroups) { $hashes = $group.Group | ForEach-Object { @{ Path = $_.FullName; Hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash } }
        $hashGroups = $hashes | Group-Object -Property Hash | Where-Object { $_.Count -gt 1 }
        foreach ($hg in $hashGroups) { [PSCustomObject]@{ PSTypeName = 'B11.DuplicateGroup'; Hash = $hg.Name; Size = $group.Name; Files = @($hg.Group.Path); Count = $hg.Count } } } }

function Get-B11DirectorySize { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory,ValueFromPipeline)][string[]]$Path, [switch]$Recurse, [int]$TopN = 10)
    process { foreach ($p in $Path) { $items = Get-ChildItem -Path $p -Recurse:$Recurse -File -ErrorAction SilentlyContinue
        $totalSize = ($items | Measure-Object -Property Length -Sum).Sum
        $topItems = $items | Sort-Object Length -Descending | Select-Object -First $TopN
        [PSCustomObject]@{ PSTypeName = 'B11.DirSize'; Path = $p; TotalBytes = $totalSize; FormattedSize = '{0:N2} MB' -f ($totalSize / 1MB); FileCount = $items.Count; TopFiles = $topItems } } } }

function New-B11TempFile { [CmdletBinding()][OutputType([string])] param([string]$Extension = '.tmp', [string]$Prefix = 'b11_')
    $dir = [System.IO.Path]::GetTempPath(); $name = "$Prefix$(Get-Random -Maximum 999999)$Extension"; $path = Join-Path $dir $name; [System.IO.File]::Create($path).Dispose(); $path }

function Copy-B11WithProgress { [CmdletBinding(SupportsShouldProcess)][OutputType([void])] param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Destination, [int]$BufferSize = 4MB)
    if ($PSCmdlet.ShouldProcess($Source, "Copy to $Destination")) { $srcStream = [System.IO.File]::OpenRead($Source); $dstStream = [System.IO.File]::Create($Destination)
        try { $buffer = [byte[]]::new($BufferSize); $totalRead = 0L; $srcLength = $srcStream.Length
            while (($read = $srcStream.Read($buffer, 0, $buffer.Length)) -gt 0) { $dstStream.Write($buffer, 0, $read); $totalRead += $read
                $pct = [int](($totalRead / $srcLength) * 100); Write-Progress -Activity "Copying" -Status "$pct%" -PercentComplete $pct }
        } finally { $srcStream.Dispose(); $dstStream.Dispose() } Write-Progress -Activity "Copying" -Completed } }

function Rename-B11Bulk { [CmdletBinding(SupportsShouldProcess)][OutputType([PSCustomObject[]])] param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Pattern, [Parameter(Mandatory)][string]$Replacement, [switch]$Recurse)
    $files = Get-ChildItem -Path $Path -Recurse:$Recurse -File | Where-Object { $_.Name -match $Pattern }
    foreach ($f in $files) { $newName = $f.Name -replace $Pattern, $Replacement
        if ($PSCmdlet.ShouldProcess($f.Name, "Rename to $newName")) { Rename-Item -Path $f.FullName -NewName $newName
            [PSCustomObject]@{ OldName = $f.Name; NewName = $newName; Path = $f.DirectoryName } } } }

function Get-B11FileEncoding { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory,ValueFromPipeline)][string[]]$Path)
    process { foreach ($p in $Path) { $bytes = [System.IO.File]::ReadAllBytes($p) | Select-Object -First 4
        $encoding = if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { 'UTF-8 BOM' }
        elseif ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { 'UTF-16 LE' }
        elseif ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { 'UTF-16 BE' }
        else { 'UTF-8 (no BOM) / ASCII' }
        [PSCustomObject]@{ PSTypeName = 'B11.FileEncoding'; Path = $p; Encoding = $encoding } } } }

function Convert-B11FileEncoding { [CmdletBinding(SupportsShouldProcess)][OutputType([void])] param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][ValidateSet('UTF8','UTF8BOM','ASCII','Unicode')][string]$TargetEncoding)
    if ($PSCmdlet.ShouldProcess($Path, "Convert to $TargetEncoding")) {
        $content = [System.IO.File]::ReadAllText($Path)
        $enc = switch ($TargetEncoding) { 'UTF8' { [System.Text.UTF8Encoding]::new($false) } 'UTF8BOM' { [System.Text.UTF8Encoding]::new($true) } 'ASCII' { [System.Text.Encoding]::ASCII } 'Unicode' { [System.Text.Encoding]::Unicode } }
        [System.IO.File]::WriteAllText($Path, $content, $enc) } }

function Get-B11FileLineCount { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory,ValueFromPipeline)][string[]]$Path)
    process { foreach ($p in $Path) { $lines = [System.IO.File]::ReadAllLines($p).Count; [PSCustomObject]@{ PSTypeName = 'B11.LineCount'; Path = $p; Lines = $lines } } } }

function Merge-B11Files { [CmdletBinding(SupportsShouldProcess)][OutputType([void])] param([Parameter(Mandatory)][string[]]$InputFiles, [Parameter(Mandatory)][string]$OutputFile, [string]$Separator = [Environment]::NewLine)
    if ($PSCmdlet.ShouldProcess($OutputFile, "Merge $($InputFiles.Count) files")) { $content = $InputFiles | ForEach-Object { [System.IO.File]::ReadAllText($_) }; [System.IO.File]::WriteAllText($OutputFile, ($content -join $Separator)) } }

function Split-B11File { [CmdletBinding(SupportsShouldProcess)][OutputType([PSCustomObject[]])] param([Parameter(Mandatory)][string]$Path, [int]$LinesPerChunk = 1000, [string]$OutputDirectory)
    if (-not $OutputDirectory) { $OutputDirectory = [System.IO.Path]::GetDirectoryName($Path) }
    if ($PSCmdlet.ShouldProcess($Path, "Split into chunks of $LinesPerChunk lines")) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Path); $ext = [System.IO.Path]::GetExtension($Path)
        $lines = [System.IO.File]::ReadAllLines($Path); $chunkNum = 0; $results = [List[PSCustomObject]]::new()
        for ($i = 0; $i -lt $lines.Count; $i += $LinesPerChunk) { $chunkNum++
            $chunk = $lines[$i..([Math]::Min($i + $LinesPerChunk - 1, $lines.Count - 1))]
            $outPath = Join-Path $OutputDirectory "${baseName}_part${chunkNum}${ext}"
            [System.IO.File]::WriteAllLines($outPath, $chunk)
            $results.Add([PSCustomObject]@{ Path = $outPath; Lines = $chunk.Count; ChunkNumber = $chunkNum }) }
        $results } }

Export-ModuleMember -Function @(
    'Find-B11File', 'Get-B11FileHash', 'Compare-B11Directories', 'Get-B11DuplicateFiles',
    'Get-B11DirectorySize', 'New-B11TempFile', 'Copy-B11WithProgress', 'Rename-B11Bulk',
    'Get-B11FileEncoding', 'Convert-B11FileEncoding', 'Get-B11FileLineCount',
    'Merge-B11Files', 'Split-B11File'
)
