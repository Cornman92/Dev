#Define ASCII Characters    
    $Equals = [Char]61
    $Space = [Char]32
    $SingleQuote = [Char]39
    $DoubleQuote = [Char]34
    $NewLine = "`n"

#Load WMI Classes
    $OperatingSystem = Get-WmiObject -Namespace "root\CIMv2" -Class "Win32_OperatingSystem" -Property * | Select *

#Define Functions
    #Retrieve The Value Of A Registry Path
        Function Get-RegistryValue
            {
                [CmdletBinding(SupportsShouldProcess=$True)]
                Param
                    (
                        [Parameter(Mandatory=$True)]
                        [String]$Path, 
                        
                        [Parameter(Mandatory=$True)]
                        [String]$Name
                    )
                
                If (Test-Path -Path $Path -ErrorAction SilentlyContinue)
                    {
                        Write-Verbose -Message "Now retrieving value `"$($Name)`" from `"$($Path)`""
                        $Result = (Get-ItemProperty -Path $Path -Name $Name | Select -ExpandProperty $Name | Out-String).Trim()
                    }
                Else
                    {
                        $Result = $Null
                    }
                
                Return $Result
            }
    
    #Set The Value Of A Registry Path
        Function Set-RegistryValue
            {
                [CmdletBinding(SupportsShouldProcess=$True)]
                    Param
                        (
                            [Parameter(Mandatory=$True)]
                            [ValidateScript({$_ -like "HK*:*"})]
                            [String]$Path, 
                        
                            [Parameter(Mandatory=$True)]
                            [String]$Name,
                        
                            [Parameter(Mandatory=$True)]
                            $Value,

                            [Parameter(Mandatory=$True)]
                            [ValidateSet("Binary","DWord","ExpandString","MultiString","String","QWord")]
                            [String]$ValueType
                        )
                
                $PSDrive_Name = $Path.Split(":")[0]

                If ($PSDrive_Name -eq "HKCR") {$PSDrive_Root = "HKEY_CLASSES_ROOT"}
                If ($PSDrive_Name -eq "HKCU") {$PSDrive_Root = "HKEY_CURRENT_USER"}
                If ($PSDrive_Name -eq "HKLM") {$PSDrive_Root = "HKEY_LOCAL_MACHINE"}
                If ($PSDrive_Name -eq "HKU") {$PSDrive_Root = "HKEY_USERS"}
                If ($PSDrive_Name -eq "HKCC") {$PSDrive_Root = "HKEY_CURRENT_CONFIG"}
                
                If (!(Get-PSDrive -Name $PSDrive_Name -PSProvider Registry -ErrorAction SilentlyContinue)) {$PSDrive_Create = New-PSDrive -Name $PSDrive_Name -Root $PSDrive_Root -PSProvider Registry}
                
                If (!(Test-Path -Path $Path -ErrorAction SilentlyContinue))
                    {
                        New-Item -Path $Path -Force | Out-Null
                    }

                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $ValueType -Force | Out-Null

                If ($? -eq $True)
                    {
                        Write-Verbose -Message "Set-RegistryValue: `"$($Name)`" of type `"$($ValueType)`" with value of `"$($Value)`" in path `"$($Path)`" was successful"
                    }
                Else
                    {
                        Write-Error -Message "Set-RegistryValue: `"$($Name)`" of type `"$($ValueType)`" with value of `"$($Value)`" in path `"$($Path)`" was unsuccessful"
                    }
            }
<#

.Synopsis
This powershell cmdlet enables AutoLogon the next time the device reboots. Can be configured to only require a logoff. Additionally, a command can executed upon login.

-Domain : Provide the domain of the user to be logged in. Default is the local workstation.
-Username : Provide the username that the system will use to login.
-Password : Provide the password for the username provided. Must be of type [System.Security.SecureString].
-LogonCount : Sets the number of times the system would reboot without asking for credentials. Default is 1.
-ForceAutoLogon : Force auto logon without a restart. A logoff would be sufficient.
-AsynchronousRunOnce : Allows the Windows interface to load while running the command specified in the command parameter.
-Command : Provide the command that will be executed after the device is restarted. Example : $($PSHome)\powershell.exe -ExecutionPolicy Bypass -NoLogo -WindowStyle Maximized -File `"$($Env:Windir)\Temp\MyPowershellScript.ps1`"
-DefaultCommand : Places the default command into the run once registry key, which is just a full screen non terminating powershell console.
-Interactive : Prompts for credentials using (Get-Credential) instead of using the values supplied by the arguments.

.Description
Enables AutoLogon.

.Example
Enable-AutoLogon -Interactive -DefaultCommand -ForceAutoLogon

.Example
Enable-AutoLogon -Username "Administrator" -Password (ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force)

.Example
Enable-AutoLogon -Username "Administrator" -Password (ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force) -LogonCount "3"

