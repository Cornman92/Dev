#Requires -Version 7.0
# Base utilities: define only if not already present (e.g. from CTT base profile).
# Ensures ProfileMega-only usage still has these; when base runs first, base definitions are kept.

if (-not (Get-Command -Name 'Edit-Profile' -ErrorAction SilentlyContinue)) {
    function Edit-Profile {
        param([string]$Target = 'Profile')
        $path = if ($Target -eq 'Config') {
            $up = Join-Path $Global:ProfileMegaRoot 'ProfileMegaUser.ps1'
            if (Test-Path $up) { $up } else { Join-Path $Global:ProfileMegaRoot 'Scripts\Config.ps1' }
        } else { $PROFILE.CurrentUserAllHosts }
        $editor = if (Get-Command code -ErrorAction SilentlyContinue) { 'code' } else { 'notepad' }
        & $editor $path
    }
}

if (-not (Get-Command -Name 'reload-profile' -ErrorAction SilentlyContinue)) {
    function reload-profile { & $PROFILE }
}

if (-not (Get-Command -Name 'touch' -ErrorAction SilentlyContinue)) {
    function touch { param($file) "" | Out-File $file -Encoding utf8 }
}

if (-not (Get-Command -Name 'ff' -ErrorAction SilentlyContinue)) {
    function ff {
        param($name)
        Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    }
}

if (-not (Get-Command -Name 'trash' -ErrorAction SilentlyContinue)) {
    function trash {
        param($path)
        $fullPath = (Resolve-Path -Path $path -ErrorAction SilentlyContinue).Path
        if (-not $fullPath) { Write-Warning "Path not found: $path"; return }
        $item = Get-Item $fullPath
        $parentPath = if ($item.PSIsContainer) { $item.Parent.FullName } else { $item.DirectoryName }
        $shell = New-Object -ComObject 'Shell.Application'
        $shell.NameSpace($parentPath).ParseName($item.Name).InvokeVerb('delete')
        Write-Host "Moved to Recycle Bin: $fullPath" -ForegroundColor Green
    }
}

if (-not (Get-Command -Name 'head' -ErrorAction SilentlyContinue)) {
    function head { param($Path, $n = 10) Get-Content $Path -Head $n }
}

if (-not (Get-Command -Name 'tail' -ErrorAction SilentlyContinue)) {
    function tail { param($Path, $n = 10, [switch]$f) Get-Content $Path -Tail $n -Wait:$f }
}

if (-not (Get-Command -Name 'nf' -ErrorAction SilentlyContinue)) {
    function nf { param($name) New-Item -ItemType File -Path . -Name $name }
}

if (-not (Get-Command -Name 'mkcd' -ErrorAction SilentlyContinue)) {
    function mkcd { param($dir) New-Item -ItemType Directory -Path $dir -Force | Out-Null; Set-Location $dir }
}

if (-not (Get-Command -Name 'cpy' -ErrorAction SilentlyContinue)) {
    function cpy { Set-Clipboard $args[0] }
}

if (-not (Get-Command -Name 'pst' -ErrorAction SilentlyContinue)) {
    function pst { Get-Clipboard }
}

if (-not (Get-Command -Name 'which' -ErrorAction SilentlyContinue)) {
    function which { param($name) (Get-Command $name -ErrorAction SilentlyContinue).Source }
}

if (-not (Get-Command -Name 'uptime' -ErrorAction SilentlyContinue)) {
    function uptime {
        try {
            $since = (Get-Uptime -Since).ToString()
            $uptime = Get-Uptime
            Write-Host "Boot: $since | Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Gray
        } catch { Write-Warning "Get-Uptime not available: $_" }
    }
}

if (-not (Get-Command -Name 'docs' -ErrorAction SilentlyContinue)) {
    function docs {
        $docs = [Environment]::GetFolderPath('MyDocuments')
        if (-not $docs) { $docs = Join-Path $HOME 'Documents' }
        Set-Location $docs
    }
}

if (-not (Get-Command -Name 'dtop' -ErrorAction SilentlyContinue)) {
    function dtop {
        $dtop = [Environment]::GetFolderPath('Desktop')
        if (-not $dtop) { $dtop = Join-Path $HOME 'Desktop' }
        Set-Location $dtop
    }
}

