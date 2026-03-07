# 🎮 GaymerPC API Reference

## Overview

This document provides comprehensive API documentation for all GaymerPC
  components, including configuration management, integration bridge,
  performance framework, and TUI systems

## Table of Contents

1. Configuration Management API

2. Integration Bridge API

3. Performance Framework API

4. Cache System API

5. TUI Components API

6. Launcher Scripts API

7. Examples

---

## Configuration Management API

### UnifiedConfigManager

The central configuration management system for all GaymerPC components

#### Constructor

```python

UnifiedConfigManager(config_root: Optional[Path] = None)

```text**Parameters: **- `config_root` (Optional[Path]): Root directory for configuration files. Defaults to current directory.

**Example:**```python

from Core.Config.unified_config_manager import UnifiedConfigManager

config_manager = UnifiedConfigManager()

```text

#### Methods

##### `get(key: str, default: Any = None) -> Any`Retrieve a configuration value using dot notation**Parameters:**-`key`(str): Configuration key in dot notation (e.g., "user.name", "hardware.cpu.cores")

-`default` (Any): Default value if key not found**Returns:**- Configuration
value or default**Example:**```python

user_name = config_manager.get("user.name", "Unknown")
cpu_cores = config_manager.get("hardware.cpu.cores", 4)

```text

##### `set(key: str, value: Any, persist: bool = False)`Set a configuration value using dot notation**Parameters:**-`key`(str): Configuration key in dot notation

-`value`(Any): Value to set

-`persist` (bool): Whether to persist changes to disk**Example:**```python

config_manager.set("user.name", "Connor O")
config_manager.set("gaming.auto_optimize", True, persist=True)

```text

##### `get_suite_config(suite_name: str) -> Dict[str, Any]`Get configuration for a specific suite**Parameters:**-`suite_name` (str): Name of the suite**Returns:**- Dictionary containing suite configuration**Example:**```python

gaming_config = config_manager.get_suite_config("gaming")

```text

##### `get_user_profile() -> Dict[str, Any]`

Get current user profile configuration**Returns:**- Dictionary containing
user profile**Example:**```python

profile = config_manager.get_user_profile()
print(f"User: {profile['name']}")

```text

##### `validate_config() -> ConfigValidationResult`Validate current configuration**Returns:**-`ConfigValidationResult` object with validation status**Example:**```python

validation = config_manager.validate_config()
if not validation.valid:
    print("Configuration errors:", validation.errors)

```text

##### `reload_config()`

Reload all configuration sources**Example:**```python

config_manager.reload_config()

```text

##### `export_config(format: str = "yaml") -> str`Export current configuration as string**Parameters:**-`format` (str): Export format ("yaml" or "json")

**Returns:**- Configuration as string**Example:**```python

config_yaml = config_manager.export_config("yaml")

```text

##### `create_backup(backup_path: Optional[Path] = None) -> Path`Create configuration backup**Parameters:**-`backup_path` (Optional[Path]): Custom backup path**Returns:**- Path to backup file**Example:**```python

backup_path = config_manager.create_backup()

```text

---

## Integration Bridge API

### IntegrationBridge

Cross-suite communication and integration system

#### Constructor (2)

```python

IntegrationBridge(config_path: Optional[Path] = None)

```text**Parameters:**- `config_path` (Optional[Path]): Path to integration configuration file**Example:**```python

from apps.Shared.GaymerPC_Shared.core.integration_bridge import IntegrationBridge

bridge = IntegrationBridge()

```text

#### Methods (2)

##### `register_suite(suite_type: SuiteType, suite_instance: Any, suite_info

Optional[SuiteInfo] = None) -> bool`Register a suite with the integration
bridge**Parameters:**-`suite_type`(SuiteType): Type of suite to register

-`suite_instance`(Any): Suite instance

-`suite_info` (Optional[SuiteInfo]): Suite information**Returns:**- True if
registration successful**Example:**```python

from apps.Shared.GaymerPC_Shared.core.integration_bridge import SuiteType

success = bridge.register_suite(SuiteType.GAMING, gaming_suite)

