Set-StrictMode -Version Latest

Import-Module Deployment.Core -ErrorAction Stop

function New-AutounattendXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $RunContext,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName = 'PC-*',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $TimeZone = 'Eastern Standard Time',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $RegisteredOwner = 'Better11',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $RegisteredOrganization = 'Better11',

        [Parameter()]
        [string] $ProductKey,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $UILanguage = 'en-US',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $InputLocale = 'en-US',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $SystemLocale = 'en-US',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $UserLocale = 'en-US',

        [Parameter()]
        [string] $LocalAdminName = 'localadmin',

        [Parameter()]
        [string] $LocalAdminPassword,

        [Parameter()]
        [switch] $EnableAutoLogon,

        [Parameter()]
        [int] $AutoLogonCount = 1,

        [Parameter()]
        [ValidateSet(1,2,3)]
        [int] $ProtectYourPC = 1,

        [Parameter()]
        [switch] $HideOobeEula,

        [Parameter()]
        [switch] $HideOnlineAccountScreens,

        [Parameter()]
        [switch] $HideWirelessSetupInOobe
    )

    $RunContext | Write-DeployEvent -Level 'Info' -Message "Generating autounattend.xml at '$OutputPath'."

    $arch = if ([Environment]::Is64BitOperatingSystem) { 'amd64' } else { 'x86' }
    $hideEula   = $HideOobeEula.IsPresent
    $hideOnline = $HideOnlineAccountScreens.IsPresent
    $hideWifi   = $HideWirelessSetupInOobe.IsPresent
    $autoLogonEnabled = $EnableAutoLogon.IsPresent -and $LocalAdminPassword

    $productKeyElement = ''
    if ($ProductKey) {
        $productKeyElement = @"
      <ProductKey>$ProductKey</ProductKey>

"@
    }

    $autoLogonBlock = ''
    if ($autoLogonEnabled) {
        $autoLogonBlock = @"
    <AutoLogon>
      <Username>$LocalAdminName</Username>
      <Password>
        <Value>$LocalAdminPassword</Value>
        <PlainText>true</PlainText>
      </Password>
      <Enabled>true</Enabled>
      <LogonCount>$AutoLogonCount</LogonCount>
    </AutoLogon>

"@
    }

    $oobeHideFlags = @()
    if ($hideEula)   { $oobeHideFlags += '      <HideEULAPage>true</HideEULAPage>' }
    if ($hideOnline) { 
        $oobeHideFlags += '      <HideOnlineAccountScreens>true</HideOnlineAccountScreens>'
        $oobeHideFlags += '      <HideLocalAccountScreen>true</HideLocalAccountScreen>'
    }
    if ($hideWifi)   { $oobeHideFlags += '      <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>' }

    $oobeHideText = if ($oobeHideFlags.Count -gt 0) { ($oobeHideFlags -join "`r`n") } else { '' }

    $xmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="$arch"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <ComputerName>$ComputerName</ComputerName>
      <RegisteredOwner>$RegisteredOwner</RegisteredOwner>
      <RegisteredOrganization>$RegisteredOrganization</RegisteredOrganization>
      <TimeZone>$TimeZone</TimeZone>$productKeyElement
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core"
               processorArchitecture="$arch"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>$InputLocale</InputLocale>
      <SystemLocale>$SystemLocale</SystemLocale>
      <UILanguage>$UILanguage</UILanguage>
      <UserLocale>$UserLocale</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="$arch"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <OOBE>
$oobeHideText
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>$ProtectYourPC</ProtectYourPC>
      </OOBE>
      <UserAccounts>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Name>$LocalAdminName</Name>
            <Group>Administrators</Group>
            <Password>
              <Value>$LocalAdminPassword</Value>
              <PlainText>true</PlainText>
            </Password>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
$autoLogonBlock
    </component>
  </settings>
</unattend>
"@

    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }

    Set-Content -Path $OutputPath -Value $xmlContent -Encoding UTF8

    $RunContext | Write-DeployEvent -Level 'Info' -Message "autounattend.xml written to '$OutputPath'."
}