.Example
Enable-AutoLogon -Username "Administrator" -Password (ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force) -Command "$($PSHome)\powershell.exe -ExecutionPolicy Unrestricted -NoLogo -WindowStyle Maximized -File `"$($Env:Windir)\Temp\MyPowershellScript.ps1`""

.Example
Enable-AutoLogon -Username "Administrator" -Password (ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force) -AsynchronousRunOnce -Command "$($PSHome)\powershell.exe -ExecutionPolicy Unrestricted -NoLogo -WindowStyle Maximized -File `"$($Env:Windir)\Temp\MyPowershellScript.ps1`""

#>

Function Enable-AutoLogon
    {
        [CmdletBinding()]
            Param
                (
                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=0)]
                    [Alias("DMN")]
                    [String]$Domain = "$($Env:UserDomain)",
                    
                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=1)]
                    [Alias("UN")]
                    [String]$Username = "$($Env:Username)",

                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=2)]
                    [Alias("PW")]
                    [ValidateNotNullOrEmpty()]
                    [System.Security.SecureString]$Password,

                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=3)]
                    [AllowEmptyString()]
                    [Alias("LC")]
                    [UInt32]$LogonCount = "1",

                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=4)]
                    [Alias("FAL")]
                    [Switch]$ForceAutoLogon,
                    
                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=5)]
                    [Alias("ASRO")]
                    [Switch]$AsynchronousRunOnce,
                    
                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=6)]
                    [AllowEmptyString()]
                    [Alias("Script")]
                    [String]$Command = "$($PSHome)\powershell.exe -ExecutionPolicy Unrestricted -NoLogo -NoExit -WindowStyle Maximized",
                    
                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=7)]
                    [Alias("DC")]
                    [Switch]$DefaultCommand,
                    
                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=8)]
                    [Alias("ShowUI")]
                    [Switch]$Interactive    
                )

            Begin
                {
                    $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
                    $RegistryRunOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
                    $RegistryAsynchronousRunOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
                }
    
            Process
                {
                    Try
                        {
                            If ($Interactive.IsPresent)
                                {
                                    $Credentials = (Get-Credential -Message "Please enter the credentials that will be used for AutoLogon" -UserName "$($Domain)\$($Username)").GetNetworkCredential()
                                    $Domain = $Credentials.Domain
                                    $Username = $Credentials.UserName
                                    $Password = $Credentials.SecurePassword
                                }

                            [String]$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

                            Set-RegistryValue -Path $RegistryPath -Name "AutoAdminLogon" -Value "1" -ValueType String
                            Set-RegistryValue -Path $RegistryPath -Name "DefaultUsername" -Value $Username -ValueType String
                            Set-RegistryValue -Path $RegistryPath -Name "DefaultPassword" -Value $UnsecurePassword -ValueType String
                            Set-RegistryValue -Path $RegistryPath -Name "DefaultDomainName" -Value $Domain -ValueType String
                                    
                            If ($PSBoundParameters.ContainsKey("LogonCount"))
                                {
                                    Set-RegistryValue -Path $RegistryPath -Name "AutoLogonCount" -Value $LogonCount -ValueType Dword 
                                }
                            Else
                                {
                                    Set-RegistryValue -Path $RegistryPath -Name "AutoLogonCount" -Value $LogonCount -ValueType Dword
                                }
            
                            If ($PSBoundParameters.ContainsKey("Command") -and ($DefaultCommand.IsPresent -eq $False))
                                {
                                    Set-RegistryValue -Path $RegistryRunOncePath -Name "(Default)" -Value $Command -ValueType String
                                }
                            ElseIf (!$PSBoundParameters.ContainsKey("Command") -and ($DefaultCommand.IsPresent -eq $True))
                                {
                                    Set-RegistryValue -Path $RegistryRunOncePath -Name "(Default)" -Value $Command -ValueType String
                                }
                            Else
                                {
                                    Set-RegistryValue -Path $RegistryRunOncePath -Name "(Default)" -Value "" -ValueType String
                                }
                        
                            If ($ForceAutoLogon.IsPresent)
                                {
                                    Set-RegistryValue -Path $RegistryPath -Name "ForceAutoLogon" -Value "1" -ValueType String
                                }
                            Else
                                {
                                    Set-RegistryValue -Path $RegistryPath -Name "ForceAutoLogon" -Value "0" -ValueType String
                                }
                            
                            If ($AsynchronousRunOnce.IsPresent)
                                {
                                    Set-RegistryValue -Path $RegistryAsynchronousRunOncePath -Name "AsyncRunOnce" -Value "1" -ValueType Dword
                                }
                            Else
                                {
                                    Set-RegistryValue -Path $RegistryAsynchronousRunOncePath -Name "AsyncRunOnce" -Value "0" -ValueType Dword
                                }
                        }
                    Catch
                        {
                            Write-Output -InputObject $Error
                        }
                }
    }

<#
.Synopsis
This powershell cmdlet disables AutoLogon completely.

.Description
Disables AutoLogon.

.Example
Disable-AutoLogon
#>