```text

##### `unregister_suite(suite_type: SuiteType) -> bool`Unregister a suite from the integration bridge**Parameters:**-`suite_type` (SuiteType): Type of suite to unregister**Returns:**- True if unregistration successful**Example:**```python

success = bridge.unregister_suite(SuiteType.GAMING)

```text

##### `emit_event(event_type: EventType, source_suite: SuiteType, data

Dict[str, Any], target_suite: Optional[SuiteType] = None, priority: int =
1)`Emit an integration event**Parameters:**-`event_type`(EventType): Type of event

-`source_suite`(SuiteType): Source suite

-`data`(Dict[str, Any]): Event data

-`target_suite`(Optional[SuiteType]): Target suite (None for broadcast)

-`priority` (int): Event priority**Example:**```python

from apps.Shared.GaymerPC_Shared.core.integration_bridge import EventType

bridge.emit_event(
    EventType.GAME_DETECTED,
    SuiteType.GAMING,
    {"game_name": "Cyberpunk 2077", "launcher": "Steam"}
)

```text

##### `register_event_handler(event_type: EventType, handler

Callable[[IntegrationEvent], None])`Register an event
handler**Parameters:**-`event_type`(EventType): Type of event to handle

-`handler` (Callable): Event handler function**Example:**```python

def handle_game_detected(event):
    print(f"Game detected: {event.data['game_name']}")

bridge.register_event_handler(EventType.GAME_DETECTED, handle_game_detected)

```text

##### `get_suite_status(suite_type: SuiteType) -> Optional[Dict[str, Any]]`Get status of a specific suite**Parameters:**-`suite_type` (SuiteType): Type of suite**Returns:**- Suite status dictionary or None**Example:**```python

status = bridge.get_suite_status(SuiteType.GAMING)
if status:
    print(f"Gaming suite status: {status['status']}")

```text

---

## Performance Framework API

### PerformanceFramework

High-performance framework with caching, lazy loading, and optimization

#### Constructor (3)

```python

PerformanceFramework()

```text**Example:**```python

from Core.Performance.performance_framework import PerformanceFramework

framework = PerformanceFramework()

```text

#### Decorators

##### `@cached(ttl: int = 3600, key_func: Optional[Callable] = None)`Cache function results with TTL**Parameters:**-`ttl`(int): Time to live in seconds

-`key_func` (Optional[Callable]): Custom cache key function**Example:**```python

@framework.cached(ttl=300)
def expensive_calculation(x, y):
    # Expensive operation
    return x*y + complex_math(x, y)

```text

##### `@background_task`

Run function in background thread**Example: **```python

@framework.background_task
def long_running_task():
    # Long running operation
    process_large_dataset()

```text

##### `@profile`

Profile function performance**Example:**```python

@framework.profile
def optimized_function():
    # Function to profile
    return perform_optimization()

```text

#### Methods (3)

##### `get_performance_stats() -> Dict[str, Any]`

Get performance statistics**Returns:**- Dictionary with performance
metrics**Example:**```python

stats = framework.get_performance_stats()
print(f"Cache hit rate: {stats['cache_hit_rate']}")

```text

---

## Cache System API

### UnifiedCacheSystem

Cross-platform caching system for PowerShell and Python

#### Constructor (4)

```python

UnifiedCacheSystem(
    cache_path: str = "./Cache",
    max_cache_size: int = 10000,
    default_ttl: int = 3600,
    enable_compression: bool = True,
    enable_encryption: bool = False,
    encryption_key: str = "",
    enable_logging: bool = True,
    log_path: str = "./Logs/unified_cache.log"
)

```text**Example:**```python

from Core.Performance.unified_cache_system import UnifiedCacheSystem

cache = UnifiedCacheSystem(
    cache_path="./Cache",
    max_cache_size=5000,
    default_ttl=1800
)

```text

#### Methods (4)

##### `set(key: str, value: Any, ttl: Optional[int] = None, category: str =

"default", priority: int = 1)`Set cache value**Parameters:**-`key`(str): Cache key

-`value`(Any): Value to cache

-`ttl`(Optional[int]): Time to live in seconds

-`category`(str): Cache category

-`priority` (int): Cache priority**Example:**```python

