# Copyright (c) 2025 Code Copilot
# License: MIT
@{
  General = @{
    Editor='code'; UseColor=$true; UseTranscripts=$false; TranscriptsPath="$HOME/.powerlog"
    QuietProgress=$true; ErrorView='ConciseView'; MaximumHistoryCount=5000; HistorySavePath=$null
    LocalBins=@('~/.local/bin','~/bin'); SafeRemove=$true; CacheTtlSeconds=3
  }
  Prompt = @{
    ShowTime=$true; ShowUserHost=$true; ShowGit=$true; ShowVenv=$true; ShowKube=$true; ShowDocker=$true; ShowExitCode=$true; CompactPath=$true
    Symbols=@{ Admin='#'; User='$'; Git='git'; Dirty='*'; Venv='py'; Conda='conda'; Kube='⎈'; Docker='🐳'; Time='⏱'; Ok='✓'; Fail='✗' }
  }
  Integrations = @{
    UsePoshGit=$true
    UseOhMyPosh=$true; OhMyPoshThemePath="$ThemePath"
    UseZoxide=$true; UseRipgrep=$true; UseFd=$true; UseBat=$true
    UseFzf=$true; Fzf=@{ BindCtrlR=$true; BindCtrlT=$true; BindAltC=$true; BindAltB=$true; BindCtrlF=$true; BindAltT=$true }
}
}
