# Cyberpunk Bladerunner Theme Guide for GayMR-PC


## Overview

The Cyberpunk Bladerunner theme transforms the entire GayMR-PC system into an
  immersive cyberpunk environment inspired by classic Bladerunner aesthetics,
  Cyberpunk 2077 styling, and retro terminal aesthetics
This guide covers all aspects of the theme implementation, customization,
  and usage.


## Color Palette Reference


### Primary Colors


- **Background**: `#0a0e27 `- Deep noir blue-black (main screen background)

-**Surface**:`#1a1f3a`- Dark blue-grey (panel backgrounds)

-**Neon Cyan**:`#00ffff`- Holographic blue (primary text and borders)

-**Neon Magenta**:`#ff006e`- Hot pink (secondary accents)

-**Neon Yellow**:`#fffc00`- Electric yellow (highlights and warnings)

-**Neon Red**:`#ff073a`- Warning red (errors and alerts)

-**Neon Green**:`#39ff14`- Matrix green (success states)

-**Purple Haze**:`#bd00ff`- Violet accent (special effects)


### Text Colors

-**Primary Text**:`#e0f7ff`- Bright cyan-white (main text)

-**Secondary Text**:`#8b9fde`- Muted blue-grey (subtle text)

-**Highlight**:`#00ffff`- Cyan glow (emphasized text)


## Windows Terminal Configuration


### Color Scheme

The theme includes a complete "Cyberpunk Bladerunner" color scheme with:


- Deep noir background (`#0a0e27`)


- Neon cyan foreground (`#00ffff`)


- Custom ANSI color mappings for all 16 colors


- Glowing cyan cursor (`#00ffff`)


- CRT scanline effects enabled


### Setup

Run the Windows Terminal configuration script:


```powershell

.\GaymerPC\Scripts\Set-WindowsTerminal.ps1


```text

This will:


- Create a backup of existing settings


- Add the Cyberpunk Bladerunner color scheme


- Set it as the default theme


- Enable acrylic transparency and CRT effects


## PowerShell TUI Themes


### Theme Configuration

All PowerShell TUI scripts include a "Cyberpunk" theme with the following
color mappings:


```powershell

Cyberpunk = @{
    Primary = 'Cyan'           # Neon cyan for headers

    Secondary = 'Magenta'      # Hot pink for accents

    Accent = 'Yellow'          # Electric yellow highlights

    Warning = 'Red'            # Neon red warnings

    Error = 'Red'              # Critical errors

    Success = 'Green'          # Matrix green success

    Info = 'Blue'              # Cool blue info

    Header = 'Cyan'            # Bright cyan headers

    Background = 'Black'       # Deep noir

    Border = 'Cyan'            # Neon borders

    MenuBg = 'DarkBlue'        # Dark surface

    MenuFg = 'Cyan'            # Neon text

    Title = 'â–“â–’â–‘ GAYMR-PC âš¡ CYBERDECK â–‘â–’â–“'
}


```text


### Usage

To use the cyberpunk theme in PowerShell scripts:


```powershell

$script:Theme = 'Cyberpunk'


```text


## Python Textual Applications


### CSS Styling

The theme includes comprehensive CSS styling for all Textual components:


#### Core Screen Styling


```css

Screen {
    background: #0a0e27;

    color: #00ffff;

}

Header {
    background: #1a1f3a;

    color: #00ffff;

    border-bottom: solid #00ffff;

}

Footer {
    background: #1a1f3a;

    color: #8b9fde;

    border-top: solid #00ffff;

}


```text


#### Interactive Elements


```css

Button {
    background: #1a1f3a;

    color: #00ffff;

    border: solid #00ffff;

}

Button:hover {
    background: #00ffff;

    color: #0a0e27;

    text-style: bold;
}


```text


### Theme Integration

To use the cyberpunk theme in Python TUIs:


