# 🎨 GaymerPC Customization Guide**Complete Guide to Personalizing Your
GaymerPC Experience**---

## Table of Contents

1. Overview

2. Quick Start

3. User Profiles

4. Themes & Visual Customization

5. Workflows & Shortcuts

6. Preferences & Behavior

7. Branding & Identity

8. AI Assistant Personalization

9. Advanced Features

10. Troubleshooting

11. Migration Guide

12. API Reference

---

## Overview

The GaymerPC Customization System provides comprehensive personalization
across all 15+ suites, allowing you to:

- 🎨**Customize Visual Themes**- Choose from pre-built themes or create your own

- 👤**Manage User Profiles**- Switch between different user configurations

- ⌨️**Define Custom Shortcuts**- Create personalized keyboard shortcuts

- 🔧**Build Workflows**- Automate complex sequences of actions

- 🎯**Set Behavioral Preferences**- Configure how the system behaves

- 🎭**Personalize Branding**- Customize logos, splash screens, and identity

- 🤖**Configure AI Assistant**- Set wake words, personality, and voice

---

## Quick Start

### 1. Launch Customization Manager**GUI Version (Recommended for beginners):**```powershell

## Navigate to GaymerPC directory

cd "D:\OneDrive\C-Man\Dev\GaymerPC"

## Launch GUI

.\Core\Config\customization\Customization-Manager-GUI.ps1

```text**TUI Version (For advanced users):**```powershell

## Launch TUI

python .\Core\Config\customization\customization_tui.py

```text

### 2. Create Your First Profile

1. Open the**Profiles**tab
2. Click**Create New Profile**3. Fill in your information:

- Name: `Connor O`- Alias:`C-Man`- Email:`<Saymoner88@gmail.com>`- Profile
  - Type:`Gaming Developer`### 3. Apply a Theme

1. Go to the**Themes**tab
2. Select a theme (e.g.,`Gaming RGB`)
3. Click**Apply Theme**4. See the changes immediately

### 4. Set Up Shortcuts

1. Navigate to the**Shortcuts**tab
2. Click**Create Shortcut**3. Define your shortcut:

- Name:`Start Gaming Session`- Key Combination:`Ctrl+Alt+G`- Action:`Launch
  - Gaming Suite`---

## User Profiles

### Creating Profiles

User profiles store all your personalization settings. You can create
multiple profiles for different use cases:

```json

{
  "user_id": "connor_o",
  "name": "Connor O",
  "alias": "C-Man",
  "email": "<Saymoner88@gmail.com>",
  "profile_type": "gaming_developer",
  "theme": "gaming_rgb",
  "performance_mode": "gaming",
  "auto_start_suites": ["Gaming-Suite", "AI-Command-Center"]
}

```text

### Profile Types

-**Gaming**- Optimized for gaming performance

-**Development**- Configured for coding and development

-**Streaming**- Set up for content creation and streaming

-**Gaming Developer**- Hybrid profile for both gaming and development

-**Custom**- Fully customizable profile

### Switching Profiles**Via GUI:**1. Open Customization Manager

1. Go to Profiles tab
2. Select desired profile
3. Click**Switch Profile**

**Via Command Line:**```powershell

## Switch to gaming profile

Apply-Customization -UserId "connor_gaming"

## Switch to development profile

Apply-Customization -UserId "connor_dev"

```text

---

## Themes & Visual Customization

### Built-in Themes

#### 🎮 Gaming RGB Theme

-**Colors**: Cyan, Magenta, Yellow

-**Style**: Vibrant, high-contrast

-**Best for**: Gaming sessions, RGB setups

#### 💻 Developer Pro Theme

-**Colors**: Blue, Dark Gray, Green accents

-**Style**: Professional, clean

-**Best for**: Coding, development work

#### ⚡ Minimal Zen Theme

-**Colors**: Grayscale, subtle accents

-**Style**: Clean, minimal

-**Best for**: Focus, productivity

#### 🚀 High Performance Theme

-**Colors**: Green, Black, High contrast

-**Style**: Terminal-like, performance-focused

-**Best for**: System monitoring, performance testing

#### 🎨 Connor's Custom Theme

-**Colors**: Orange, Blue, Green

-**Style**: Personalized gaming + development

-**Best for**: Connor's personal use

### Creating Custom Themes

1.**Copy an existing theme:**```bash
   cp GaymerPC/Core/Config/customization/themes/gaming_rgb.json my_custom_theme.json
   ```

2.**Edit the theme file:**```json
   {
     "name": "My Custom Theme",
     "description": "My personalized theme",
     "colors": {
       "primary": "#ff6600",
       "secondary": "#0066ff",
       "accent": "#00ff66",
       "background": "#0d1117",
       "surface": "#161b22",
       "text": "#f0f6fc"
     }
   }

