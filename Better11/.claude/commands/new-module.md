Scaffold a new Better11 PowerShell module. The user will provide the module name as $ARGUMENTS.

Create the following structure under `PowerShell/Modules/B11.{Name}/`:

1. `B11.{Name}.psd1` — Module manifest with:
   - ModuleVersion 1.0.0
   - Author 'C-Man'
   - PowerShellVersion '7.0'
   - FunctionsToExport listing all public functions
   
2. `B11.{Name}.psm1` — Root module that dot-sources Public/*.ps1 and Private/*.ps1

3. `Public/` directory with initial function files following:
   - [CmdletBinding()] on every function
   - [OutputType()] attribute
   - SupportsShouldProcess on state-changing functions
   - Verb-B11{Name} naming convention
   - Full comment-based help (.SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE)
   - Export-ModuleMember at bottom
   
4. `Private/` directory (empty, for internal helper functions)

5. `Tests/B11.{Name}.Tests.ps1` — Pester 5.x test file with:
   - BeforeAll importing the module
   - Context blocks per function
   - It blocks covering success, failure, and edge cases
   - 100% coverage target

Follow all conventions from CLAUDE.md and CLAUDE-CODE.md.
