# This is a locally sourced Imports file for local development.
# It can be imported by the psm1 in local development to add script level variables.
# It will merged in the build process. This is for local development only.

# region script variables
$script:resourcePath = "$PSScriptRoot\Resources"


<#
.EXTERNALHELP Catesta-help.xml
#>
function New-ModuleProject {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            HelpMessage = 'File path where PowerShell Module project will be created')]
        [string]
        $DestinationPath,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Plaster choices inside hashtable')]
        [hashtable]
        $ModuleParameters,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Suppresses the display of the Plaster logo')]
        [switch]$NoLogo,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Plaster template object')]
        [switch]$PassThru,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Skip confirmation')]
        [switch]$Force
    )

    Begin {

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }

        Write-Verbose -Message ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
        Write-Verbose -Message ('ParameterSetName: {0}' -f $PSCmdlet.ParameterSetName)
    } #begin
    Process {

        Write-Verbose -Message 'Importing Plaster...'
        try {
            Import-Module -Name Plaster -ErrorAction Stop
            Write-Verbose 'Plaster Imported.'
        }
        catch {
            throw $_
        }

        $path = 'Module'
        Write-Verbose -Message ('Template Path: {0}\{1}' -f $script:resourcePath, $path)

        if ($ModuleParameters) {

            # process overrides for ModuleParameters that do not permit customization
            $ModuleParameters['VAULT'] = 'NOTVAULT'
            $ModuleParameters['ErrorAction'] = 'Stop'
            $ModuleParameters['TemplatePath'] = '{0}\{1}' -f $script:resourcePath, $path
            $ModuleParameters['DestinationPath'] = $DestinationPath

            if ($PassThru -eq $true) {
                $ModuleParameters['PassThru'] = $true
            }
            $invokePlasterSplat = $ModuleParameters

            $shouldProcessMessage = 'Scaffolding PowerShell module project with provided custom module parameters: {0}' -f $($invokePlasterSplat | Out-String)

        } #if_ModuleParameters
        else {
            $invokePlasterSplat = @{
                TemplatePath    = '{0}\{1}' -f $script:resourcePath, $path
                DestinationPath = $DestinationPath
                VAULT           = 'NOTVAULT'
                PassThru        = $PassThru
                NoLogo          = $NoLogo
                ErrorAction     = 'Stop'
            }

            $shouldProcessMessage = 'Scaffolding PowerShell module project with: {0}' -f $($invokePlasterSplat | Out-String)

        } #else_ModuleParameters

        if ($Force -or $PSCmdlet.ShouldProcess($DestinationPath, $shouldProcessMessage)) {
            Write-Verbose -Message ('[{0}] Reached command' -f $MyInvocation.MyCommand)

            # Save current value of $ConfirmPreference
            $originalConfirmPreference = $ConfirmPreference
            # Set $ConfirmPreference to 'NONE'
            $ConfirmPreference = 'None'

            Write-Verbose -Message 'Deploying template...'
            $result = Invoke-Plaster @invokePlasterSplat
            Write-Verbose -Message 'Template Deployed.'

            # Set $ConfirmPreference back to original value
            $ConfirmPreference = $originalConfirmPreference
        } #if_Should

    } #process
    End {
        if ($PassThru -or $ModuleParameters.PassThru -eq $true) {
            return $result
        }
    } #end
} #New-ModuleProject



<#
.EXTERNALHELP Catesta-help.xml
#>
function New-VaultProject {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = 'File path where PowerShell SecretManagement vault project will be created')]
        [string]
        $DestinationPath,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Plaster choices inside hashtable')]
        [hashtable]
        $VaultParameters,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Suppresses the display of the Plaster logo')]
        [switch]$NoLogo,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Plaster template object')]
        [switch]$PassThru,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Skip confirmation')]
        [switch]$Force
    )
    Begin {

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }

        Write-Verbose -Message ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
        Write-Verbose -Message ('ParameterSetName: {0}' -f $PSCmdlet.ParameterSetName)
    } #begin
    Process {

        Write-Verbose -Message 'Importing Plaster...'
        try {
            Import-Module -Name Plaster -ErrorAction Stop
            Write-Verbose 'Plaster Imported.'
        }
        catch {
            throw $_
        }

        $path = 'Vault'
        Write-Verbose -Message ('Template Path: {0}\{1}' -f $script:resourcePath, $path)

        if ($VaultParameters) {

            # process overrides for VaultParameters that do not permit customization
            $VaultParameters['VAULT'] = 'VAULT'
            $VaultParameters['ErrorAction'] = 'Stop'
            $VaultParameters['TemplatePath'] = '{0}\{1}' -f $script:resourcePath, $path
            $VaultParameters['DestinationPath'] = $DestinationPath

            if ($PassThru -eq $true) {
                $VaultParameters['PassThru'] = $true
            }
            $invokePlasterSplat = $VaultParameters

            $shouldProcessMessage = 'Scaffolding PowerShell vault project with provided custom vault parameters: {0}' -f $($invokePlasterSplat | Out-String)

        } #if_$VaultParameters
        else {
            $invokePlasterSplat = @{
                TemplatePath    = '{0}\{1}' -f $script:resourcePath, $path
                DestinationPath = $DestinationPath
                VAULT           = 'VAULT'
                PassThru        = $PassThru
                NoLogo          = $NoLogo
                ErrorAction     = 'Stop'
            }
            # if ($NoLogo -eq $true) {
            #     $invokePlasterSplat['NoLogo'] = $NoLogo
            # }

            $shouldProcessMessage = 'Scaffolding PowerShell vault project with: {0}' -f $($invokePlasterSplat | Out-String)

        } #else_$VaultParameters

        if ($Force -or $PSCmdlet.ShouldProcess($DestinationPath, $shouldProcessMessage)) {
            Write-Verbose -Message ('[{0}] Reached command' -f $MyInvocation.MyCommand)

            # Save current value of $ConfirmPreference
            $originalConfirmPreference = $ConfirmPreference
            # Set $ConfirmPreference to 'NONE'
            $ConfirmPreference = 'None'

            Write-Verbose -Message 'Deploying template...'
            $result = Invoke-Plaster @invokePlasterSplat
            Write-Verbose -Message 'Template Deployed.'

            # Set $ConfirmPreference back to original value
            $ConfirmPreference = $originalConfirmPreference
        } #if_Should

    } #process
    End {
        if ($PassThru -or $VaultParameters.PassThru -eq $true) {
            return $result
        }
    } #end
} #New-VaultProject




