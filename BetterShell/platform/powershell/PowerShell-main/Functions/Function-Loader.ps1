# PowerShell Function and Alias Lazy-Loader
# Discovers all .ps1 files in the Functions directory and creates proxy commands for them.

function Enable-LazyFunctionLoading {
    [CmdletBinding()]
    param(
        [string]$FunctionsPath = (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)
    )

    # A hashtable to keep track of which files have been sourced to avoid duplicate loading
    if (-not $script:SourcedFunctionFiles) {
        $script:SourcedFunctionFiles = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new()
    }

    # Discover all function files, excluding system directories and handling access denied errors
    $functionFiles = Get-ChildItem -Path $FunctionsPath -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable DirErrors | 
        Where-Object { $_.FullName -notmatch '\\Windows\\|\\Program Files\\|\\Program Files \(x86\).*\\Windows\\|\\ProgramData\\|\\System Volume Information\\|\\Windows.old\\|\\$Recycle.Bin\\' }
    
    # Log any access denied errors
    foreach ($errorRecord in $DirErrors) {
        if ($errorRecord.Exception -is [System.UnauthorizedAccessException]) {
            Write-Verbose "Access denied to directory: $($errorRecord.TargetObject)"
        }
    }

    foreach ($file in $functionFiles) {
        # The command name is derived from the filename (e.g., Get-SystemInfo.ps1 -> Get-SystemInfo)
        $commandName = $file.BaseName

        # Skip if a command with this name already exists (e.g., from a module or built-in)
        if (Get-Command $commandName -ErrorAction SilentlyContinue) {
            Write-Verbose "Skipping proxy for '$commandName' as a command with this name already exists."
            continue
        }

        # Define the script block for the proxy function.
        # This uses a scriptblock with a using scope to create a closure, capturing the file path.
        $proxyScriptBlock = [scriptblock]::Create(@"
            param(
                [Parameter(ValueFromRemainingArguments)]
                `$remainingArgs
            )

            # Source the file if it hasn't been already
            if (`$script:SourcedFunctionFiles.TryAdd("$($file.FullName)", `$true)) {
                . "$($file.FullName)"
                Write-Verbose "Lazy-loaded functions from: $($file.Name)"
            }

            # Execute the real command with the original arguments and splatting
            & "$commandName" @remainingArgs
"@)
        
        # Create the proxy function in the global scope
        Set-Item -Path "function:global:$commandName" -Value $proxyScriptBlock -Force
        Write-Verbose "Created lazy-loader for '$commandName'."
    }
}

# Execute the loader
Enable-LazyFunctionLoading