```python

from gaymerpc_tui import GaymerPCTUI


## Create TUI with cyberpunk theme

app = GaymerPCTUI(theme='Cyberpunk')
app.run()


```text


## ASCII Art Library


### Main Components


#### System Banner


```python

from cyberpunk_art import CyberpunkArt

art = CyberpunkArt()
banner = art.get_main_banner(width=80)
print(banner)


```text


#### Loading Indicators


```python


## Progress bar with cyberpunk styling

loading_bar = art.get_loading_bar(progress=75, width=40)


## Animated loading spinner

spinner = art.get_animated_loading(frame=0)


```text


### Status Icons


- `âš¡`- Power/Active

-`â—‰`- Online/Connected

-`âš `- Warning/Alert

-`âœ•`- Error/Critical

-`â—ˆ`- Secure/Encrypted

-`â—¢â—£â—¤â—¥`- Processing animation

-`â–“â–’â–‘`- Loading gradient


### Box-Drawing Characters

-`â•”â•â•—â•šâ•â•â•‘`- Double-line borders

-`â”Œâ”€â”â””â”€â”˜â”‚`- Single-line borders

-`â–“â–’â–‘`- Gradient/loading effects

-`â—¢â—£â—¤â—¥`- Animated indicators


## Visual Effects


### PowerShell Effects


#### Glitch Text


```powershell

Import-Module .\cyberpunk_effects.ps1


## Basic glitch effect

$glitchText = Get-GlitchText -Text "GAYMR-PC" -Intensity 3


## Animated glitch

Show-GlitchAnimation -Text "SYSTEM ONLINE" -Duration 3


```text


### Neon Styling


```powershell


## Neon text with glow

Write-NeonText -Text "CYBERDECK ACTIVE" -Color 'Cyan' -Bold


## Neon bordered content

Write-NeonBorder -Text "NEURAL INTERFACE" -Color 'Cyan'


## Progress bar with neon styling

Write-NeonProgress -Current 75 -Total 100 -Color 'Cyan'


```text


### Animations


```powershell


## Loading spinner

Show-LoadingSpinner -Message "Initializing Neural Link" -Duration 5


## Typing animation

Show-TypingAnimation -Text "Welcome to the Cyberdeck" -Speed 50


## Pulsing text

Show-PulsingText -Text "SYSTEM ONLINE" -Duration 3


```text


### Python Effects


#### CSS Animations

The cyberpunk theme includes hover effects, transitions, and glow simulations:


```css

.cyberpunk-button:hover {
    background: #00ffff;

    color: #0a0e27;

    text-style: bold;
}

.neon-glow {
    color: #00ffff;

    text-style: bold;
}


```text


## Customization Guide


### Color Customization


#### Windows Terminal

Edit `GaymerPC\Scripts\Set-WindowsTerminal.ps1`and modify the color scheme:


```powershell

@{
    "name" = "Custom Cyberpunk"
    "background" = "#your_color"

    "foreground" = "#your_color"

    # ... other colors

}


```text


#### PowerShell Themes

Modify the theme dictionary in your TUI script:


```powershell

CustomCyberpunk = @{
    Primary = 'YourColor'
    Secondary = 'YourColor'
    # ... other properties

}


```text


#### Python CSS

Create custom CSS classes:


```css

.custom-cyberpunk-panel {
    background: #your_color;

    border: solid #your_color;

    color: #your_color;

}


```text


### ASCII Art Customization


#### Adding New Banners


```python

def get_custom_banner(self, width: int = 80) -> str:
    return f"""
    â•”{'â•'*(width-4)}â•—
    â•‘  YOUR CUSTOM BANNER HERE  â•‘
    â•š{'â•'*(width-4)}â•
    """


```text


#### Custom Status Icons


```python

def get_custom_icons(self) -> Dict[str, str]:
    return {
        "custom_status": "ðŸ”®",
        "another_status": "âš¡",
    }


```text


## Performance Considerations


### Visual Effects


