function Invoke-FuzzyFind {
    [CmdletBinding()]
    param(
        [string]$InitialQuery
    )

    # Ensure fzf module is available
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        try {
            Install-Module -Name fzf -Scope CurrentUser -Force -ErrorAction Stop
        } catch {
            Write-Error "fzf module is required. Please install it by running: Install-Module fzf"
            return
        }
    }

    # Use fd for fast file searching if available, otherwise fallback to Get-ChildItem
    $finder = if (Get-Command fd -ErrorAction SilentlyContinue) {
        'fd --type f --hidden --exclude .git'
    } else {
        'gci -file -recurse -force -ErrorAction SilentlyContinue'
    }

    $selectedFile = Invoke-Expression $finder | fzf --query=$InitialQuery --preview 'bat --color=always --style=numbers --line-range=:500 {}'

    if ($selectedFile) {
        # Open the file in the default editor (VSCode in this case)
        code $selectedFile
    }
}