```json

3.**Register the theme:**```python
from GaymerPC.Core.Config.customization.customization_manager import
  CustomizationManager

   manager = CustomizationManager()
   manager.register_theme("my_custom", theme_data)
   ```### Theme Components

Each theme includes:

-**Color Palette**- Primary, secondary, accent colors

-**Typography**- Font families and sizes

-**Layout**- Spacing, borders, alignment

-**Visual Elements**- Icons, splash screens

-**CSS Styles**- Custom styling for components

---

## Workflows & Shortcuts

### Creating Workflows

Workflows automate sequences of actions. Example workflow for starting a
gaming session:

```json

{
  "name": "Gaming Session Start",
  "description": "Optimizes system for gaming and launches apps",
  "steps": [
    {
      "action": "system_optimization",
      "params": {"mode": "gaming_performance"}
    },
    {
      "action": "launch_application",
      "params": {"app_name": "Steam"}
    },
    {
      "action": "launch_application",
      "params": {"app_name": "Discord"}
    },
    {
      "action": "set_theme",
      "params": {"theme_name": "gaming_rgb"}
    }
  ]
}

```text

### Built-in Workflows

-**Gaming Session Start**- Optimize for gaming

-**Development Session Start**- Set up dev environment

-**Streaming Session Start**- Prepare for streaming

-**Daily System Maintenance**- Run maintenance tasks

### Keyboard Shortcuts

#### Global Shortcuts

- `Ctrl+Alt+G`- Start gaming session

-`Ctrl+Alt+D`- Start development session

-`Ctrl+Alt+S`- Start streaming session

-`Ctrl+Alt+M`- Run system maintenance

-`Ctrl+Alt+T`- Switch theme

-`Ctrl+Alt+P`- Switch profile

-`Ctrl+Alt+C`- Open customization manager

#### Suite-Specific Shortcuts

-`Ctrl+Alt+B`- Run benchmarks (Gaming Suite)

-`Ctrl+Alt+R`- Run application (Development Suite)

-`Ctrl+Alt+O`- Optimize system (Performance Suite)

### Creating Custom Shortcuts

1. Open Customization Manager
2. Go to Shortcuts tab
3. Click**Create Shortcut**4. Define:

  -**Name**: Descriptive name
  -**Key Combination**: Keyboard shortcut
  -**Action**: What it does
  -**Suite**: Which suite it belongs to

---

## Preferences & Behavior

### Behavioral Preferences

Control how the system behaves:

```json

{
  "auto_system_optimization": {
    "enabled": true,
    "mode": "aggressive",
    "schedule": "idle_time"
  },
  "notification_settings": {
    "level": "minimal",
    "gaming_alerts": false,
    "dev_alerts": true
  },
  "power_management": {
    "gaming_power_plan": "ultimate_performance",
    "dev_power_plan": "balanced"
  }
}

```text

### Integration Preferences

Configure how suites integrate with each other:

```json

{
  "cloud_integration": {
    "enabled": true,
    "provider": "OneDrive",
    "auto_sync_paths": ["D:\\OneDrive\\C-Man\\Dev"]
  },
  "ai_assistant_integration": {
    "enabled": true,
    "default_ai_model": "cman_ai_v2",
    "voice_commands_enabled": true
  },
  "gaming_platform_integration": {
    "steam_api_key": "YOUR_STEAM_API_KEY",
    "auto_launch_on_game_start": true
  }
}

```text

---

## Branding & Identity

### Custom Branding

Personalize your GaymerPC experience:

```json

{
  "workspace_branding": {
    "name": "GaymerPC",
    "full_name": "GaymerPC Ultimate Gaming Suite",
    "tagline": "Connor O (C-Man)'s Ultimate Gaming PC",
    "author": "Connor O (C-Man)",
    "email": "<Saymoner88@gmail.com>"
  },
  "visual_identity": {
    "logo": "🎮",
    "primary_logo": "🎮",
    "secondary_logo": "⚡",
    "accent_logo": "🚀"
  }
}

```text

### ASCII Art Customization

Customize ASCII art banners:

```json

{
  "ascii_art": {
    "gaymerpc": {
      "main": [
        " ██████╗  █████╗ ██╗   ██╗███╗   ███╗███████╗██████╗ ██████╗ ██████╗ ",
        "██╔════╝ ██╔══██╗╚██╗ ██╔╝████╗ ████║██╔════╝██╔══██╗██╔══██╗██╔══██╗"
      ]
    }
  }
}

```text

### Splash Screens

Configure startup and shutdown screens:

```json

{
  "splash_screens": {
    "startup": {
      "enabled": true,
      "duration": 3,
      "animation": "fade",
      "background": "#0d1117",
      "text_color": "#f0f6fc"
    }
  }
}

```text

---

## AI Assistant Personalization

### Wake Words

Set custom wake words for voice activation:

```json

{
  "ai_assistant": {
    "wake_word": "Hey C-Man",
    "personality": "Helpful, gaming-focused, witty",
    "voice": "male_energetic",
    "response_style": "casual_professional"
  }
}

