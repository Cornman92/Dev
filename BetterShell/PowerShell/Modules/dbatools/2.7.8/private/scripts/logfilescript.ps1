$scriptBlock = {
    $script:___ScriptName = 'dbatools-logging'

    #region Helper Functions
    function Clean-ErrorXml {
        [CmdletBinding()]
        param (
            $Path
        )

        $totalLength = $Null
        $files = Get-ChildItem -Path $Path.FullName -Filter "dbatools_$($pid)_error_*.xml" | Sort-Object LastWriteTime
        $totalLength = $files | Measure-Object Length -Sum | Select-Object -ExpandProperty Sum
        if (([Dataplat.Dbatools.Message.LogHost]::MaxErrorFileBytes) -gt $totalLength) { return }

        $removed = 0
        foreach ($file in $files) {
            $removed += $file.Length
            Remove-Item -Path $file.FullName -Force -Confirm:$false

            if (($totalLength - $removed) -lt ([Dataplat.Dbatools.Message.LogHost]::MaxErrorFileBytes)) { break }
        }
    }

    function Clean-MessageLog {
        [CmdletBinding()]
        param (
            $Path
        )

        if ([Dataplat.Dbatools.Message.LogHost]::MaxMessagefileCount -eq 0) { return }

        $files = Get-ChildItem -Path $Path.FullName -Filter "dbatools_$($pid)_message_*.log" | Sort-Object LastWriteTime
        if (([Dataplat.Dbatools.Message.LogHost]::MaxMessagefileCount) -ge $files.Count) { return }

        $removed = 0
        foreach ($file in $files) {
            $removed++
            Remove-Item -Path $file.FullName -Force -Confirm:$false

            if (($files.Count - $removed) -le ([Dataplat.Dbatools.Message.LogHost]::MaxMessagefileCount)) { break }
        }
    }

    function Clean-GlobalLog {
        [CmdletBinding()]
        param (
            $Path
        )

        # Kill too old files
        Get-ChildItem -Path "$($Path.FullName)\*" -Include "*.xml", "*.log" -Filter "*" | Where-Object LastWriteTime -LT ((Get-Date) - ([Dataplat.Dbatools.Message.LogHost]::MaxLogFileAge)) |Remove-Item -Force -Confirm:$false

        # Handle the global overcrowding
        $files = Get-ChildItem -Path "$($Path.FullName)\*" -Include "*.xml", "*.log" -Filter "*" | Sort-Object LastWriteTime
        if (-not ($files)) { return }
        $totalLength = $files | Measure-Object Length -Sum | Select-Object -ExpandProperty Sum

        if (([Dataplat.Dbatools.Message.LogHost]::MaxTotalFolderSize) -gt $totalLength) { return }

        $removed = 0
        foreach ($file in $files) {
            $removed += $file.Length
            Remove-Item -Path $file.FullName -Force -Confirm:$false

            if (($totalLength - $removed) -lt ([Dataplat.Dbatools.Message.LogHost]::MaxTotalFolderSize)) { break }
        }
    }
    #endregion Helper Functions

    try {
        while ($true) {
            # This portion is critical to gracefully closing the script
            if ([Dataplat.Dbatools.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLowerInvariant()].State -notlike "Running") {
                break
            }

            $path = [Dataplat.Dbatools.Message.LogHost]::LoggingPath
            if (-not (Test-Path $path)) {
                $root = New-Item $path -ItemType Directory -Force -ErrorAction Stop
            } else {
                $root = Get-Item -Path $path
            }

            $errorFiles = Get-ChildItem -Path $root.FullName -Filter "dbatools_$($pid)_error_*.xml" | Sort-Object LastWriteTime -Descending
            [int]$num_Error = if ($errorFiles) {
                (Select-String -InputObject $errorFiles[0].Name -Pattern "(\d+)" -AllMatches).Matches[1].Value
            } else {
                0
            }

            $messageFiles = Get-ChildItem -Path $root.FullName -Filter "dbatools_$($pid)_message_*.xml" | Sort-Object LastWriteTime -Descending
            [int]$num_Message = if ($messageFiles) {
                (Select-String -InputObject $messageFiles[0].Name -Pattern "(\d+)" -AllMatches).Matches[1].Value
            } else {
                0
            }

            #region Process Errors
            while ([Dataplat.Dbatools.Message.LogHost]::OutQueueError.Count -gt 0) {
                $num_Error++

                $Record = $null
                $null = [Dataplat.Dbatools.Message.LogHost]::OutQueueError.TryDequeue([ref]$Record)

                if ($Record) {
                    $Record | Export-Clixml -Path "$($root.FullName)\dbatools_$($pid)_error_$($num_Error).xml" -Depth 3
                }

                Clean-ErrorXml -Path $root
            }
            #endregion Process Errors

            #region Process Logs
            while ([Dataplat.Dbatools.Message.LogHost]::OutQueueLog.Count -gt 0) {
                $CurrentFile = "$($root.FullName)\dbatools_$($pid)_message_$($num_Message).log"
                if (Test-Path $CurrentFile) {
                    $item = Get-Item $CurrentFile
                    if ($item.Length -gt ([Dataplat.Dbatools.Message.LogHost]::MaxMessagefileBytes)) {
                        $num_Message++
                        $CurrentFile = "$($root.FullName)\dbatools_$($pid)_message_$($num_Message).log"
                    }
                }

                $Entry = $null
                $null = [Dataplat.Dbatools.Message.LogHost]::OutQueueLog.TryDequeue([ref]$Entry)
                if ($Entry) {
                    Add-Content -Path $CurrentFile -Value (ConvertTo-Csv -InputObject $Entry -NoTypeInformation)[1]
                }
            }
            #endregion Process Logs

            Clean-MessageLog -Path $root
            Clean-GlobalLog -Path $root

            Start-Sleep -Seconds 5
        }
    } catch { }
    finally {
        [Dataplat.Dbatools.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLowerInvariant()].SignalStopped()
    }
}

