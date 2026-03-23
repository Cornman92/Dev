<#
.SYNOPSIS
    Gets the access control entries for a file or directory.
.DESCRIPTION
    This function retrieves the access control list (ACL) for a specified file or directory
    and returns the access control entries in a user-friendly format.
.PARAMETER Path
    The path to the file or directory for which to get the access control entries.
.PARAMETER Recurse
    If specified, retrieves access control entries for all child items as well.
.PARAMETER IncludeInherited
    If specified, includes inherited access rules in the results.
    By default, only explicit access rules are returned.
.PARAMETER AsHashTable
    If specified, returns the results as a hashtable with identity references as keys.
.OUTPUTS
    System.Management.Automation.PSCustomObject or System.Collections.Hashtable
    An object or hashtable containing the access control entries.
.EXAMPLE
    Get-FileSystemAccess -Path 'C:\Temp\example.txt'
    
    Gets the access control entries for the specified file.
.EXAMPLE
    Get-FileSystemAccess -Path 'C:\Data' -Recurse -IncludeInherited
    
    Gets all access control entries for the specified directory and its subdirectories,
    including inherited permissions.
.NOTES
    Author: C-Man
    Date:   $(Get-Date -Format 'yyyy-MM-dd')
#>
[CmdletBinding()]
[OutputType([System.Management.Automation.PSCustomObject], [System.Collections.Hashtable])]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('FullName', 'PSPath')]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path,
    
    [Parameter()]
    [switch]$Recurse,
    
    [Parameter()]
    [switch]$IncludeInherited,
    
    [Parameter()]
    [switch]$AsHashTable
)

begin {
    # Define the properties we want to include in the output
    $properties = @(
        'Path',
        'Identity',
        'AccessControlType',
        'FileSystemRights',
        'InheritanceFlags',
        'PropagationFlags',
        'IsInherited',
        'InheritedFrom'
    )
    
    # Initialize results collection
    $results = [System.Collections.Generic.List[PSObject]]::new()
}

process {
    foreach ($itemPath in $Path) {
        try {
            # Resolve the path to handle relative paths and wildcards
            $resolvedPaths = Resolve-Path -Path $itemPath -ErrorAction Stop | Select-Object -ExpandProperty Path
            
            foreach ($resolvedPath in $resolvedPaths) {
                # Check if the path exists
                if (-not (Test-Path -Path $resolvedPath -ErrorAction Stop)) {
                    Write-Error "Path not found: $resolvedPath" -ErrorAction Continue
                    continue
                }
                
                # Get the item to determine if it's a directory or file
                $item = Get-Item -Path $resolvedPath -Force -ErrorAction Stop
                
                # Process the item
                ProcessItem -Item $item
                
                # Process child items if Recurse is specified and the item is a directory
                if ($Recurse -and ($item.PSIsContainer -or $item -is [System.IO.DirectoryInfo])) {
                    $childItems = Get-ChildItem -Path $resolvedPath -Force -ErrorAction SilentlyContinue
                    foreach ($childItem in $childItems) {
                        ProcessItem -Item $childItem
                    }
                }
            }
        }
        catch {
            Write-Error "Error processing path '$itemPath': $_" -ErrorAction Continue
        }
    }
}

end {
    # Return the results in the requested format
    if ($AsHashTable) {
        $hashTable = @{}
        $results | ForEach-Object {
            $identity = $_.Identity
            if (-not $hashTable.ContainsKey($identity)) {
                $hashTable[$identity] = [System.Collections.Generic.List[PSObject]]::new()
            }
            $hashTable[$identity].Add($_)
        }
        return $hashTable
    }
    
    return $results
}

<#
.SYNOPSIS
    Processes a file system item and extracts its access control entries.
.DESCRIPTION
    This helper function processes a file system item, retrieves its access control list,
    and adds the entries to the results collection.
.PARAMETER Item
    The file system item to process.
#>
function ProcessItem {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Item
    )
    
    try {
        # Get the access control list
        $acl = Get-Acl -Path $Item.FullName -ErrorAction Stop
        
        # Process each access rule
        foreach ($accessRule in $acl.Access) {
            # Skip inherited rules if not requested
            if (-not $IncludeInherited -and $accessRule.IsInherited) {
                continue
            }
            
            # Determine where the permission is inherited from
            $inheritedFrom = $null
            if ($accessRule.IsInherited) {
                $parentPath = Split-Path -Path $Item.FullName -Parent
                $inheritedFrom = $parentPath
            }
            
            # Create a custom object with the access rule properties
            $result = [PSCustomObject]@{
                PSTypeName      = 'FileSystem.AccessRule'
                Path            = $Item.FullName
                ItemType        = if ($Item.PSIsContainer) { 'Directory' } else { 'File' }
                Identity        = $accessRule.IdentityReference.Value
                AccessControlType = $accessRule.AccessControlType
                FileSystemRights = $accessRule.FileSystemRights
                InheritanceFlags = $accessRule.InheritanceFlags
                PropagationFlags = $accessRule.PropagationFlags
                IsInherited     = $accessRule.IsInherited
                InheritedFrom   = $inheritedFrom
                AccessRule      = $accessRule
            }
            
            # Add the result to the collection
            $results.Add($result)
        }
    }
    catch {
        Write-Error "Error processing item '$($Item.FullName)': $_" -ErrorAction Continue
    }
}

# Export the function
Export-ModuleMember -Function Get-FileSystemAccess
