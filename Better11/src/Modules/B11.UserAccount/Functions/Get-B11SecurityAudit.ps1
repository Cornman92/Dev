function Get-B11SecurityAudit {
    [CmdletBinding()] [OutputType([PSCustomObject[]])]
    param([Parameter()] [int]$MaxEntries = 50)
    try {
        $events = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4624,4625,4634,4672,4720,4726 } -MaxEvents $MaxEntries -ErrorAction SilentlyContinue
        return @($events | ForEach-Object {
            $type = switch ($_.Id) { 4624 { 'Logon Success' } 4625 { 'Logon Failure' } 4634 { 'Logoff' } 4672 { 'Privilege Escalation' } 4720 { 'Account Created' } 4726 { 'Account Deleted' } default { "Event $($_.Id)" } }
            $account = ''; if ($_.Properties.Count -gt 5) { $account = "$($_.Properties[5].Value)" }
            [PSCustomObject]@{ Timestamp = $_.TimeCreated.ToString('o'); EventType = $type; AccountName = $account; Source = 'Security'; EventId = $_.Id; Result = if ($_.Id -eq 4625) { 'Failure' } else { 'Success' } }
        })
    } catch { return @() }
}