Function Disable-AutoLogon
    {
        Begin
            {
                $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
                $RegistryRunOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
                $RegistryAsynchronousRunOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
            }
    
        Process
            {
                Try
                    {
                        Set-RegistryValue -Path $RegistryPath -Name "AutoAdminLogon" -Value "0" -ValueType String
                        Set-RegistryValue -Path $RegistryPath -Name "DefaultUsername" -Value "" -ValueType String
                        Set-RegistryValue -Path $RegistryPath -Name "DefaultPassword" -Value "" -ValueType String
                        Set-RegistryValue -Path $RegistryPath -Name "DefaultDomainName" -Value "" -ValueType String
                        Set-RegistryValue -Path $RegistryPath -Name "AutoLogonCount" -Value "" -ValueType Dword
                        Set-RegistryValue -Path $RegistryPath -Name "ForceAutoLogon" -Value "0" -ValueType String
                        Set-RegistryValue -Path $RegistryRunOncePath -Name "(Default)" -Value "" -ValueType String        
                        If ([Version]($OperatingSystem.Version) -lt [Version]"10.0")
                            {
                                Set-RegistryValue -Path $RegistryAsynchronousRunOncePath -Name "AsyncRunOnce" -Value "0" -ValueType Dword
                            }
                        ElseIf ([Version]($OperatingSystem.Version) -ge [Version]"10.0")
                            {
                                Set-RegistryValue -Path $RegistryAsynchronousRunOncePath -Name "AsyncRunOnce" -Value "1" -ValueType Dword
                            }
                    }
                Catch
                    {
                        Write-Output -InputObject $Error
                    }
            }
    }

<#

.Synopsis

This powershell cmdlet allows you to retrieve the current phase of a phased autologon routine.

You could for example get the current phase and run an additional command/script based on the phase value.

If ((Get-Phase) -eq "1") {Enable-AutoLogon -Username "Administrator" -Password (ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force) -AsynchronousRunOnce -Command "$($PSHome)\powershell.exe -ExecutionPolicy Unrestricted -NoLogo -WindowStyle Maximized -File `"$($Env:Windir)\Temp\MyPowershellScript1.ps1`""}

If ((Get-Phase) -eq "2") {Enable-AutoLogon -Username "Administrator" -Password (ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force) -AsynchronousRunOnce -Command "$($PSHome)\powershell.exe -ExecutionPolicy Unrestricted -NoLogo -WindowStyle Maximized -File `"$($Env:Windir)\Temp\MyPowershellScript2.ps1`""}

.Example
Get-Phase

#>

Function Get-Phase
    {
        [CmdletBinding()]
            Param
                (
                )
                    Begin
                        {
                            [String]$Path = "HKLM:\SOFTWARE\Modules\AutoLogon"
                            [String]$Name = "Phase"
                            [String]$Value = "1"
                        }
                    
                    Process
                        {
                            Try
                                {   
                                    If (Get-RegistryValue -Path $Path -Name $Name)
                                        {
                                            $ScriptPhase = Get-RegistryValue -Path $Path -Name $Name
                                        }
                                    Else
                                        {
                                            Write-Warning -Message "`"$($Path)`" not found. Please use the `"Set-Phase`" cmdlet to set the phase first."
                                        }
                            
                                    If ($ScriptPhase) {Return $ScriptPhase}
                                }
                            Catch
                                {
                                    Write-Output -InputObject $Error
                                }
                        }
    }

<#

.Synopsis
This powershell cmdlet allows the phase to be set while still running a script.

.Description
This powershell cmdlet allows the phase to be set while still running a script. Somewhere at the end of a script, set the phase and enable autologon. Once the devices reboots and runs the script, it will conditionally execute the code relative to phase 2 for example. Ultimately, the ability to string together reboots, autologons, and script execution, you will be able to fully prepare a computer. 

.Example
Set-Phase -Phase "2"

#>

Function Set-Phase
    {
        [CmdletBinding()]
            Param
                (
                    [Parameter(Mandatory=$False,ValueFromPipeline=$True,Position=0)]
                    [ValidateNotNullOrEmpty()]
                    [String]$Phase = "1"   
                )
                    Begin
                        {
                            [String]$Path = "HKLM:\SOFTWARE\Modules\AutoLogon"
                            [String]$Name = "Phase"
                        }
                    Process
                        {
                            Try
                                {
                                    Set-RegistryValue -Path $Path -Name $Name -Value $Phase -ValueType String 
                                }
                            Catch
                                {
                                    Write-Error -InputObject $Error
                                }
                        }
    }

<#

.Synopsis
This powershell cmdlet removes phase information from the registry. Useful for cleanup in scripts

.Description
This powershell cmdlet removes phase information from the registry. Useful for cleanup in scripts

.Example
Remove-Phase

#>

Function Remove-Phase
    {
        [CmdletBinding()]
            Param
                (
                )
                    Begin
                        {
                            [String]$Path = "HKLM:\SOFTWARE\Modules\AutoLogon"
                        }

                    Process
                        {
                            Try
                                {
                                    Remove-Item -Path $Path -Recurse -Force       
                                }   
                            Catch
                                {
                                    Write-Output -InputObject $Error
                                }
                    }
    }

#Export Module Functions
    Export-ModuleMember -Function "Enable-AutoLogon", "Disable-AutoLogon", "Get-Phase", "Set-Phase", "Remove-Phase"