Register-DbaRunspace -ScriptBlock $scriptBlock -Name "dbatools-logging"
Start-DbaRunspace -Name "dbatools-logging"
# SIG # Begin signature block
# MIIt2wYJKoZIhvcNAQcCoIItzDCCLcgCAQMxDTALBglghkgBZQMEAgEwewYKKwYB
# BAGCNwIBBKBtBGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCIiVU8AKz9mdHY
# nVoRGv/hsyZ2M0kd1XNZ0GLkGBf4waCCFdswggbXMIIEv6ADAgECAhMzAAVSjpHf
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJcx
# OPjOi0LyPr0/O/neHJquwA1VmZnZU6PF0kScm4EAMAsGCSqGSIb3DQEBAQSCAYAK
# Lap+rF2Y20whx7Mm0WzOA2RC2lpwEpvOrxBgs+z3B0Z7H4TRcpZREi5PcIW6DL32
# 1RSHUlO4I6/wusZWnDIT/NGPEqrKtwIf1ukV3VmqveC77utdgMg+F6563g0fI5XO
# DXf6hDQtXnCV1sKELejJ5h2KsRpwQCBKVlGw0Q8erJN95q/gkO4fcJYYHHx9oY5l
# GgJytp1XbCegSzvi0aPnaDCmmrMm9q6wRDbyep3BTM/vw+ZiHjxZVwhmutjsoW+j
# 8IECvKs7eRYNnfTJQr5dlpHQCl+ZDoirh/0v4+J8+w6GPwgJWbZts8SS/So4n4pI
# qhpW1oN3ZvNkc2AplH/WRzoUnau9EXh6fUCKnJ+tgdrErBvmWuD69TlCerMC+lao
# GyVpZhZC5IZfmnMYBUgiigJM4Va7R7ywPsdsaSCBsJ3cQgZfktcTQSxC7vhCNq5l
# eUcNfwEftf7Qtfuxz28dOer3cuHEKqpF3H+xfYWpKGhVu3dJGv3XEVcLB5qleByh
# ghS8MIIUuAYKKwYBBAGCNwMDATGCFKgwghSkBgkqhkiG9w0BBwKgghSVMIIUkQIB
# AzEPMA0GCWCGSAFlAwQCAQUAMIIBdAYLKoZIhvcNAQkQAQSgggFjBIIBXzCCAVsC
# AQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQgknfM6oHhUeslMUPZ6/EN
# o4s7U6alokMbwpg0k4uX1jcCBmkDwp3AgBgTMjAyNTExMTkwMDI0MTQuNzEzWjAE
# gAIB9AIIZqWNKvac3uSggemkgeYwgeMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlv
# bnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjQ1MUEtMDVFMC1E
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
# QivRepyvWcl+JYbYbBh7pmgAXVswggefMIIFh6ADAgECAhMzAAAAVD/yAD6+odim
# AAAAAABUMA0GCSqGSIb3DQEBDAUAMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMg
# UlNBIFRpbWVzdGFtcGluZyBDQSAyMDIwMB4XDTI1MDIyNzE5NDAyN1oXDTI2MDIy
# NjE5NDAyN1owgeMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# LTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEn
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjQ1MUEtMDVFMC1EOTQ3MTUwMwYDVQQD
# EyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK7Wnnjlw596igDzQ7R0X23v
# QVa+rXKNIACd35OP+MD1C7yApSmxTQ7rAHsBF66lxk+1pAU5q7UzaWOW7rFrkPVX
# hd9ZzcCQ+yXKgCwYEI7czsnqhyHV5rXJeN0nBS10c7xk54hOQi7JGn8MRm5jdW6U
# 7lMxJbmvr+rTkO7lqMe9DcnROD09MrK03VgGzNlvauMK9rpqK/hDUJHslgi8p9Uk
# BUeeRSZc+c9WcHzNFxBHv7jNB9ZPnaIrGmyBqvF13aSXQsA3OLJ5ErAW+tPoiAhe
# ApQuQlKH9lyLF0Hp+4Deyt7V+Z9a+4UiYNfMLEql964BFUqPgDm9icr8o0SUAgc4
# itc/+XZ6Qm4PouEPK6V89uopDSzwhlOxtehq1NlzS3/ncqlcdtD1r6uqKJSYyzr3
# 4z6QX+dAOQVrW+IFtVJA7xIosC6Uf3MT8mO6dr1PhGR8GV4NJ1/BQBXg83jYeK9E
# byi7UlGfXaGIm+n3rk5b2juIBBadcmhQnMlje6STwuCknheFu6UQ/ZULYxcX20I9
# Ri3rimB0noxDUsM2e3oNjCqjBSfZu4G5KRORl+8sERCowawabgRKcJKI05gFrSV2
# Axc0+NPFxJJcJGHTWXHmeyxUAHuW3Q2loSVfxsIsqZMGnhiQX4f8xtqR2+dJu9TK
# 1kuWDSKv7DKhSMHB98I7AgMBAAGjggHLMIIBxzAdBgNVHQ4EFgQU0mk2gtuzakAQ
# FqbmgXWAbmc3XdkwHwYDVR0jBBgwFoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYD
# VR0fBGUwYzBhoF+gXYZbaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0El
# MjAyMDIwLmNybDB5BggrBgEFBQcBAQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8E
# AjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNV
# HSAEXzBdMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EM
# AQQCMA0GCSqGSIb3DQEBDAUAA4ICAQBz2BTfhlJWlQFTmpmXmIPh9DhsKMmgE6am
# JWyc42zNMXE2KbKtBQCkcHFCoLTrBORt52psHmm0LMdUqExfPLzIgP7+vtyBi03B
# UkBTr0f1EcgMHwzY/8aWCO/dx5BStip/3YzwPLHebCao/vIHNspwvxmKZPnz68Bs
# l4Gbxtes8J7hIH9mabHUY/2jJ0yMGt7164AXaAgMgziO/D8ZR6vIpptKsAcLAlW0
# B+F64oFOVf5GhVYss86hD2QN+UK0nTP3snU4+rrWZAlxwaw2OsrU8AEyb7r6Wozb
# VwTxRNITSLrlimbU+L1jRMFf3kzfa/hOAqEGARW5pN4UOU+U6nFNp+4jpri1iSlG
# kna3+QZEpRLuzu5fnMNV8gNUBh0PMk0pq6lMEKgaqrm6sB2RVuG+O/1WJQAc8pt9
# EHH/owuZD6a4Q4NhVqUZXWqwzfuS+z6oT88qcUIom9AY0WDsMjA3c4nvULS6g95F
# NQxvnJhDhqxJEVef8452wETsRlYxYE+B64UPaYWBSzJCE2Oea55PSyzeBMBtsPl1
# hglmoo3yJKWOS3EBm6wouObjfjg0oy9kebPUcUzWs+5767NE8V/BrKOulvZWyT+q
# JgmRXCiQBVgb/y/uaCC8peyx0QQuoDsJ9VhnQ5cVl9+3yrdXYhj9ltlyd9m1Tlm4
# PVwBrkoOFDGCA9QwggPQAgEBMHgwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBS
# U0EgVGltZXN0YW1waW5nIENBIDIwMjACEzMAAABUP/IAPr6h2KYAAAAAAFQwDQYJ
# YIZIAWUDBAIBBQCgggEtMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkq
# hkiG9w0BCQQxIgQg7EJI0s2HM28uavl4a2j/E5u7JUMBcj9RBgP2j4DDFRwwgd0G
# CyqGSIb3DQEJEAIvMYHNMIHKMIHHMIGgBCDUgap6YlmYSW/WIF/+rbNjJEZNLqfc
# NECo7poQmEmwCzB8MGWkYzBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBU
# aW1lc3RhbXBpbmcgQ0EgMjAyMAITMwAAAFQ/8gA+vqHYpgAAAAAAVDAiBCBm34hu
# 9OaSLrxvzq6HW8eK+x0V1zDRwdk9UN9bZWR4mzANBgkqhkiG9w0BAQsFAASCAgA0
# zDjOO7vmkHEiia92Y1lPBIFXJrh2YSHBcSgOJsUblzKsqW8JXSgngtvPKUZOQ9lJ
# rhs1Le8RY9TYcy1nhzhuCpSP02J/z+4tmo8iKcVhveH0tfUzt7Yz20N1z30w1w+l
# TxTC9ndjzoB39Cf1Kx9n5cTUnhF1UlUdCITY3oCCImneXe5JRrOQqvrW8LCovvCu
# LS5QdiCC+yJeOdtqTGx2sKYoUhV326AXOkZ7XJYWW8IOL1/AS0Yuwc8MR2PI8+im
# RAMVfrRhN0hPFROesjG0NaIETDvD1mxs/AC/EN93GBYUe14aW9Ai4nf6EYqJ2/9/
# jrMo8GjDf/Nd3rT4tTebHF09gG4zWNKXehNZXToszmd+vDUk2MdPrMr94IEIkbXg
# +yWbmS4C/qkU9b5pdl1WRGJbzhMTJFDS5WraqhWCLCMOCU5indtlNWnscYexNnwI
# n0o/E734jPr2CtyEIdMTEnLE3OEo+OSairxHrsO9rjTavbnrz1C/JQHuTS3xhOAi
# q4ZvPD62ZxwpO+aEBVIzBAE0bBl0oRMS2e3DlwlghH8OMu5Sof2wcdfeZgbQ0heC
# Fz0+Gr6m5L5dPZzcWMRC/0fXgLdtQ+p20jrUCWnuxEanWdxhImFYRe92xOnfssDC
# PfSyW+AyCKQhlB3uyaF1N0LaJwyJROmPiDsw+/r3sg==
# SIG # End signature block
