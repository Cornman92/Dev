[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    $module = "dbatools"
)
# Which process should we be looking for?
if ($psedition -eq 'Core') {
    $process = "pwsh"
} else {
    $process = "powershell"
}
if (($PSVersionTable.PSVersion.Major -le 5) -or ($PSVersionTable.PSVersion.Major -gt 6 -and $PSVersionTable.OS -contains "Windows")) {
    $isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $ise = Get-Process powershell_ise -ErrorAction SilentlyContinue
    if ($ise) {
        return "PowerShell ISE found in use. Please close this program before using this script."
    }
} else {
    $isElevated = $null;
    $ise = $null;
}
$installedVersion = Get-InstalledModule $module -AllVersions | Select-Object Version, InstalledLocation
Write-Output "The currently installed version(s) of $module is/are: "
$installedVersion.Version

$results =
foreach ($v in $installedVersion) {
    if ($v.InstalledLocation -match "C:\\Users") {
        Add-Member -Force -InputObject $v -MemberType NoteProperty -Name IsUserScope -value $true
    } else {
        if (-not $isElevated) {
            Write-Output "$module version $v.Version cannot be removed without elevated session."
        }
        Add-Member -Force -InputObject $v -MemberType NoteProperty -Name IsUserScope -value $false
    }
    $v
}

$newestVersion = Find-Module $module | Select-Object Version
Write-Output "`nThe latest version of $module in the PSGallery is: $($newestVersion.Version)"
$olderVersions = @( )
if ($installedVersion.Count -gt 1) {
    $olderVersions = @($installedVersion | Where-Object { [version]$_.Version -lt [version]$newestVersion.Version })
}

if ( ($olderVersions.Count -gt 0) -and $newestVersion.Version -in $installedVersion.Version ) {
    Write-Output "Latest version of $module found on $env:COMPUTERNAME."
    Write-Output "Older versions of $module also found. These will be uninstalled now."
    if ($isElevated) {
        $processes = Get-Process $process -IncludeUserName -ErrorAction SilentlyContinue | Where-Object Id -NE $pid
    } else {
        $processes = Get-Process $process -ErrorAction SilentlyContinue | Where-Object Id -NE $PID
    }
    if ($processes.Count -gt 0) {
        if ($Pscmdlet.ShouldProcess("$env:COMPUTERNAME", "Killing $($processes.Count) processes of powershell running")) {
            Write-Output "Death to the following process(es): $(($processes.Id) -join ",")"
            $processes | Stop-Process -ErrorVariable dangit -ErrorAction SilentlyContinue -Force
            if ($dangit) {
                Write-Warning "Not able to kill following processes: $((Get-Process $process | Where-Object Id -NE $pid).Id -join ",")"
            }
        }
    }
    if ($Pscmdlet.ShouldProcess("$env:COMPUTERNAME", "Removing old versions of $module.")) {
        foreach ($v in $olderVersions.Version) {
            Uninstall-Module $module -RequiredVersion $v -ErrorVariable dangit -ErrorAction SilentlyContinue -Force
            if ($dangit) {
                if ($dangit.Exception -like "*Administrator rights*") {
                    Write-Warning "Elevated session is required to uninstall $module version: $v"
                } else {
                    Write-Warning "Unable to remove $module version [$v] due to: `n`t$($dangit.Exception)"
                }
            }
        }
    }
    Write-Output "The End"
} elseif ( ($olderVersions.Count -gt 0) -and $newestVersion.Version -notin $installedVersion.Version ) {
    Write-Output "Update of $module is available"
    Write-Output "Older versions of $module found. These will be uninstalled now."
    if ($isElevated) {
        $processes = Get-Process $process -ErrorAction SilentlyContinue -IncludeUserName | Where-Object Id -NE $pid
    } else {
        $processes = Get-Process $process -ErrorAction SilentlyContinue | Where-Object Id -NE $PID
    }
    if ($processes.Count -gt 0) {
        if ($Pscmdlet.ShouldProcess("$env:COMPUTERNAME", "Killing $($processes.Count) processes of powershell running")) {
            Write-Output "Death to the following process(es): $(($processes.Id) -join ",")"
            $processes | Stop-Process -ErrorVariable dangit -ErrorAction SilentlyContinue -Force
            if ($dangit) {
                Write-Warning "Not able to kill following processes: $((Get-Process $process | Where-Object Id -NE $pid).Id -join ",")"
            }
        }
    }
    if ($Pscmdlet.ShouldProcess("$env:COMPUTERNAME", "Removing old versions of $module.")) {
        foreach ($v in $olderVersions.Version) {
            Uninstall-Module $module -RequiredVersion $v -ErrorVariable dangit -ErrorAction SilentlyContinue -Force
            if ($dangit) {
                if ($dangit.Exception -like "*Administrator rights*") {
                    Write-Warning "Elevated session is required to uninstall $module version: $v"
                } else {
                    Write-Warning "Unable to remove $module version [$v] due to: `n`t$($dangit.Exception)"
                }
            }
        }
    }
    Write-Output "Continuing to install latest release of $module"
    Install-Module $module -Force
    Write-Output "The End"
} else {
    Write-Output "No update/actions required."
}

