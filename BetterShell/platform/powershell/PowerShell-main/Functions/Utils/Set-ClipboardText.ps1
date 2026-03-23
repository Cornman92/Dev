function Set-ClipboardText {
    [CmdletBinding()]
    param([string]$Text)

    Set-Clipboard -Value $Text
}