if (-not (Get-Command -Name 'flushdns' -ErrorAction SilentlyContinue)) {
    function flushdns {
        Clear-DnsClientCache
        Write-Host "DNS cache cleared." -ForegroundColor Green
    }
}

if (-not (Get-Command -Name 'Get-PubIP' -ErrorAction SilentlyContinue)) {
    function Get-PubIP { (Invoke-WebRequest -Uri 'https://ifconfig.me/ip' -UseBasicParsing).Content.Trim() }
}

if (-not (Get-Command -Name 'k9' -ErrorAction SilentlyContinue)) {
    function k9 { param($name) Stop-Process -Name $name -Force -ErrorAction SilentlyContinue }
}

if (-not (Get-Command -Name 'la' -ErrorAction SilentlyContinue)) {
    function la { Get-ChildItem | Format-Table -AutoSize }
}

if (-not (Get-Command -Name 'll' -ErrorAction SilentlyContinue)) {
    function ll { Get-ChildItem -Force | Format-Table -AutoSize }
}

if (-not (Get-Command -Name 'unzip' -ErrorAction SilentlyContinue)) {
    function unzip {
        param($file)
        $full = (Get-ChildItem -Path . -Filter $file -ErrorAction SilentlyContinue).FullName
        if ($full) { Expand-Archive -Path $full -DestinationPath .; Write-Host "Extracted to $PWD" -ForegroundColor Green }
    }
}

if (-not (Get-Command -Name 'grep' -ErrorAction SilentlyContinue)) {
    function grep { param($regex, $dir) if ($dir) { Get-ChildItem $dir | Select-String $regex } else { $input | Select-String $regex } }
}

if (-not (Get-Command -Name 'sed' -ErrorAction SilentlyContinue)) {
    function sed { param($file, $find, $replace) (Get-Content $file -Raw).Replace($find, $replace) | Set-Content $file -NoNewline }
}

if (-not (Get-Command -Name 'export' -ErrorAction SilentlyContinue)) {
    function export { param($name, $value) Set-Item -Path "env:$name" -Value $value -Force }
}

if (-not (Get-Command -Name 'pkill' -ErrorAction SilentlyContinue)) {
    function pkill { param($name) Get-Process $name -ErrorAction SilentlyContinue | Stop-Process }
}

if (-not (Get-Command -Name 'pgrep' -ErrorAction SilentlyContinue)) {
    function pgrep { param($name) Get-Process $name -ErrorAction SilentlyContinue }
}

if (-not (Get-Command -Name 'sysinfo' -ErrorAction SilentlyContinue)) {
    function sysinfo { Get-ComputerInfo }
}

if (-not (Get-Command -Name 'admin' -ErrorAction SilentlyContinue)) {
    function admin {
        if ($args.Count -gt 0) {
            $argList = $args -join ' '
            Start-Process wt -Verb runAs -ArgumentList "pwsh -NoExit -Command $argList"
        } else {
            Start-Process wt -Verb runAs
        }
    }
}

if (-not (Get-Command -Name 'df' -ErrorAction SilentlyContinue)) {
    function df { Get-Volume }
}

if (-not (Get-Command -Name 'hb' -ErrorAction SilentlyContinue)) {
    function hb {
        param([Parameter(Mandatory = $true)][string]$FilePath)
        if (-not (Test-Path $FilePath)) {
            Write-Error "File not found: $FilePath"
            return
        }
        $baseUrl = $Global:ProfileConfig.HastebinUrl
        if ([string]::IsNullOrWhiteSpace($baseUrl)) {
            Write-Host "Set ProfileConfig.HastebinUrl or use base profile's hb." -ForegroundColor Yellow
            return
        }
        $baseUrl = $baseUrl.TrimEnd('/')
        $postUrl = "$baseUrl/documents"
        $content = Get-Content $FilePath -Raw
        try {
            $response = Invoke-RestMethod -Uri $postUrl -Method Post -Body $content -ErrorAction Stop
            $pasteUrl = if ($response.key) { "$baseUrl/$($response.key)" } elseif ($response.url) { $response.url } else { $response }
            Set-Clipboard $pasteUrl
            Write-Host $pasteUrl
        } catch {
            Write-Error "hb failed: $_"
        }
    }
}
