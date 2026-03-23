function Invoke-FuzzyFind {
    [CmdletBinding()]
    param(
        [string]$Directory = '.',
        [switch]$Preview
    )

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning "fzf is not installed. Please install it from https://github.com/junegunn/fzf"
        return
    }

    $previewCmd = if ($Preview) {
        '--preview="if [ -f {} ]; then bat --color=always --style=numbers {}; else tree -C {} | head -200; fi" --preview-window=right:60%'
    } else { '' }
    
    $selected = Get-ChildItem -Path $Directory -Recurse -ErrorAction SilentlyContinue |
               Select-Object -ExpandProperty FullName |
               fzf --height 40% --reverse --border $previewCmd
    
    if ($selected) {
        if (-not (Get-Item $selected).PSIsContainer) {
            Set-Location (Split-Path $selected)
        }
        return $selected
    }
}