# SIG # Begin signature block
# MIIt2wYJKoZIhvcNAQcCoIItzDCCLcgCAQMxDTALBglghkgBZQMEAgEwewYKKwYB
# BAGCNwIBBKBtBGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBbC7m38uJKN0Fh
# yce8/lpvD8KrpB4HRQCSsGB5ShHRlaCCFdswggbXMIIEv6ADAgECAhMzAAVSjpHf
# 5qC/N5S7AAAABVKOMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDIwHhcNMjUxMTE4MDcxMjIyWhcNMjUxMTIx
# MDcxMjIyWjBXMQswCQYDVQQGEwJVUzERMA8GA1UECBMIVmlyZ2luaWExDzANBgNV
# BAcTBlZpZW5uYTERMA8GA1UEChMIZGJhdG9vbHMxETAPBgNVBAMTCGRiYXRvb2xz
# MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEArXOa2W/nDIb0WvI3zL2i
# rf2o5zIyG+7l6tlk1zyL+N/BeO3G0CQ8ytBFkLBZClDn3XsKnZ3H/tcTsh1jytiN
# KXbaD7qGZJBymV1bCwpbHg1bhLCT+ZNJXuiISgFFtqX6kHX0C3p8g9dIn0YNxS/f
# rRUMCJbwHx2nE1ddQvxClbfEopEW9VuO71D7ye0pMdn0Y+9XuaFY4otGlsKpS0xK
# NdjSjYa8SOBMVgmhQ/JWyGb7GfGkyLslQONvs0+XmD4og3Be5eJmlT3dFYkg17b+
# Yj/SEEi/jitx7i9ADK5UO5fZ4Sa7h/7O4LVRDOwghCGy+wWXtc51zVLJrFBOXc6u
# m2Slga/i25HSMMQ2w06swKV17jupouRhpuloLUublyw57GEgIffI5y4EVULmfDdJ
# s29nqNbREFT4nRgLgfV2HGnDedfGkOQouTVEfWPKC97rEiklqFXfv4N//DxFlbG4
# 0l9OMXdCTqzC5zdr6/fsAGyo2Qvdxf3xlD4h2Ixyr5UlAgMBAAGjggIXMIICEzAM
# BgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA6BgNVHSUEMzAxBgorBgEEAYI3
# YQEABggrBgEFBQcDAwYZKwYBBAGCN2H5+cEspPS4DoOuxLIcm56wGDAdBgNVHQ4E
# FgQUssC0qEWAORSvDjXuLz8v7Dam0U8wHwYDVR0jBBgwFoAUZZ9RzoVofy+KRYiq
# 3acxux4NAF4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmllZCUyMENTJTIw
# RU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQGCCsGAQUFBzAC
# hlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29m
# dCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIwMDIuY3J0MC0GCCsG
# AQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29jc3AwZgYDVR0g
# BF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMAgGBmeBDAEE
# ATANBgkqhkiG9w0BAQwFAAOCAgEAtS7vrfkEyaNonuEznmAtpTeffcrHOgm/3s/Q
# sl6ApGDNcbtS8xkO5gBk1HIXwfBpsIOgp+MOnmXY2brzLOnNTXSgdVIF8R4JNhfv
# rlEPdtpYTgHsggi+4jEjNTY7KrDSk+kDwcYZ3hg2nASFx0vjOG8t/VMCva6+WQLz
# PxMRlgSN3UYbCoZiczrpbOldAS2rixNCjzWWEPPA+ScxoVWNxnRR1XPft61VPrG5
# D+mm0OQhG/gJZLRwsRa/eZKWj99pSfqWa6KjkTu8J5n5xxisHNgr0cSCd9iS2hqP
# XugvvHW4QI/I8v2G46csn29HfNzdSAmYRb1sXD9ZNzMga71c/4ENplDoacJOMEHd
# G0Dmn0BNPxydXxUWz/kHxPeL+MAaE8zH2iM4MTdP6SZzfSOMqNpTbuV7of5Or9pL
# ivAXZi3FGhC/CDug2mWPE39/ce9BFeG8It76K2IY/fRwMA5PqWTBdNKI3VAyzT16
# Ln7yMmu+C/tF243B4bstBfCVH82uxO5jrC7ghzZPjS9WHtoFALIQpNacrhw6vjXn
# C/iGi0RBBgalHcm1jRlZXnj77l9nGxSKUMshtB3qLv6DopsdRibRYC9qvurDOgUZ
# ai6BeMy9WTmNJmwO16C7LZTP0M8rv4aMhZmnRt8lW1bGW+WzvX3mDCoeJtmx7F1w
# qfSkuRowggdaMIIFQqADAgECAhMzAAAABft6XDITYd9dAAAAAAAFMA0GCSqGSIb3
# DQEBDAUAMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBDb2RlIFNpZ25p
# bmcgUENBIDIwMjEwHhcNMjEwNDEzMTczMTUzWhcNMjYwNDEzMTczMTUzWjBaMQsw
# CQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSswKQYD
# VQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDAyMIICIjANBgkq
# hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0hqZfD8ykKTA6CDbWvshmBpDoBf7Lv13
# 2RVuSqVwQO3aALLkuRnnTIoRmMGo0fIMQrtwR6UHB06xdqOkAfqB6exubXTHu44+
# duHUCdE4ngjELBQyluMuSOnHaEdveIbt31OhMEX/4nQkph4+Ah0eR4H2sTRrVKmK
# rlOoQlhia73Qg2dHoitcX1uT1vW3Knpt9Mt76H7ZHbLNspMZLkWBabKMl6BdaWZX
# YpPGdS+qY80gDaNCvFq0d10UMu7xHesIqXpTDT3Q3AeOxSylSTc/74P3og9j3Oue
# mEFauFzL55t1MvpadEhQmD8uFMxFv/iZOjwvcdY1zhanVLLyplz13/NzSoU3QjhP
# dqAGhRIwh/YDzo3jCdVJgWQRrW83P3qWFFkxNiME2iO4IuYgj7RwseGwv7I9cxOy
# aHihKMdT9NeoSjpSNzVnKKGcYMtOdMtKFqoV7Cim2m84GmIYZTBorR/Po9iwlasT
# YKFpGZqdWKyYnJO2FV8oMmWkIK1iagLLgEt6ZaR0rk/1jUYssyTiRqWr84Qs3XL/
# V5KUBEtUEQfQ/4RtnI09uFFUIGJZV9mD/xOUksWodGrCQSem6Hy261xMJAHqTqMu
# DKgwi8xk/mflr7yhXPL73SOULmu1Aqu4I7Gpe6QwNW2TtQBxM3vtSTmdPW6rK5y0
# gED51RjsyK0CAwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQBgkrBgEEAYI3
# FQEEAwIBADAdBgNVHQ4EFgQUZZ9RzoVofy+KRYiq3acxux4NAF4wVAYDVR0gBE0w
# SzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3FAIEDB4KAFMA
# dQBiAEMAQTASBgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaAFNlBKbAPD2Ns
# 72nX9c0pnqRIajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBD
# b2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEFBQcBAQSBoTCB
# njBtBggrBgEFBQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# ZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUyMFNpZ25pbmcl
# MjBQQ0ElMjAyMDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29uZW9jc3AubWlj
# cm9zb2Z0LmNvbS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQBFSWDUd08X4g5HzvVf
# rB1SiV8pk6XPHT9jPkCmvU/uvBzmZRAjYk2gKYR3pXoStRJaJ/lhjC5Dq/2R7P1Y
# RZHCDYyK0zvSRMdE6YQtgGjmsdhzD0nCS6hVVcgfmNQscPJ1WHxbvG5EQgYQ0ZED
# 1FN0MOPQzWe1zbH5Va0dSxtnodBVRjnyDYEm7sNEcvJHTG3eXzAyd00E5KDCsEl4
# z5O0mvXqwaH2PS0200E6P4WqLwgs/NmUu5+Aa8Lw/2En2VkIW7Pkir4Un1jG6+tj
# /ehuqgFyUPPCh6kbnvk48bisi/zPjAVkj7qErr7fSYICCzJ4s4YUNVVHgdoFn2xb
# W7ZfBT3QA9zfhq9u4ExXbrVD5rxXSTFEUg2gzQq9JHxsdHyMfcCKLFQOXODSzcYe
# LpCd+r6GcoDBToyPdKccjC6mAq6+/hiMDnpvKUIHpyYEzWUeattyKXtMf+QrJeQ+
# ny5jBL+xqdOOPEz3dg7qn8/oprUrUbGLBv9fWm18fWXdAv1PCtLL/acMLtHoyeSV
# MKQYqDHb3Qm0uQ+NQ0YE4kUxSQa+W/cCzYAI32uN0nb9M4Mr1pj4bJZidNkM4JyY
# qezohILxYkgHbboJQISrQWrm5RYdyhKBpptJ9JJn0Z63LjdnzlOUxjlsAbQir2Wm
# z/OJE703BbHmQZRwzPx1vu7S5zCCB54wggWGoAMCAQICEzMAAAAHh6M0o3uljhwA
# AAAAAAcwDQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWljcm9zb2Z0IElkZW50aXR5
# IFZlcmlmaWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDIwMB4X
# DTIxMDQwMTIwMDUyMFoXDTM2MDQwMTIwMTUyMFowYzELMAkGA1UEBhMCVVMxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0
# IElEIFZlcmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALLwwK8ZiCji3VR6TElsaQhVCbRS/3pK+MHrJSj3
# Zxd3KU3rlfL3qrZilYKJNqztA9OQacr1AwoNcHbKBLbsQAhBnIB34zxf52bDpIO3
# NJlfIaTE/xrweLoQ71lzCHkD7A4As1Bs076Iu+mA6cQzsYYH/Cbl1icwQ6C65rU4
# V9NQhNUwgrx9rGQ//h890Q8JdjLLw0nV+ayQ2Fbkd242o9kH82RZsH3HEyqjAB5a
# 8+Ae2nPIPc8sZU6ZE7iRrRZywRmrKDp5+TcmJX9MRff241UaOBs4NmHOyke8oU1T
# Yrkxh+YeHgfWo5tTgkoSMoayqoDpHOLJs+qG8Tvh8SnifW2Jj3+ii11TS8/FGngE
# aNAWrbyfNrC69oKpRQXY9bGH6jn9NEJv9weFxhTwyvx9OJLXmRGbAUXN1U9nf4lX
# ezky6Uh/cgjkVd6CGUAf0K+Jw+GE/5VpIVbcNr9rNE50Sbmy/4RTCEGvOq3GhjIT
# bCa4crCzTTHgYYjHs1NbOc6brH+eKpWLtr+bGecy9CrwQyx7S/BfYJ+ozst7+yZt
# G2wR461uckFu0t+gCwLdN0A6cFtSRtR8bvxVFyWwTtgMMFRuBa3vmUOTnfKLsLef
# RaQcVTgRnzeLzdpt32cdYKp+dhr2ogc+qM6K4CBI5/j4VFyC4QFeUP2YAidLtvpX
# RRo3AgMBAAGjggI1MIICMTAOBgNVHQ8BAf8EBAMCAYYwEAYJKwYBBAGCNxUBBAMC
# AQAwHQYDVR0OBBYEFNlBKbAPD2Ns72nX9c0pnqRIajDmMFQGA1UdIARNMEswSQYE
# VR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBD
# AEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJqhSobyhmYBAcnz1AQ
# T2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJpZmljYXRpb24l
# MjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIwLmNybDCBwwYI
# KwYBBQUHAQEEgbYwgbMwgYEGCCsGAQUFBzAChnVodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZp
# Y2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5j
# cnQwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vbmVvY3NwLm1pY3Jvc29mdC5jb20vb2Nz
# cDANBgkqhkiG9w0BAQwFAAOCAgEAfyUqnv7Uq+rdZgrbVyNMul5skONbhls5fccP
# lmIbzi+OwVdPQ4H55v7VOInnmezQEeW4LqK0wja+fBznANbXLB0KrdMCbHQpbLvG
# 6UA/Xv2pfpVIE1CRFfNF4XKO8XYEa3oW8oVH+KZHgIQRIwAbyFKQ9iyj4aOWeAzw
# k+f9E5StNp5T8FG7/VEURIVWArbAzPt9ThVN3w1fAZkF7+YU9kbq1bCR2YD+Mtun
# SQ1Rft6XG7b4e0ejRA7mB2IoX5hNh3UEauY0byxNRG+fT2MCEhQl9g2i2fs6VOG1
# 9CNep7SquKaBjhWmirYyANb0RJSLWjinMLXNOAga10n8i9jqeprzSMU5ODmrMCJE
# 12xS/NWShg/tuLjAsKP6SzYZ+1Ry358ZTFcx0FS/mx2vSoU8s8HRvy+rnXqyUJ9H
# BqS0DErVLjQwK8VtsBdekBmdTbQVoCgPCqr+PDPB3xajYnzevs7eidBsM71PINK2
# BoE2UfMwxCCX3mccFgx6UsQeRSdVVVNSyALQe6PT12418xon2iDGE81OGCreLzDc
# MAZnrUAx4XQLUz6ZTl65yPUiOh3k7Yww94lDf+8oG2oZmDh5O1Qe38E+M3vhKwmz
# IeoB1dVLlz4i3IpaDcR+iuGjH2TdaC1ZOmBXiCRKJLj4DT2uhJ04ji+tHD6n58vh
# avFIrmcxghdWMIIXUgIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmll
# ZCBDUyBFT0MgQ0EgMDICEzMABVKOkd/moL83lLsAAAAFUo4wCwYJYIZIAWUDBAIB
# oHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFKD
# rUC9MfUl6WviS5DsMj8L+CQLkDYrBgi30kFi7KjkMAsGCSqGSIb3DQEBAQSCAYA8
# 0Xo0GGX7ZpDaorSLHctJQTfSmt+qazMeM1/ecSThsMnGaGT9kWLHn4inOzqDbBPH
# Fyc0aBgVJiOROhu03mJGzPKKL/UoGN9j+eS10NoXImO1MIrLrMAT4TAyhVLgsiWF
# NAntNNAuit8VxXyGGy8wLuJ0EUW1rspUyPWJn158JOADHduraEOIWp3IraLd0OXe
# TzCNAGKr1+WFmboLGuUgMUCJNl+wvXSR1QJLc8tf2O/N9cnJ+FmFUZQC+mhwNj2i
# 8RCkIiZ69p1PJe1jHU2x263+wvBZ8wY4t3UaVvBXICU/9GroNL/iFjM+Lz3Nuz9K
# EaQAdzXBIAhFwxlsRzZv7qAFdhAL2AhLcgjh8RpjYjZwp85vygLx3efhFonryKwJ
# PaFbwGd64tUs8DJ8HQDV4IezAPn4JmH4/OKJwms2o9y3vTHy6LGdSTOmuh1yJRP+
# 3/hha1ANcz5jdVczh1qVw3rAY8HZCFd9hTX/rnR1uv7+FlSXKBYg/1BymqQPGkGh
# ghS8MIIUuAYKKwYBBAGCNwMDATGCFKgwghSkBgkqhkiG9w0BBwKgghSVMIIUkQIB
# AzEPMA0GCWCGSAFlAwQCAQUAMIIBdAYLKoZIhvcNAQkQAQSgggFjBIIBXzCCAVsC
# AQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQgBkbGB1tI/P0Jt4ky6k5i
# upkrpPD7sK+xsPCIDNmiuG8CBmkBZHAFVBgTMjAyNTExMTkwMDI0MjIuNjQ0WjAE
# gAIB9AIIZBrTTIKYAm2ggemkgeYwgeMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlv
# bnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjQ5MUEtMDVFMC1E
# OTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lIFN0YW1waW5n
# IEF1dGhvcml0eaCCDykwggeCMIIFaqADAgECAhMzAAAABeXPD/9mLsmHAAAAAAAF
# MA0GCSqGSIb3DQEBDAUAMHcxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jvc29mdCBJZGVudGl0eSBWZXJp
# ZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAyMDAeFw0yMDEx
# MTkyMDMyMzFaFw0zNTExMTkyMDQyMzFaMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJs
# aWMgUlNBIFRpbWVzdGFtcGluZyBDQSAyMDIwMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEAnnznUmP94MWfBX1jtQYioxwe1+eXM9ETBb1lRkd3kcFdcG9/
# sqtDlwxKoVIcaqDb+omFio5DHC4RBcbyQHjXCwMk/l3TOYtgoBjxnG/eViS4sOx8
# y4gSq8Zg49REAf5huXhIkQRKe3Qxs8Sgp02KHAznEa/Ssah8nWo5hJM1xznkRsFP
# u6rfDHeZeG1Wa1wISvlkpOQooTULFm809Z0ZYlQ8Lp7i5F9YciFlyAKwn6yjN/kR
# 4fkquUWfGmMopNq/B8U/pdoZkZZQbxNlqJOiBGgCWpx69uKqKhTPVi3gVErnc/qi
# +dR8A2MiAz0kN0nh7SqINGbmw5OIRC0EsZ31WF3Uxp3GgZwetEKxLms73KG/Z+Mk
# euaVDQQheangOEMGJ4pQZH55ngI0Tdy1bi69INBV5Kn2HVJo9XxRYR/JPGAaM6xG
# l57Ei95HUw9NV/uC3yFjrhc087qLJQawSC3xzY/EXzsT4I7sDbxOmM2rl4uKK6eE
# purRduOQ2hTkmG1hSuWYBunFGNv21Kt4N20AKmbeuSnGnsBCd2cjRKG79+TX+sTe
# hawOoxfeOO/jR7wo3liwkGdzPJYHgnJ54UxbckF914AqHOiEV7xTnD1a69w/UTxw
# jEugpIPMIIE67SFZ2PMo27xjlLAHWW3l1CEAFjLNHd3EQ79PUr8FUXetXr0CAwEA
# AaOCAhswggIXMA4GA1UdDwEB/wQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADAdBgNV
# HQ4EFgQUa2koOjUvSGNAz3vYr0npPtk92yEwVAYDVR0gBE0wSzBJBgRVHSAAMEEw
# PwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9j
# cy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFMh+
# 0mqFKhvKGZgEByfPUBBPaKiiMIGEBgNVHR8EfTB7MHmgd6B1hnNodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBJZGVudGl0eSUy
# MFZlcmlmaWNhdGlvbiUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUyMEF1dGhvcml0eSUy
# MDIwMjAuY3JsMIGUBggrBgEFBQcBAQSBhzCBhDCBgQYIKwYBBQUHMAKGdWh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwSWRl
# bnRpdHklMjBWZXJpZmljYXRpb24lMjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRo
# b3JpdHklMjAyMDIwLmNydDANBgkqhkiG9w0BAQwFAAOCAgEAX4h2x35ttVoVdedM
# eGj6TuHYRJklFaW4sTQ5r+k77iB79cSLNe+GzRjv4pVjJviceW6AF6ycWoEYR0LY
# haa0ozJLU5Yi+LCmcrdovkl53DNt4EXs87KDogYb9eGEndSpZ5ZM74LNvVzY0/nP
# ISHz0Xva71QjD4h+8z2XMOZzY7YQ0Psw+etyNZ1CesufU211rLslLKsO8F2aBs2c
# Io1k+aHOhrw9xw6JCWONNboZ497mwYW5EfN0W3zL5s3ad4Xtm7yFM7Ujrhc0aqy3
# xL7D5FR2J7x9cLWMq7eb0oYioXhqV2tgFqbKHeDick+P8tHYIFovIP7YG4ZkJWag
# 1H91KlELGWi3SLv10o4KGag42pswjybTi4toQcC/irAodDW8HNtX+cbz0sMptFJK
# +KObAnDFHEsukxD+7jFfEV9Hh/+CSxKRsmnuiovCWIOb+H7DRon9TlxydiFhvu88
# o0w35JkNbJxTk4MhF/KgaXn0GxdH8elEa2Imq45gaa8D+mTm8LWVydt4ytxYP/bq
# jN49D9NZ81coE6aQWm88TwIf4R4YZbOpMKN0CyejaPNN41LGXHeCUMYmBx3PkP8A
# DHD1J2Cr/6tjuOOCztfp+o9Nc+ZoIAkpUcA/X2gSMkgHAPUvIdtoSAHEUKiBhI6J
# QivRepyvWcl+JYbYbBh7pmgAXVswggefMIIFh6ADAgECAhMzAAAATqPGDj4xw3Qn
# AAAAAABOMA0GCSqGSIb3DQEBDAUAMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMg
# UlNBIFRpbWVzdGFtcGluZyBDQSAyMDIwMB4XDTI1MDIyNzE5NDAxN1oXDTI2MDIy
# NjE5NDAxN1owgeMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# LTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEn
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjQ5MUEtMDVFMC1EOTQ3MTUwMwYDVQQD
# EyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAIbflIu6bAltld7nRX0T6SbF
# 4bEMjoEmU7dL7ZHBsOQtg5hiGs8GQlrZVE1yAWzGArehop47rm2Q0Widteu8M0H/
# c7caoehVD1so8GY0Vo12kfImQp1qt5A1kcTcYXWmyQbeLx9w8KHBnIHpesP+sk2S
# TglYsFu3CtHtIFXjrLAF7+NjA0Urws3ny5bPd+tjxO6vFIY3V6yXb3GIbcHbfmle
# Nfra4ZEAA/hFxDDdm2ReLt/6ij7iVM7Q6EbDQrguRMQydF8HEyLP98iGKHEH36mc
# z+eJ9Xl/bva+Pk/9Yj1aic2MBrA7YTbY/hdw3HSskxvUUgNIcKFQVsz36FSMXQOz
# VXW1cFXL4UiGqw+ylClJcZ0l3H0Aiwsnpvo0t9v4zD5jwJrmeNIlKBeH5EGbfXPe
# lbVEZ2ntMBCgPegB5qelqo+bMfSz9lRTO2c7LByYfQs6UOJL2JhgrZoT+g7WNSEZ
# KXQ+o6DXujpif5XTMdMzWCOOiJnMcevpZdD2aYaOEGFXUm51QE2JLKni/71ecZjI
# 6Df4C6vBXRV7WT76BYUgcEa08kYbW5kN0jjnBPGFASr9SSnZNGFKQ4J8MyRxEBPZ
# TN33MX9Pz+3ZfZF4mS8oyXMCcOmE406M9RSQP9bTVWVuOR0MHo56EpUAK1hVLKfu
# SD0dEwbGiMawHrelOKNBAgMBAAGjggHLMIIBxzAdBgNVHQ4EFgQU8Me6g3SqStL0
# tyd5iw4rvw1NamIwHwYDVR0jBBgwFoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYD
# VR0fBGUwYzBhoF+gXYZbaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0El
# MjAyMDIwLmNybDB5BggrBgEFBQcBAQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8E
# AjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNV
# HSAEXzBdMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EM
# AQQCMA0GCSqGSIb3DQEBDAUAA4ICAQATJnMrpCGuWq9ZOgEKcKyPZj71n/JpX9SY
# aTK/qOrPsIxzf/qvq//uj0dTBnfx7KW0aI1Yz2C6Q78g1b80AU8ARNyoIhmT2SWN
# I8k7FLo7qeWSzN4bcgDgTRSaKGPiWWbJtEjbCgbIkNJ3ZTP9iBJCsxZwv6a45an9
# ApG1NV/wP8niV0RBCH9SIHmD6sv34lxlzHTgGGf1n289fg/LoSMsLFPZ4+G3p0KY
# u7A5fz616IBk9ZWpXQxHFNcSMg/rlwbO65k0k0sRrUlIWkk+71nt2NgpsFaWi2JY
# q0msX0uzV3LbLaWfKzg1B3ugoSXLypZg3pPypkdXh1wra9h222RuzjyOmwyWi7jT
# QUBOPZenyapbJhAZXlCxOBaN00bs1V+zUg2miNte9E8CWHagq+Rts/1iSiPCwWmM
# KfqilSSdSMtYSXMyciCKWexeRjAX0QovSsGv0pMqkYfPa5ubnI03ab/A6Kod2TEF
# 8ufShV9sQSqbDscMW12TQOboyTUhc8wPp8p2WWejvrH+9AUO6hToaYeM4jMmmOcA
# AlpHm2AY+GAk+Y54d6DYA6NBED+CSEFSakUVRqNbkN4mN1SOklodZhvRphmF9Ot0
# DuzLu/KByWIfHbaY/wTusrEVGH4W4n39FmcMIvVbMpeOENZ59+xGiFwt5izuabZi
# HN/EFR4leTGCA9QwggPQAgEBMHgwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBS
# U0EgVGltZXN0YW1waW5nIENBIDIwMjACEzMAAABOo8YOPjHDdCcAAAAAAE4wDQYJ
# YIZIAWUDBAIBBQCgggEtMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkq
# hkiG9w0BCQQxIgQgQ7FwKxOspnxIZF0bQucOs5rK/M+i4N1Uv87gX9cP4sswgd0G
# CyqGSIb3DQEJEAIvMYHNMIHKMIHHMIGgBCBvsqfT7ygFHbDe/Tj3QCn25JHDuUhg
# ytNPRb67/5ZKFzB8MGWkYzBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBU
# aW1lc3RhbXBpbmcgQ0EgMjAyMAITMwAAAE6jxg4+McN0JwAAAAAATjAiBCBYQ6uK
# WG4ujJVwrw1kVwnKNMri67bpGbByp5baRtYu5DANBgkqhkiG9w0BAQsFAASCAgAx
# PDEkagQelYJecNsAIt3ehcn0nb8FYP48OLmU/Nq2iJiyJNF1sK5d8YIBLftpLj8Z
# 2toMtObUqFIPSCPjFUzG2tHOCI4womEk4Z2sjb9iyZ1xnMz4yxlgsMKw+/SIaSBN
# kQUYgxsd9oNFYmdl7Z3hpTNS8nK1sN55djJsTIlczzCtPE13VJBsrqprMQ12G0k0
# HH/tnaByJp9eFpreddGSCBPSDiPglOu1SnNLQC6aIl6VE9b+/OlQ2P/qzq552tH6
# sp3quosMV4VQ5XrP84+5x6im+1apKpd7tRliv7NXhSlXPf4yPEXTfLgMIZxCN6nE
# LNcqJpApG7S8rsNApH0m3hRgsnhSHLaVKAve6QfKqfBOvq3HiqClkvq6r+YyiYFe
# bU5qx+fUW7WuzL+Rwe8xgOpW/QuWSSW7nWewM1ekEfxX0faZ6djBQ1kHqDsEnUzj
# /z/B+0ZQHyWxYYItmpb2oQqU7kxxu3KIjBBUB2Bj/rdbrHCPFP82h9DCspw7TLoh
# Ov4nPTRMqzeXVxVk6FD6dbEOJ8hxOxUEMlSr1Ca8anigzGbJUwruhb+SDGnN05QU
# teFs/d/G8491PgctmAdjbyaOEy5rIMCqAEYpNe4qfVuw2g6U2t3lMI+e8gGReCG1
# zM4wTKxoEIwBHewK5bklnaoN1uq+UDSu/5ezjGtPew==
# SIG # End signature block