- Glitch effects use minimal CPU but may impact text rendering


- Animations are optimized for 60fps terminal displays


- CRT effects are hardware-accelerated when available


### Memory Usage


- ASCII art is cached for performance


- CSS is compiled once and reused


- Theme configurations are lightweight


### Compatibility


- Windows Terminal 1.15+ required for full effects


- PowerShell 7.0+ for advanced features


- Python 3.8+ for Textual applications


## Troubleshooting


### Common Issues


#### Colors Not Displaying


- Ensure Windows Terminal is up to date


- Check that the color scheme is properly configured


- Verify PowerShell version compatibility


#### ASCII Art Rendering


- Check terminal font supports Unicode box-drawing characters


- Ensure terminal width is sufficient for banners


- Verify encoding is set to UTF-8


#### CSS Not Applied


- Confirm Textual version is 0.40.0+


- Check CSS syntax is valid


- Verify theme is properly loaded


### Debug Mode

Enable debug mode for detailed logging:


```powershell

.\Show-GaymerPCTUI.ps1 -LogLevel Debug


```text


## Examples


### Complete Setup Example


```powershell


## 1. Configure Windows Terminal

.\GaymerPC\Scripts\Set-WindowsTerminal.ps1


## 2. Import cyberpunk effects

Import-Module .\cyberpunk_effects.ps1


## 3. Set theme and show welcome

Set-CyberpunkTheme
Show-CyberpunkWelcome -UserName "Connor"


## 4. Launch TUI with cyberpunk theme

.\Show-GaymerPCTUI.ps1 -Theme Cyberpunk


```text


### Python TUI Example


```python

from gaymerpc_tui import GaymerPCTUI
from cyberpunk_art import get_cyberpunk_banner


## Show banner

print(get_cyberpunk_banner(width=80))


## Launch TUI

app = GaymerPCTUI(theme='Cyberpunk')
app.run()


```text


## Advanced Features


### Glitch Effects


- Unicode combining characters for corruption


- Random character substitution


- Intensity levels (1-5)


- Animated glitch sequences


### Neon Glow Simulation


- Multiple character layering


- Color intensity variations


- Hover state enhancements


- Pulsing animations


### CRT Effects


- Scanline overlays


- Screen curvature simulation


- Phosphor glow effects


- Retro terminal aesthetics


## File Structure


```text

GaymerPC/
â”œâ”€â”€ Scripts/
â”‚   â””â”€â”€ Set-WindowsTerminal.ps1          # Windows Terminal config

â”œâ”€â”€ apps/Shared/GaymerPC-Shared/shared/
â”‚   â”œâ”€â”€ cyberpunk_art.py                 # ASCII art library

â”‚   â”œâ”€â”€ cyberpunk_theme.tcss            # Textual CSS theme

â”‚   â”œâ”€â”€ cyberpunk_effects.ps1           # PowerShell effects

â”‚   â”œâ”€â”€ tui_components.py               # Updated TUI components

â”‚   â””â”€â”€ scripts/utilities/
â”‚       â””â”€â”€ gaymerpc_tui.py             # Main TUI with cyberpunk theme

â”œâ”€â”€ Gaming-Suite/TUI/
â”‚   â””â”€â”€ gaymerpc_suite_tui.py           # Gaming suite with cyberpunk CSS

â””â”€â”€ Docs/
    â””â”€â”€ Cyberpunk-Theme-Guide.md        # This documentation


```text


## Support

For issues, feature requests, or customization help:


- Check the troubleshooting section above


- Review the example implementations


- Examine the source code for reference implementations


- Test changes in a development environment first


## Version History

-**v3.0.0**- Initial cyberpunk theme implementation

  - Windows Terminal color scheme
  - PowerShell TUI themes
  - Python Textual CSS styling
  - ASCII art library
  - Visual effects library
  - Comprehensive documentation

---


* Welcome to the cyberdeck. The future is now.*

