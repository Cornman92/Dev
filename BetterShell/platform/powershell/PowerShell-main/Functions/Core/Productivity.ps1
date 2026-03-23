# Productivity.ps1 - Productivity enhancements for PowerShell

# Configuration
$script:ProductivityConfig = @{
    EnableAliases = $true
    EnableDirectoryBookmarks = $true
    EnableQuickEdit = $true
    EnableHistorySearch = $true
}

# Directory bookmarks
$script:DirectoryBookmarks = @{}

# Initialize productivity features
function Initialize-Productivity {
    [CmdletBinding()]
    param()
    
    # Load bookmarks if they exist
    $bookmarksFile = "$env:USERPROFILE\Documents\PowerShell\bookmarks.json"
    if (Test-Path $bookmarksFile) {
        $script:DirectoryBookmarks = Get-Content $bookmarksFile | ConvertFrom-Json -AsHashtable
    }
    
    # Set up quick edit mode if enabled
    if ($script:ProductivityConfig.EnableQuickEdit) {
        $quickEditCode = @"
        `$QuickEditCode = @'
        [DllImport("kernel32.dll")]
        public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
        [DllImport("kernel32.dll")]
        public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetStdHandle(int nStdHandle);
'@
        `$Kernel32 = Add-Type -MemberDefinition `$QuickEditCode -Name 'Kernel32' -Namespace 'Win32' -PassThru
        `$hStdOut = [Win32.Kernel32]::GetStdHandle(-11)
        [Win32.Kernel32]::GetConsoleMode(`$hStdOut, [ref]`$mode)
        [Win32.Kernel32]::SetConsoleMode(`$hStdOut, `$mode -bor 0x0040) | Out-Null
"@
        Add-Type -TypeDefinition $quickEditCode -Language CSharp
    }
    
    # Set up history search with fzf if available
    if ($script:ProductivityConfig.EnableHistorySearch -and (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
            
            $result = $(
                [System.Collections.ArrayList]::new([string[]](Get-Content (Get-PSReadLineOption).HistorySavePath)) |
                Sort-Object -Unique |
                fzf --height 40% --reverse --tac --no-sort --query $line
            )
            
            if ($result) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $result)
            }
        }
    }
    
    Write-Verbose "Productivity features initialized"
}

# Directory bookmarks
function Add-Bookmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Path = (Get-Location).Path
    )
    
    $script:DirectoryBookmarks[$Name] = $Path
    Save-Bookmarks
    Write-Host "Bookmark added: $Name -> $Path" -ForegroundColor Green
}

function Remove-Bookmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    if ($script:DirectoryBookmarks.ContainsKey($Name)) {
        $script:DirectoryBookmarks.Remove($Name)
        Save-Bookmarks
        Write-Host "Bookmark removed: $Name" -ForegroundColor Yellow
    } else {
        Write-Error "Bookmark not found: $Name"
    }
}

function Get-Bookmark {
    [CmdletBinding()]
    param(
        [string]$Name
    )
    
    if ($Name) {
        if ($script:DirectoryBookmarks.ContainsKey($Name)) {
            return $script:DirectoryBookmarks[$Name]
        } else {
            Write-Error "Bookmark not found: $Name"
            return $null
        }
    } else {
        return $script:DirectoryBookmarks.GetEnumerator() | Sort-Object Name
    }
}

function Set-LocationBookmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    $path = Get-Bookmark -Name $Name
    if ($path) {
        Set-Location $path
    }
}

function Save-Bookmarks {
    $bookmarksFile = "$env:USERPROFILE\Documents\PowerShell\bookmarks.json"
    $script:DirectoryBookmarks | ConvertTo-Json | Set-Content -Path $bookmarksFile -Force
}

# Set up aliases if enabled
if ($script:ProductivityConfig.EnableAliases) {
    Set-Alias -Name bm -Value Add-Bookmark -Scope Global -Force
    Set-Alias -Name gbm -Value Get-Bookmark -Scope Global -Force
    Set-Alias -Name rbm -Value Remove-Bookmark -Scope Global -Force
    Set-Alias -Name cdb -Value Set-LocationBookmark -Scope Global -Force
}

# Export public functions
export-modulemember -Function @(
    'Initialize-Productivity',
    'Add-Bookmark',
    'Get-Bookmark',
    'Remove-Bookmark',
    'Set-LocationBookmark'
)

# Initialize productivity features
Initialize-Productivity
