# Better11 UI Style Guide

## Design Philosophy

Better11 uses a **dense, dark, WinUtil-inspired** UI aesthetic. Think Chris Titus Tech's WinUtil — compact checkbox grids, minimal whitespace, information-dense layouts with a terminal/hacker feel.

## Color Palette

### Dark Theme (Primary)

| Token | Hex | Usage |
|---|---|---|
| `B11PrimaryBackground` | `#111111` | Page backgrounds, main content area |
| `B11SecondaryBackground` | `#1A1A1A` | Navigation pane, sidebars |
| `B11TertiaryBackground` | `#222222` | Elevated surfaces |
| `B11CardBackground` | `#1E1E1E` | Cards, panels, grouped content |
| `B11AccentColor` | `#0078D4` | Accent buttons, active items, links, section headers |
| `B11TextPrimary` | `#EEEEEE` | Primary text, values, headings |
| `B11TextSecondary` | `#AAAAAA` | Labels, descriptions |
| `B11TextTertiary` | `#777777` | Hints, timestamps, captions |
| `B11BorderDefault` | `#333333` | Card borders, dividers |
| `B11SuccessColor` | `#2EA043` | Success indicators, enabled states |
| `B11WarningColor` | `#D29922` | Warning indicators |
| `B11ErrorColor` | `#F85149` | Error indicators, critical states |
| `B11InfoColor` | `#58A6FF` | Info indicators, links |

## Typography

| Size | Token | Usage |
|---|---|---|
| 11px | `B11FontSizeCaption` | Captions, timestamps, secondary labels |
| 13px | `B11FontSizeBody` | Body text, list items, descriptions |
| 16px | `B11FontSizeSubtitle` | Section headers |
| 20px | `B11FontSizeTitle` | Page titles |
| 28px | `B11FontSizeHeader` | Hero headers (rare) |
| Mono | `Cascadia Code, Consolas` | Console output, code, paths |

## Dense Layout Rules

- **Row height:** 24px standard, 20px compact
- **Card padding:** 10px horizontal, 8px vertical
- **Section spacing:** 12px between sections
- **Item spacing:** 4px between items within a section
- **Page margin:** 16px all sides (reduced from default 24px)
- **Button height:** 28px (reduced from default 32px)
- **Corner radius:** 4px cards, 2px buttons

## Component Patterns

### Section Header
```xml
<TextBlock Text="Section Name" Style="{StaticResource B11SectionHeaderStyle}"/>
```
Accent-colored, 16px, SemiBold. Always used before a group of related content.

### Dense Card
```xml
<Border Style="{StaticResource B11DenseCardStyle}">
    <!-- Card content -->
</Border>
```
Dark card (#1E1E1E) with subtle border (#333333), 4px corner radius, compact padding.

### Checkbox Grid (Tweaks/Settings)
Use `DenseCheckboxGrid` control with items bound to a collection of selectable items. Grid auto-flows items into columns at 220px minimum width.

### Console Output
Use `ConsoleOutputPanel` control for any PowerShell command output. Black background (#0C0C0C), monospace font, auto-scroll, copy/clear buttons.

### Settings Row
Use `CompactSettingsCard` control for each setting. Icon + Title + Description + Action slot (ToggleSwitch, ComboBox, Button).

### Page Layout Pattern
```
Grid (B11PageMargin padding)
├── Row 0: Page header (icon + title + action buttons)
├── Row 1: Status bar (ProgressBar + InfoBars)
└── Row 2: ScrollViewer
    └── StackPanel (B11SectionSpacing)
        ├── Section header
        ├── Content cards
        ├── Section header
        └── Content cards
```

## Do / Don't

| Do | Don't |
|---|---|
| Use B11 theme brushes for all colors | Hardcode hex colors in XAML |
| Use dense 24px rows | Use default WinUI spacing (40px+) |
| Use B11DenseCardStyle for grouping | Use Expander or default cards |
| Use FontIcon with 14px size in nav | Use large icons (20px+) in dense areas |
| Use B11CompactButtonStyle | Use default Button style |
| Use accent color sparingly (headers, primary actions) | Paint everything accent blue |
| Keep pages scrollable | Use fixed-height layouts |
