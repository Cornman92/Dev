<#
.SYNOPSIS
    Sends notifications via toast, email, or webhook.

.DESCRIPTION
    Provides a unified notification interface for other scripts. Supports
    Windows toast notifications (BurntToast or native), email via SMTP,
    and Discord/Slack webhooks. Designed to be dot-sourced or called by
    other automation scripts.

.PARAMETER Title
    Notification title/subject.

.PARAMETER Message
    Notification body text.

.PARAMETER Type
    Notification channel: Toast, Email, Discord, Slack. Defaults to Toast.

.PARAMETER WebhookUrl
    Webhook URL for Discord or Slack notifications.

.PARAMETER SmtpServer
    SMTP server for email notifications.

.PARAMETER SmtpPort
    SMTP port. Defaults to 587.

.PARAMETER To
    Email recipient address(es).

.PARAMETER From
    Email sender address.

.PARAMETER Credential
    PSCredential for SMTP authentication.

.EXAMPLE
    .\Send-Notification.ps1 -Title "Backup Complete" -Message "All jobs finished successfully."
    Shows a Windows toast notification.

.EXAMPLE
    .\Send-Notification.ps1 -Type Discord -Title "Deploy" -Message "Build complete" -WebhookUrl "https://discord.com/api/webhooks/..."
    Sends a Discord webhook notification.

.EXAMPLE
    .\Send-Notification.ps1 -Type Email -Title "Health Alert" -Message "Disk 90% full" -To "admin@example.com" -SmtpServer "smtp.example.com"
    Sends an email notification.

.NOTES
    Author: C-Man
    Date:   2026-03-23
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Title,

    [Parameter(Mandatory, Position = 1)]
    [string]$Message,

    [Parameter()]
    [ValidateSet('Toast', 'Email', 'Discord', 'Slack')]
    [string]$Type = 'Toast',

    [Parameter()]
    [string]$WebhookUrl,

    [Parameter()]
    [string]$SmtpServer,

    [Parameter()]
    [int]$SmtpPort = 587,

    [Parameter()]
    [string[]]$To,

    [Parameter()]
    [string]$From,

    [Parameter()]
    [pscredential]$Credential
)

$ErrorActionPreference = 'Stop'

switch ($Type) {
    'Toast' {
        # Try BurntToast module first, fall back to native
        $hasBurntToast = Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue

        if ($hasBurntToast) {
            Import-Module BurntToast -ErrorAction SilentlyContinue
            New-BurntToastNotification -Text $Title, $Message
            Write-Host "  [TOAST] Notification sent via BurntToast" -ForegroundColor Green
        }
        else {
            # Native Windows toast via .NET
            try {
                [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

                $template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$([System.Security.SecurityElement]::Escape($Title))</text>
            <text>$([System.Security.SecurityElement]::Escape($Message))</text>
        </binding>
    </visual>
</toast>
"@

                $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                $xml.LoadXml($template)
                $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
                $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
                [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
                Write-Host "  [TOAST] Notification sent via native API" -ForegroundColor Green
            }
            catch {
                # Fallback: simple balloon notification via NotifyIcon
                Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
                $notify = New-Object System.Windows.Forms.NotifyIcon
                $notify.Icon = [System.Drawing.SystemIcons]::Information
                $notify.BalloonTipTitle = $Title
                $notify.BalloonTipText = $Message
                $notify.Visible = $true
                $notify.ShowBalloonTip(5000)

                # Clean up after a delay
                Start-Sleep -Seconds 6
                $notify.Dispose()
                Write-Host "  [TOAST] Notification sent via balloon tip" -ForegroundColor Green
            }
        }
    }

    'Email' {
        if (-not $SmtpServer) {
            Write-Error "SMTP server required for email notifications. Use -SmtpServer."
        }
        if (-not $To) {
            Write-Error "Recipient address required. Use -To."
        }
        if (-not $From) {
            $From = "$env:USERNAME@$env:COMPUTERNAME"
        }

        $mailParams = @{
            From       = $From
            To         = $To
            Subject    = $Title
            Body       = $Message
            SmtpServer = $SmtpServer
            Port       = $SmtpPort
            UseSsl     = $true
        }

        if ($Credential) {
            $mailParams['Credential'] = $Credential
        }

        Send-MailMessage @mailParams
        Write-Host "  [EMAIL] Notification sent to: $($To -join ', ')" -ForegroundColor Green
    }

    'Discord' {
        if (-not $WebhookUrl) {
            Write-Error "Webhook URL required for Discord notifications. Use -WebhookUrl."
        }

        $payload = @{
            embeds = @(
                @{
                    title       = $Title
                    description = $Message
                    color       = 3447003  # Blue
                    timestamp   = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
                    footer      = @{
                        text = "$env:COMPUTERNAME"
                    }
                }
            )
        } | ConvertTo-Json -Depth 5

        $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType 'application/json'
        Write-Host "  [DISCORD] Notification sent" -ForegroundColor Green
    }

    'Slack' {
        if (-not $WebhookUrl) {
            Write-Error "Webhook URL required for Slack notifications. Use -WebhookUrl."
        }

        $payload = @{
            blocks = @(
                @{
                    type = 'header'
                    text = @{
                        type = 'plain_text'
                        text = $Title
                    }
                }
                @{
                    type = 'section'
                    text = @{
                        type = 'mrkdwn'
                        text = $Message
                    }
                }
                @{
                    type = 'context'
                    elements = @(
                        @{
                            type = 'mrkdwn'
                            text = "From: $env:COMPUTERNAME | $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
                        }
                    )
                }
            )
        } | ConvertTo-Json -Depth 6

        $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType 'application/json'
        Write-Host "  [SLACK] Notification sent" -ForegroundColor Green
    }
}