cache.set("user_profile", user_data, ttl=3600, category="user")

```text

##### `get(key: str, default: Any = None) -> Any`Get cache value**Parameters:**-`key`(str): Cache key

-`default` (Any): Default value if not found**Returns:**- Cached value or
default**Example:**```python

user_data = cache.get("user_profile", {})

```text

##### `delete(key: str) -> bool`Delete cache entry**Parameters:**-`key` (str): Cache key**Returns:**- True if deleted**Example:**```python

cache.delete("user_profile")

```text

##### `clear(category: Optional[str] = None)`Clear cache entries**Parameters:**-`category` (Optional[str]): Category to clear (None for all)

**Example:**```python

cache.clear("user")  # Clear user category

cache.clear()        # Clear all

```text

##### `get_stats() -> Dict[str, Any]`

Get cache statistics**Returns:**- Dictionary with cache
statistics**Example:**```python

stats = cache.get_stats()
print(f"Cache hits: {stats['cache_hits']}")
print(f"Cache misses: {stats['cache_misses']}")

```text

---

## TUI Components API

### Base TUI App

All GaymerPC TUIs inherit from a base TUI application class

#### Common Methods

##### `compose() -> ComposeResult`

Compose the TUI layout**Example:**```python

def compose(self) -> ComposeResult:
    yield Header()
    yield TabbedContent(
        Tab("Main", id="main-tab"),
        Tab("Settings", id="settings-tab")
    )
    yield Footer()

```text

##### `on_button_pressed(event: Button.Pressed)`

Handle button press events.
**Example:**```python

def on_button_pressed(self, event: Button.Pressed) -> None:
    if event.button.id == "start-gaming":
        self.start_gaming_session()

```text

##### `notify(message: str, severity: str = "information")`Show notification to user**Parameters:**-`message`(str): Notification message

-`severity` (str): Severity level ("information", "warning", "error")
**Example:**```python

self.notify("Gaming session started", severity="information")

```text

---

## Launcher Scripts API

### PowerShell Launcher Scripts

All launcher scripts follow a consistent pattern

#### Common Parameters

```powershell

param(
    [Parameter(Mandatory = $false)]
    [string]$PythonPath = "python",

    [Parameter(Mandatory = $false)]
    [switch]$NoExit
)

```text

#### Common Functions

##### `Test-Python`

Check if Python is available**Example:**```powershell

if (-not (Test-Python)) {
    Write-Host "❌ Python not found" -ForegroundColor Red
    exit 1
}

```text

##### `Launch-TUI`

Launch a TUI application**Example:**```powershell

function Launch-TUI {
    param([string]$TUIName)

    $tuiPath = Join-Path $GaymerPCRoot "TUI\$TUIName"
    & $PythonPath $tuiPath
}

```text

---

## Examples

### Complete Configuration Setup

```python

from Core.Config.unified_config_manager import UnifiedConfigManager
from apps.Shared.GaymerPC_Shared.core.integration_bridge import
IntegrationBridge, SuiteType

## Initialize configuration

config_manager = UnifiedConfigManager()

## Set user preferences

config_manager.set("user.name", "Connor O")
config_manager.set("user.email", "<Saymoner88@gmail.com>")
config_manager.set("gaming.auto_optimize", True, persist=True)

## Initialize integration bridge

bridge = IntegrationBridge()

## Register gaming suite

gaming_suite = GamingSuite()
bridge.register_suite(SuiteType.GAMING, gaming_suite)

## Set up event handling

def handle_game_detected(event):
    game_name = event.data.get("game_name")
    config_manager.set(f"gaming.last_game", game_name)
    print(f"Game detected: {game_name}")

bridge.register_event_handler(EventType.GAME_DETECTED, handle_game_detected)

```text

### Performance Optimization

```python

from Core.Performance.performance_framework import PerformanceFramework
from Core.Performance.unified_cache_system import UnifiedCacheSystem

## Initialize performance framework

framework = PerformanceFramework()

## Set up caching

cache = UnifiedCacheSystem()

## Optimized function with caching

@framework.cached(ttl=300)
def get_gaming_performance_data():
    # Expensive operation
    return analyze_gaming_performance()

