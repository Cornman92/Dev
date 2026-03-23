<#
.SYNOPSIS
    Generates a new PowerShell script from a standard template.

.DESCRIPTION
    Creates a new .ps1 file with boilerplate comment-based help,
    CmdletBinding, parameters, error handling, and the workspace
    header format. Saves time scaffolding new scripts.

.PARAMETER Name
    Name of the script to create (without .ps1 extension).

.PARAMETER Type
    Template type: 'Script' (standalone), 'Function' (reusable),
    or 'Optimization' (system tweak). Defaults to Script.

.PARAMETER OutputDir
    Directory to create the file in. Auto-selects based on Type
    if not specified: Scripts/, Functions/, or Optimizations/.

.PARAMETER Description
    Brief description for the help block.

.PARAMETER RequiresAdmin
    Include an admin check at the top of the script.

.PARAMETER Force
    Overwrite if file already exists.

.EXAMPLE
    .\New-ScriptFromTemplate.ps1 -Name "Get-UserSessions" -Description "Lists active user sessions"
    Creates Scripts/Get-UserSessions.ps1 with boilerplate.

.EXAMPLE
    .\New-ScriptFromTemplate.ps1 -Name "Invoke-Cleanup" -Type Optimization -RequiresAdmin
    Creates Optimizations/Invoke-Cleanup.ps1 with admin check.

.EXAMPLE
    .\New-ScriptFromTemplate.ps1 -Name "Format-Output" -Type Function
    Creates Functions/Format-Output.ps1 as a function template.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidatePattern('^[A-Za-z]+-[A-Za-z]+')]
    [string]$Name,

    [Parameter()]
    [ValidateSet('Script', 'Function', 'Optimization')]
    [string]$Type = 'Script',

    [Parameter()]
    [string]$OutputDir,

    [Parameter()]
    [string]$Description = 'TODO: Add description here.',

    [Parameter()]
    [switch]$RequiresAdmin,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Resolve workspace root
$workspaceRoot = Split-Path -Parent $PSScriptRoot

# Auto-select output directory
if (-not $OutputDir) {
    $OutputDir = switch ($Type) {
        'Script'       { Join-Path $workspaceRoot 'Scripts' }
        'Function'     { Join-Path $workspaceRoot 'Functions' }
        'Optimization' { Join-Path $workspaceRoot 'Optimizations' }
    }
}

$filePath = Join-Path $OutputDir "$Name.ps1"

if ((Test-Path $filePath) -and -not $Force) {
    Write-Error "File already exists: $filePath. Use -Force to overwrite."
}

$date = Get-Date -Format 'yyyy-MM-dd'

# Build template
$adminBlock = if ($RequiresAdmin) {
    @"

`$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not `$isAdmin) {
    Write-Error 'This script requires administrator privileges.'
}

"@
} else { "`n" }

$template = switch ($Type) {
    'Function' {
        @"
<#
.SYNOPSIS
    $Description

.DESCRIPTION
    TODO: Add detailed description.

.PARAMETER InputObject
    TODO: Describe parameter.

.EXAMPLE
    $Name -InputObject `$data
    TODO: Describe example.

.NOTES
    Author: C-Man
    Date:   $date
#>
function $Name {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object]`$InputObject
    )

    begin {
    }

    process {
        # TODO: Implementation
    }

    end {
    }
}
"@
    }
    default {
        @"
<#
.SYNOPSIS
    $Description

.DESCRIPTION
    TODO: Add detailed description.

.PARAMETER Name
    TODO: Describe parameter.

.EXAMPLE
    .\$Name.ps1
    TODO: Describe example.

.NOTES
    Author: C-Man
    Date:   $date$(if ($RequiresAdmin) { "`n    Requires: Run as Administrator" })
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]`$Name
)

`$ErrorActionPreference = 'Stop'
$adminBlock
Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  $Name" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# TODO: Implementation

Write-Host ""
"@
    }
}

# Ensure directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Set-Content -Path $filePath -Value $template -Encoding UTF8
Write-Host "Created: $filePath" -ForegroundColor Green
Write-Host "Type:    $Type" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open $filePath in your editor" -ForegroundColor Gray
Write-Host "  2. Update the help block and parameters" -ForegroundColor Gray
Write-Host "  3. Implement the script logic" -ForegroundColor Gray
Write-Host "  4. Test in Scratch/ before committing" -ForegroundColor Gray
Write-Host ""
