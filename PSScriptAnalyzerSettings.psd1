@{
    Severity = @('Error', 'Warning', 'Information')

    IncludeDefaultRules = $true

    Rules = @{
        # Enforce approved verbs
        PSUseApprovedVerbs = @{
            Enable = $true
        }

        # Enforce consistent casing
        PSProvideCommentHelp = @{
            Enable            = $true
            ExportedOnly      = $true
            BlockComment      = $true
            VSCodeSnippetCorrection = $false
            Placement         = 'begin'
        }

        # Align with PascalCase function names
        PSUseConsistentWhitespace = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator                  = $true
            CheckParameter                  = $false
        }

        PSUseConsistentIndentation = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }

        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        # Avoid aliases in scripts
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }

        # Avoid Write-Host in functions
        PSAvoidUsingWriteHost = @{
            Enable = $true
        }

        # Use ShouldProcess for state-changing functions
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }

        # Require output type declaration
        PSUseOutputTypeCorrectly = @{
            Enable = $true
        }
    }

    ExcludeRules = @(
        # Allow positional parameters in scripts (not modules)
        'PSAvoidUsingPositionalParameters'
    )
}