```text

### Available Personalities

-**Gaming-Focused**- Optimized for gaming help

-**Developer-Friendly**- Technical and precise

-**Casual**- Relaxed and friendly

-**Professional**- Formal and business-like

-**Witty**- Humorous and entertaining

### Voice Options

-**Male Energetic**- High energy, gaming-focused

-**Female Calm**- Professional, development-focused

-**Neutral**- Balanced for all activities

---

## Advanced Features

### Time-Based Themes

Automatically switch themes based on time of day:

```json

{
  "advanced_features": {
    "time_based_theme": true,
    "theme_schedule": {
      "06:00-12:00": "minimal_zen",
      "12:00-18:00": "developer_pro",
      "18:00-24:00": "gaming_rgb"
    }
  }
}

```text

### Activity-Based Switching

Change themes based on detected activity:

```json

{
  "activity_based_theme": {
    "enabled": true,
    "triggers": {
      "game_detected": "gaming_rgb",
      "ide_opened": "developer_pro",
      "streaming_started": "high_performance"
    }
  }
}

```text

### Performance Adaptation

Adjust visual complexity based on system load:

```json

{
  "performance_adaptation": {
    "enabled": true,
    "thresholds": {
      "cpu_usage": 70,
      "ram_usage": 80
    },
    "low_performance_theme": "minimal_zen"
  }
}

```text

---

## Troubleshooting

### Common Issues

#### Theme Not Applying

1. Check theme file syntax in JSON
2. Verify theme is registered in theme_registry.json
3. Restart the application after theme changes

#### Shortcuts Not Working

1. Ensure no conflicts with system shortcuts
2. Check that the target application is running
3. Verify shortcut syntax in workflow definitions

#### Profile Switch Fails

1. Check profile JSON syntax
2. Verify all referenced themes exist
3. Check file permissions on profile directory

### Reset to Defaults

```powershell

## Reset all customizations

Reset-Customization -Force

## Reset specific component

Reset-Customization -Component "themes" -Force

```text

### Backup & Restore

```powershell

## Create backup

Backup-Customization -Path "C:\Backups\gaymerpc_customization_$(Get-Date
-Format 'yyyyMMdd').zip"

## Restore from backup

Restore-Customization -Path "C:\Backups\gaymerpc_customization_20240115.zip"

```text

---

## Migration Guide

### Migrating from Existing Configs

If you have existing GaymerPC configurations, use the migration system:

```powershell

## Run migration

python .\Core\Config\customization\migrate_existing_configs.py

```text

The migration system will:

1. Backup your existing configurations
2. Convert them to the new format
3. Create your initial user profile
4. Generate a migration report

### Migration Checklist

- [ ] Backup existing configurations

- [ ] Run migration script

- [ ] Review migration report

- [ ] Test all themes and profiles

- [ ] Verify shortcuts work correctly

- [ ] Check suite integrations

- [ ] Remove backup files after verification

---

## API Reference

### CustomizationManager Class

```python

from GaymerPC.Core.Config.customization.customization_manager import
CustomizationManager

## Initialize

manager = CustomizationManager()

## Get user profile

profile = manager.get_user_profile("connor_o")

## Set user profile

manager.set_user_profile("connor_o", profile_data)

## Get theme

theme = manager.get_theme("gaming_rgb")

## Register theme

manager.register_theme("custom_theme", theme_data)

## Apply customization

manager.apply_customization("connor_o")

```text

### PowerShell Module

```powershell

## Import module

Import-Module .\Core\Config\customization\customization_manager.psm1

## Get user profile (2)

$profile = Get-UserProfile -UserId "connor_o"

## Set user profile (2)

Set-UserProfile -UserId "connor_o" -ProfileData $profile

## Get theme (2)

$theme = Get-Theme -ThemeName "gaming_rgb"

## Apply customization (2)

Apply-Customization -UserId "connor_o"

```text

### UI Component Library

```python

from GaymerPC.Core.Config.customization.components.ui_components import
UIComponentLibrary

## Initialize (2)

library = UIComponentLibrary()

## Create components

header = library.create_header(ComponentConfig("header", "My App"))
button = library.create_button(ComponentConfig("button", "Click Me"))
theme_css = library.get_theme_css("gaming_rgb")

```text

---

## Support

### Getting Help

1.**Check this guide**- Most questions are answered here
2.**Review migration report**- If you migrated from existing configs
3.**Check logs**- Look in ` GaymerPC/Core/Logs/` for error details
4.**Community support**- Join the GaymerPC community forums

### Reporting Issues

When reporting issues, include:

- Your profile configuration

- Theme being used

- Steps to reproduce

- Error messages from logs

- System information

### Contributing

Want to contribute themes, workflows, or improvements

1. Fork the repository
2. Create your customizations
3. Test thoroughly
4. Submit a pull request

---
**Happy Customizing! 🎨**

* GaymerPC Customization System v1.0.0 - Created for Connor O (C-Man)*
