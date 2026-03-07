function Get-AppCatalog {
  @{
    Essentials = @(
      "Microsoft.WindowsTerminal",
      "Microsoft.PowerToys",
      "7zip.7zip"
    )
    DevCore = @(
      "Microsoft.VisualStudioCode",
      "Git.Git"
    )
    AITools = @(
      "Anthropic.Claude"
    )
    GameLaunchers = @(
      "Valve.Steam",
      "EpicGames.EpicGamesLauncher"
    )
    Productivity = @(
      "Discord.Discord",
      "Obsidian.Obsidian"
    )
  }
}
function Get-AppId($i){ if($i -is [hashtable]){$i.Id}else{$i} }