## Background task

@framework.background_task
def update_gaming_stats():
    stats = get_gaming_performance_data()
    cache.set("gaming_stats", stats, ttl=600)

## Profile performance

@framework.profile
def optimize_system():
    return perform_system_optimization()

```text

### TUI Development

```python

from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import Button, Header, Footer, Static

class GamingTUI(App):
    def compose(self) -> ComposeResult:
        yield Header()
        yield Container(
            Static("Gaming Command Center", id="title"),
            Horizontal(
                Button("Start Gaming", id="start-gaming"),
                Button("Optimize System", id="optimize"),
                Button("Settings", id="settings")
            ),
            id="main-container"
        )
        yield Footer()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "start-gaming":
            self.start_gaming_session()
        elif event.button.id == "optimize":
            self.optimize_system()
        elif event.button.id == "settings":
            self.show_settings()

    def start_gaming_session(self):
        self.notify("Starting gaming session...", severity="information")
        # Gaming session logic here

    def optimize_system(self):
        self.notify("Optimizing system...", severity="information")
        # Optimization logic here

if __name__ == "__main__":
    app = GamingTUI()
    app.run()

```text

### PowerShell Integration

```powershell

## Launch-AllTUIs.ps1

param(
    [string]$TUI = "All",
    [string]$PythonPath = "python"
)

function Launch-TUI {
    param([string]$TUIName)

    $tuiPath = Join-Path $GaymerPCRoot "TUI\$TUIName"
    if (Test-Path $tuiPath) {
        & $PythonPath $tuiPath
    } else {
        Write-Host "TUI not found: $TUIName" -ForegroundColor Red
    }
}

## Main execution

if ($TUI -eq "All") {
    Show-TUIMenu
} else {
    Launch-TUI $TUI
}

```text

---

## Error Handling

### Common Exceptions

#### ConfigurationError

Raised when configuration operations fail

```python

try:
    config_manager.set("invalid.key", "value")
except ConfigurationError as e:
    print(f"Configuration error: {e}")

```text

#### IntegrationError

Raised when integration bridge operations fail

```python

try:
    bridge.register_suite(SuiteType.INVALID, suite)
except IntegrationError as e:
    print(f"Integration error: {e}")

```text

#### CacheError

Raised when cache operations fail

```python

try:
    cache.set("key", "value")
except CacheError as e:
    print(f"Cache error: {e}")

```text

---

## Best Practices

### Configuration Management

1.**Use dot notation**for nested configuration keys
2.**Validate configuration**before using
3.**Create backups**before major changes
4.**Use environment-specific**configurations

### Integration Bridge

1.**Register suites**early in application lifecycle
2.**Handle events**asynchronously when possible
3.**Use appropriate event priorities**4.**Clean up**event handlers when done

### Performance Framework

1.**Use caching**for expensive operations
2.**Profile critical paths**regularly
3.**Run background tasks**for non-blocking operations
4.**Monitor performance**metrics

### TUI Development (2)

1.**Follow consistent**layout patterns
2.**Handle errors**gracefully
3.**Provide user feedback**for long operations
4.**Test on different**terminal sizes

---

## Troubleshooting

### Common Issues

#### Configuration Not Loading

- Check file paths and permissions

- Validate YAML/JSON syntax

- Ensure required sections exist

#### Integration Bridge Not Working

- Verify suite registration

- Check event handler registration

- Ensure proper event types

#### Performance Issues

- Check cache hit rates

- Profile slow functions

- Monitor memory usage

#### TUI Not Displaying

- Check terminal compatibility

- Verify Textual installation

- Test with minimal example

### Debug Mode

Enable debug logging:

```python

import logging
logging.basicConfig(level=logging.DEBUG)

```text

### Testing

Run comprehensive tests:

```powershell

.\Scripts\Run-Tests.ps1 -TestType All -Verbose

```text

---

## Support

For additional support:

-**Documentation**: Check the Docs/ directory

-**Examples**: See the Examples/ directory

-**Issues**: Report on GitHub

-**Community**: Join the Discord server

---
*Last updated: January 2025*

* Version: 1.0.0*