function Start-AutounattendWizard {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $DefaultOutputDirectory = '.'
    )

    if (-not (Test-DeployAdmin)) {
        throw "Autounattend wizard must be run as Administrator."
    }

    $ctx = New-DeployRunContext

    Clear-Host
    Write-Host '=============================================' -ForegroundColor Cyan
    Write-Host '   Better11 - Autounattend.xml Wizard         ' -ForegroundColor Cyan
    Write-Host '=============================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host "Run Id: $($ctx.RunId)"
    Write-Host ''

    $outDir = Read-Host "Output directory for autounattend.xml [`$Default: $DefaultOutputDirectory]"
    if ([string]::IsNullOrWhiteSpace($outDir)) {
        $outDir = $DefaultOutputDirectory
    }

    $outDir = (Resolve-Path $outDir).ProviderPath
    $outPath = Join-Path $outDir 'autounattend.xml'

    Write-Host ''

    $computerName = Read-Host "Computer name (use * for random) [`$Default: PC-*]"
    if ([string]::IsNullOrWhiteSpace($computerName)) {
        $computerName = 'PC-*'
    }

    $owner = Read-Host "Registered owner [`$Default: Better11]"
    if ([string]::IsNullOrWhiteSpace($owner)) { $owner = 'Better11' }

    $org = Read-Host "Registered organization [`$Default: Better11]"
    if ([string]::IsNullOrWhiteSpace($org)) { $org = 'Better11' }

    $tz = Read-Host "Time zone (Windows ID) [`$Default: Eastern Standard Time]"
    if ([string]::IsNullOrWhiteSpace($tz)) { $tz = 'Eastern Standard Time' }

    $productKey = Read-Host "Product key (optional, blank to skip)"

    Write-Host ''

    $lang = Read-Host "UI language (en-US, fr-FR, etc.) [`$Default: en-US]"
    if ([string]::IsNullOrWhiteSpace($lang)) { $lang = 'en-US' }

    $localAdmin = Read-Host "Local admin username [`$Default: localadmin]"
    if ([string]::IsNullOrWhiteSpace($localAdmin)) { $localAdmin = 'localadmin' }

    $localPass = Read-Host "Local admin password (stored in plaintext in unattend.xml)" -AsSecureString
    $passPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($localPass)
    )

    Write-Host ''

    $autoLogonAns = Read-Host "Enable one-time auto-logon for local admin? (y/N)"
    $enableAutoLogon = $false
    if ($autoLogonAns -match '^(y|yes)$') { $enableAutoLogon = $true }

    $protectStr = Read-Host "ProtectYourPC (1=Recommended updates, 2=Not recommended, 3=No updates) [`$Default: 1]"
    $protectVal = 1
    if ([int]::TryParse($protectStr, [ref]([int]0))) {
        $p = [int]$protectStr
        if ($p -ge 1 -and $p -le 3) { $protectVal = $p }
    }

    Write-Host ''

    $hideEula   = Read-Host "Hide OOBE EULA page? (y/N)"
    $hideOnline = Read-Host "Hide Microsoft account / online account screens? (y/N)"
    $hideWifi   = Read-Host "Hide wireless setup during OOBE? (y/N)"

    Clear-Host

    Write-Host 'Autounattend configuration summary:' -ForegroundColor Green
    Write-Host "  Output path           : $outPath"
    Write-Host "  Computer name         : $computerName"
    Write-Host "  Owner / Org           : $owner / $org"
    Write-Host "  Time zone             : $tz"
    Write-Host "  Product key           : $productKey"
    Write-Host "  UI language           : $lang"
    Write-Host "  Local admin           : $localAdmin"
    Write-Host "  Auto-logon            : $enableAutoLogon"
    Write-Host "  ProtectYourPC         : $protectVal"
    Write-Host "  Hide EULA             : $hideEula"
    Write-Host "  Hide online accounts  : $hideOnline"
    Write-Host "  Hide wireless in OOBE : $hideWifi"
    Write-Host ''

    $confirm = Read-Host "Generate autounattend.xml with these settings? Type YES to confirm"

    if ($confirm -ne 'YES') {
        Write-Host 'Operation cancelled.' -ForegroundColor Yellow
        return
    }

    New-AutounattendXml -RunContext $ctx `
        -OutputPath $outPath `
        -ComputerName $computerName `
        -TimeZone $tz `
        -RegisteredOwner $owner `
        -RegisteredOrganization $org `
        -ProductKey $productKey `
        -UILanguage $lang `
        -InputLocale $lang `
        -SystemLocale $lang `
        -UserLocale $lang `
        -LocalAdminName $localAdmin `
        -LocalAdminPassword $passPlain `
        -EnableAutoLogon:($enableAutoLogon) `
        -ProtectYourPC $protectVal `
        -HideOobeEula:($hideEula -match '^(y|yes)$') `
        -HideOnlineAccountScreens:($hideOnline -match '^(y|yes)$') `
        -HideWirelessSetupInOobe:($hideWifi -match '^(y|yes)$')

    Write-Host ''
    Write-Host "autounattend.xml generated at: $outPath" -ForegroundColor Green
}

