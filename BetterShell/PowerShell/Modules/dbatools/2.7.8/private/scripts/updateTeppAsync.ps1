if (-not ([Dataplat.Dbatools.TabExpansion.TabExpansionHost]::TeppAsyncDisabled -or [Dataplat.Dbatools.TabExpansion.TabExpansionHost]::TeppDisabled)) {
    $scriptBlock = {
        $script:___ScriptName = 'dbatools-teppasynccache'

        # Defer module import to avoid collisions and reduce CPU impact
        Start-Sleep -Seconds 15
        $dbatoolsPath = Join-Path -Path ([Dataplat.Dbatools.dbaSystem.SystemHost]::ModuleBase) -ChildPath "dbatools.psd1"
        Import-Module $dbatoolsPath
        $script:dbatools = Get-Module dbatools

        #region Utility Functions
        function Get-PriorityServer {
            [Dataplat.Dbatools.TabExpansion.TabExpansionHost]::InstanceAccess.Values | Where-Object -Property LastUpdate -LT (New-Object System.DateTime(1, 1, 1, 1, 1, 1))
        }

        function Get-ActionableServer {
            [Dataplat.Dbatools.TabExpansion.TabExpansionHost]::InstanceAccess.Values | Where-Object -Property LastUpdate -LT ((Get-Date) - ([Dataplat.Dbatools.TabExpansion.TabExpansionHost]::TeppUpdateInterval)) | Where-Object -Property LastUpdate -GT ((Get-Date) - ([Dataplat.Dbatools.TabExpansion.TabExpansionHost]::TeppUpdateTimeout))
        }

        function Update-TeppCache {
            [CmdletBinding()]
            param (
                [Parameter(ValueFromPipeline)]
                $ServerAccess
            )
            process {
                if ([Dataplat.Dbatools.TabExpansion.TabExpansionHost]::TeppUdaterStopper) { break }

                foreach ($instance in $ServerAccess) {
                    if ([Dataplat.Dbatools.TabExpansion.TabExpansionHost]::TeppUdaterStopper) { break }
                    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($instance.ConnectionObject)
                    try {
                        $server.ConnectionContext.Connect()
                    } catch {
                        & $script:dbatools { Write-Message "Failed to connect to $instance" -ErrorRecord $_ -Level Debug }
                        continue
                    }

                    $FullSmoName = ([Dataplat.Dbatools.Parameter.DbaInstanceParameter]$instance.ConnectionObject.ConnectionString).FullSmoName.ToLowerInvariant()

                    foreach ($scriptBlock in ([Dataplat.Dbatools.TabExpansion.TabExpansionHost]::TeppGatherScriptsFast)) {
                        $scriptName = ([Dataplat.Dbatools.TabExpansion.TabExpansionHost]::Scripts.Values | Where-Object ScriptBlock -EQ $scriptBlock).Name
                        # Workaround to avoid stupid issue with scriptblock from different runspace
                        try { [ScriptBlock]::Create($scriptBlock).Invoke() }
                        catch { & $script:dbatools { Write-Message "Failed to execute TEPP $scriptName against $FullSmoName" -ErrorRecord $_ -Level Debug } }
                    }

                    foreach ($scriptBlock in ([Dataplat.Dbatools.TabExpansion.TabExpansionHost]::TeppGatherScriptsSlow)) {
                        $scriptName = ([Dataplat.Dbatools.TabExpansion.TabExpansionHost]::Scripts.Values | Where-Object ScriptBlock -EQ $scriptBlock).Name
                        # Workaround to avoid stupid issue with scriptblock from different runspace
                        try { [ScriptBlock]::Create($scriptBlock).Invoke() }
                        catch { & $script:dbatools { Write-Message "Failed to execute TEPP $scriptName against $FullSmoName" -ErrorRecord $_ -Level Debug } }
                    }

                    $server.ConnectionContext.Disconnect()
                    $instance.LastUpdate = Get-Date
                }
            }
        }
        #endregion Utility Functions

        try {
            #region Main Execution
            while ($true) {
                # This portion is critical to gracefully closing the script
                if ([Dataplat.Dbatools.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLowerInvariant()].State -notlike "Running") {
                    break
                }

                Get-PriorityServer | Update-TeppCache
                Get-ActionableServer | Update-TeppCache
                Start-Sleep -Seconds 5
            }
            #endregion Main Execution
        } catch {
            & $script:dbatools { Write-Message "General Failure" -ErrorRecord $_ -Level Debug }
        } finally {
            [Dataplat.Dbatools.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLowerInvariant()].SignalStopped()
        }
    }

    Register-DbaRunspace -ScriptBlock $scriptBlock -Name "dbatools-teppasynccache"
    Start-DbaRunspace -Name "dbatools-teppasynccache"
}
# SIG # Begin signature block
# MIIt2gYJKoZIhvcNAQcCoIItyzCCLccCAQMxDTALBglghkgBZQMEAgEwewYKKwYB
# BAGCNwIBBKBtBGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAMUoWyM3Zh7OqE
# /ci5Y0gAnGF/mRUj9vLGOpEWWanyEqCCFdswggbXMIIEv6ADAgECAhMzAAVSjpHf
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
# avFIrmcxghdVMIIXUQIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmll
# ZCBDUyBFT0MgQ0EgMDICEzMABVKOkd/moL83lLsAAAAFUo4wCwYJYIZIAWUDBAIB
# oHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBqn
# gERnk2TIM81huI9q2/Jca3jHapPD+lnPFn9/3BxfMAsGCSqGSIb3DQEBAQSCAYBs
# e+0TKVAdApEm+ZDi58UrK4JPBongaykaXTZcZ3sUfqiqcMUIS3H2GyR7Ob31M8wn
# 7GaKXVTvLQRxxC3pXTpsDuXMtMpr2OTvrNqoE5OGWu5kuIGIsr0WgWCXx6vgc6DF
# d8klrk5NkVbVUtFWZ/W80oTfhHZJPnr7tjf1mC8VJS0SZGS7V/teB1NMzuarsh2m
# Bdfjxjhw3jS+kKO0QCSEUPXPOLX+VRrFu/ADUeEl5Cxsz0HfWVryugjmLZbs63lF
# 4h0/34V85rk1hQfzY3AvHd5iZIZpQfAYrZctVttWZLsCPNLJeDOHjGGYEBQyvpln
# U8RjmkazVOZ9vXOuKIo8YShRfQZFVOlwTs87DxEnomJX8sCNt0ZUmw/quGXDJKg8
# kmjZRX4aEgChKMGgdSyFrza5wHz07WRjzTcYsDHDhLDEFzhMsyiYdIDxNeeGaN2g
# lTtpVscXGvxqQ36NFcAiV+FaUb7UTt4u0eav0XxNksv8Rzme7haHsMnal0h0jZ+h
# ghS7MIIUtwYKKwYBBAGCNwMDATGCFKcwghSjBgkqhkiG9w0BBwKgghSUMIIUkAIB
# AzEPMA0GCWCGSAFlAwQCAQUAMIIBcwYLKoZIhvcNAQkQAQSgggFiBIIBXjCCAVoC
# AQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQgq01buWDzaVR8+ry6nXJL
# x/TnR8Xmul736jGX5tp9Yu0CBmkDwp3AkBgSMjAyNTExMTkwMDI0MTcuMDFaMASA
# AgH0AghqblF8w8nIP6CB6aSB5jCB4zELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9u
# cyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046NDUxQS0wNUUwLUQ5
# NDcxNTAzBgNVBAMTLE1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcg
# QXV0aG9yaXR5oIIPKTCCB4IwggVqoAMCAQICEzMAAAAF5c8P/2YuyYcAAAAAAAUw
# DQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWljcm9zb2Z0IElkZW50aXR5IFZlcmlm
# aWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDIwMB4XDTIwMTEx
# OTIwMzIzMVoXDTM1MTExOTIwNDIzMVowYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1Ymxp
# YyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQCefOdSY/3gxZ8FfWO1BiKjHB7X55cz0RMFvWVGR3eRwV1wb3+y
# q0OXDEqhUhxqoNv6iYWKjkMcLhEFxvJAeNcLAyT+XdM5i2CgGPGcb95WJLiw7HzL
# iBKrxmDj1EQB/mG5eEiRBEp7dDGzxKCnTYocDOcRr9KxqHydajmEkzXHOeRGwU+7
# qt8Md5l4bVZrXAhK+WSk5CihNQsWbzT1nRliVDwunuLkX1hyIWXIArCfrKM3+RHh
# +Sq5RZ8aYyik2r8HxT+l2hmRllBvE2Wok6IEaAJanHr24qoqFM9WLeBUSudz+qL5
# 1HwDYyIDPSQ3SeHtKog0ZubDk4hELQSxnfVYXdTGncaBnB60QrEuazvcob9n4yR6
# 5pUNBCF5qeA4QwYnilBkfnmeAjRN3LVuLr0g0FXkqfYdUmj1fFFhH8k8YBozrEaX
# nsSL3kdTD01X+4LfIWOuFzTzuoslBrBILfHNj8RfOxPgjuwNvE6YzauXi4orp4Sm
# 6tF245DaFOSYbWFK5ZgG6cUY2/bUq3g3bQAqZt65KcaewEJ3ZyNEobv35Nf6xN6F
# rA6jF9447+NHvCjeWLCQZ3M8lgeCcnnhTFtyQX3XgCoc6IRXvFOcPVrr3D9RPHCM
# S6Ckg8wggTrtIVnY8yjbvGOUsAdZbeXUIQAWMs0d3cRDv09SvwVRd61evQIDAQAB
# o4ICGzCCAhcwDgYDVR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1Ud
# DgQWBBRraSg6NS9IY0DPe9ivSek+2T3bITBUBgNVHSAETTBLMEkGBFUdIAAwQTA/
# BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2Nz
# L1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcU
# AgQMHgoAUwB1AGIAQwBBMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUyH7S
# aoUqG8oZmAQHJ89QEE9oqKIwgYQGA1UdHwR9MHsweaB3oHWGc2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElkZW50aXR5JTIw
# VmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIw
# MjAyMC5jcmwwgZQGCCsGAQUFBwEBBIGHMIGEMIGBBggrBgEFBQcwAoZ1aHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJZGVu
# dGl0eSUyMFZlcmlmaWNhdGlvbiUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUyMEF1dGhv
# cml0eSUyMDIwMjAuY3J0MA0GCSqGSIb3DQEBDAUAA4ICAQBfiHbHfm21WhV150x4
# aPpO4dhEmSUVpbixNDmv6TvuIHv1xIs174bNGO/ilWMm+Jx5boAXrJxagRhHQtiF
# prSjMktTliL4sKZyt2i+SXncM23gRezzsoOiBhv14YSd1Klnlkzvgs29XNjT+c8h
# IfPRe9rvVCMPiH7zPZcw5nNjthDQ+zD563I1nUJ6y59TbXWsuyUsqw7wXZoGzZwi
# jWT5oc6GvD3HDokJY401uhnj3ubBhbkR83RbfMvmzdp3he2bvIUztSOuFzRqrLfE
# vsPkVHYnvH1wtYyrt5vShiKheGpXa2AWpsod4OJyT4/y0dggWi8g/tgbhmQlZqDU
# f3UqUQsZaLdIu/XSjgoZqDjamzCPJtOLi2hBwL+KsCh0Nbwc21f5xvPSwym0Ukr4
# o5sCcMUcSy6TEP7uMV8RX0eH/4JLEpGyae6Ki8JYg5v4fsNGif1OXHJ2IWG+7zyj
# TDfkmQ1snFOTgyEX8qBpefQbF0fx6URrYiarjmBprwP6ZObwtZXJ23jK3Fg/9uqM
# 3j0P01nzVygTppBabzxPAh/hHhhls6kwo3QLJ6No803jUsZcd4JQxiYHHc+Q/wAM
# cPUnYKv/q2O444LO1+n6j01z5mggCSlRwD9faBIySAcA9S8h22hIAcRQqIGEjolC
# K9F6nK9ZyX4lhthsGHumaABdWzCCB58wggWHoAMCAQICEzMAAABUP/IAPr6h2KYA
# AAAAAFQwDQYJKoZIhvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBS
# U0EgVGltZXN0YW1waW5nIENBIDIwMjAwHhcNMjUwMjI3MTk0MDI3WhcNMjYwMjI2
# MTk0MDI3WjCB4zELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEt
# MCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046NDUxQS0wNUUwLUQ5NDcxNTAzBgNVBAMT
# LE1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5MIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArtaeeOXDn3qKAPNDtHRfbe9B
# Vr6tco0gAJ3fk4/4wPULvIClKbFNDusAewEXrqXGT7WkBTmrtTNpY5busWuQ9VeF
# 31nNwJD7JcqALBgQjtzOyeqHIdXmtcl43ScFLXRzvGTniE5CLskafwxGbmN1bpTu
# UzElua+v6tOQ7uWox70NydE4PT0ysrTdWAbM2W9q4wr2umor+ENQkeyWCLyn1SQF
# R55FJlz5z1ZwfM0XEEe/uM0H1k+doisabIGq8XXdpJdCwDc4snkSsBb60+iICF4C
# lC5CUof2XIsXQen7gN7K3tX5n1r7hSJg18wsSqX3rgEVSo+AOb2JyvyjRJQCBziK
# 1z/5dnpCbg+i4Q8rpXz26ikNLPCGU7G16GrU2XNLf+dyqVx20PWvq6oolJjLOvfj
# PpBf50A5BWtb4gW1UkDvEiiwLpR/cxPyY7p2vU+EZHwZXg0nX8FAFeDzeNh4r0Rv
# KLtSUZ9doYib6feuTlvaO4gEFp1yaFCcyWN7pJPC4KSeF4W7pRD9lQtjFxfbQj1G
# LeuKYHSejENSwzZ7eg2MKqMFJ9m7gbkpE5GX7ywREKjBrBpuBEpwkojTmAWtJXYD
# FzT408XEklwkYdNZceZ7LFQAe5bdDaWhJV/GwiypkwaeGJBfh/zG2pHb50m71MrW
# S5YNIq/sMqFIwcH3wjsCAwEAAaOCAcswggHHMB0GA1UdDgQWBBTSaTaC27NqQBAW
# puaBdYBuZzdd2TAfBgNVHSMEGDAWgBRraSg6NS9IY0DPe9ivSek+2T3bITBsBgNV
# HR8EZTBjMGGgX6BdhltodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Ny
# bC9NaWNyb3NvZnQlMjBQdWJsaWMlMjBSU0ElMjBUaW1lc3RhbXBpbmclMjBDQSUy
# MDIwMjAuY3JsMHkGCCsGAQUFBwEBBG0wazBpBggrBgEFBQcwAoZdaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBQdWJsaWMl
# MjBSU0ElMjBUaW1lc3RhbXBpbmclMjBDQSUyMDIwMjAuY3J0MAwGA1UdEwEB/wQC
# MAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQDAgeAMGYGA1Ud
# IARfMF0wUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAIBgZngQwB
# BAIwDQYJKoZIhvcNAQEMBQADggIBAHPYFN+GUlaVAVOamZeYg+H0OGwoyaATpqYl
# bJzjbM0xcTYpsq0FAKRwcUKgtOsE5G3namweabQsx1SoTF88vMiA/v6+3IGLTcFS
# QFOvR/URyAwfDNj/xpYI793HkFK2Kn/djPA8sd5sJqj+8gc2ynC/GYpk+fPrwGyX
# gZvG16zwnuEgf2ZpsdRj/aMnTIwa3vXrgBdoCAyDOI78PxlHq8imm0qwBwsCVbQH
# 4XrigU5V/kaFViyzzqEPZA35QrSdM/eydTj6utZkCXHBrDY6ytTwATJvuvpajNtX
# BPFE0hNIuuWKZtT4vWNEwV/eTN9r+E4CoQYBFbmk3hQ5T5TqcU2n7iOmuLWJKUaS
# drf5BkSlEu7O7l+cw1XyA1QGHQ8yTSmrqUwQqBqqubqwHZFW4b47/VYlABzym30Q
# cf+jC5kPprhDg2FWpRldarDN+5L7PqhPzypxQiib0BjRYOwyMDdzie9QtLqD3kU1
# DG+cmEOGrEkRV5/zjnbAROxGVjFgT4HrhQ9phYFLMkITY55rnk9LLN4EwG2w+XWG
# CWaijfIkpY5LcQGbrCi45uN+ODSjL2R5s9RxTNaz7nvrs0TxX8Gso66W9lbJP6om
# CZFcKJAFWBv/L+5oILyl7LHRBC6gOwn1WGdDlxWX37fKt1diGP2W2XJ32bVOWbg9
# XAGuSg4UMYID1DCCA9ACAQEweDBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lc3RhbXBpbmcgQ0EgMjAyMAITMwAAAFQ/8gA+vqHYpgAAAAAAVDANBglg
# hkgBZQMEAgEFAKCCAS0wGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqG
# SIb3DQEJBDEiBCBUQxsZDEcYYNDWjcdLZWi7MFzhtSqysXtTx84ibSq4WjCB3QYL
# KoZIhvcNAQkQAi8xgc0wgcowgccwgaAEINSBqnpiWZhJb9YgX/6ts2MkRk0up9w0
# QKjumhCYSbALMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwAhMzAAAAVD/yAD6+odimAAAAAABUMCIEIGbfiG70
# 5pIuvG/Orodbx4r7HRXXMNHB2T1Q31tlZHibMA0GCSqGSIb3DQEBCwUABIICAHRk
# x8GF2tSPRHkt5/RnOcfsqBb+0cF9Axki5AjLQCdKC0ArM1pKh1OCaxmqyc99W7xa
# YXdEOqn+5Q3jWsO3uMY7gUVsmlw95KJbSio5SSqPF8VO6T/mpSuWR3U9DuCuQ8wY
# lkLU3ZzfLsJRYjpJjfVvXbNMhTEAYQMtbj7RyV6czSZ2fnWDqFZG1loBv9Bvm1Ft
# dIQGBsNbxTWxymRnid308gGkOcPlAR8mGAl9WRuwzTqJmFQ3r7+86LYnwsBJPJE1
# ELqOSGMIgxFvoXcYQF20qGpEZQJpC5xpy/kSxfLrMfTJA7NJVskqup7cZfPtLlW6
# YqYZ/4dhMYBolum1TKeY+Z0ow8DyiWVtjOri6pL+qQE7yFNND3VIcBp/idUbC+jb
# jJaS8B4Hiq85hnD5SNOBItQ0DCXD//pTWlQ03HZb+Ut/1HOwChDOG2iIITxwgGFL
# hpVBEZh1oVJ4yPeladFI/phB3RH1T+c8FcaX4LsQCtSX9NT1uuoqVKgeBJvWVGIn
# BV2NeZJWvfwYBG3QFM+1hcPAHGS4NvEo97q2VVQQezB6TDZ+vICpw0Qgw2mRR3S9
# 5UzQJ/NeAOL6oiON54/RHIxO1VaytqrZn20RFPSH4gxXv0El6ocfWYXDaz1jQHoQ
# TgKXmqd7Lfr5mISz0LPRSVoQJrQEa1fv/OOx6Ft5
# SIG # End signature block
