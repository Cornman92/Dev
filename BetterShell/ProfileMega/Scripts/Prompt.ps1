#Requires -Version 7.0
# Enhanced prompt for ProfileMega (dot-sourced by root module)
# Only defines prompt when PromptDriver is 'ProfileMega' or 'None'; otherwise base profile or init script owns prompt.

$driver = $Global:ProfileConfig.PromptDriver
if ($driver -eq 'ProfileMega' -or $driver -eq 'None') {
    function prompt {
        $location = Get-Location
        $shortPath = $location.Path -replace [regex]::Escape($HOME), "~"

        # Admin indicator
        $isAdmin = $false
        try {
            $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        } catch { }
        $adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }

        # Window title
        $title = "PowerShell $($PSVersionTable.PSVersion)$adminSuffix"
        if ($location.Path) { $title += " - $shortPath" }
        $Host.UI.RawUI.WindowTitle = $title

        if ($driver -eq 'None') {
            return "[$shortPath]$adminSuffix> "
        }

        $gitBranch = ""
        $gitDirty = ""
        if (Test-Path .git) {
            $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
            $gitStatus = git status --porcelain 2>$null
            if ($gitStatus) { $gitDirty = "*" }
        }

        $agentStatus = ""
        if ($Global:AgentOrchestrator) {
            $runningAgents = ($Global:AgentOrchestrator.Agents.Values | Where-Object { $_.State -eq 'Running' }).Count
            if ($runningAgents -gt 0) { $agentStatus = " [Agents:$runningAgents]" }
        }

        $gray = if ($PSStyle) { $PSStyle.Foreground.DarkGray } else { "" }
        $green = if ($PSStyle) { $PSStyle.Foreground.Green } else { "" }
        $cyan = if ($PSStyle) { $PSStyle.Foreground.Cyan } else { "" }
        $yellow = if ($PSStyle) { $PSStyle.Foreground.Yellow } else { "" }
        $red = if ($PSStyle) { $PSStyle.Foreground.Red } else { "" }
        $blue = if ($PSStyle) { $PSStyle.Foreground.Blue } else { "" }
        $magenta = if ($PSStyle) { $PSStyle.Foreground.Magenta } else { "" }
        $reset = if ($PSStyle) { $PSStyle.Reset } else { "" }

        $line1 = "`n$gray[${green}$env:USERNAME${gray}@${cyan}$env:COMPUTERNAME${gray}]$adminSuffix"
        if ($gitBranch) { $line1 += "${gray} [${yellow}$gitBranch${red}$gitDirty${gray}]" }
        $line1 += "$magenta$agentStatus$reset"
        $line2 = "$gray[$blue$shortPath${gray}]${green}❯ $reset"
        return $line1 + "`n" + $line2
    }
}
