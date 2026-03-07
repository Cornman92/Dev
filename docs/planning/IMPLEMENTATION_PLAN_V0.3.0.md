# Better11 v0.3.0 - Detailed Implementation Plan

**Version**: 0.3.0  
**Codename**: "Security & Trust"  
**Target Date**: March 31, 2026  
**Duration**: 12 weeks (January - March 2026)  
**Status**: Planning Phase

---

## 📋 Executive Summary

Version 0.3.0 focuses on **security, automation, and user trust**. This release adds critical security features (code signing verification), automation capabilities (auto-updates), and essential system management tools (privacy, updates, startup management).

**Key Goals**:
1. ✅ Verify software integrity with code signing
2. ✅ Automate application and Better11 updates
3. ✅ Provide user configuration persistence
4. ✅ Enable comprehensive system control
5. ✅ Maintain 100% test coverage
6. ✅ Zero regressions in existing features

---

## 🎯 Feature Breakdown

### Phase 1: Foundation (Weeks 1-3)

#### 1.1 Configuration System (`better11/config.py`)
**Priority**: CRITICAL | **Effort**: 1 week | **Owner**: TBD

**Requirements**:
- Load/save TOML and YAML configuration files
- Default configuration embedded in code
- User configuration in user directory (~/.better11/config.toml)
- System-wide configuration support
- Configuration validation with clear error messages
- Configuration migration system for future versions
- Environment variable overrides

**Configuration Structure**:
```toml
[better11]
version = "0.3.0"
auto_update = true
check_updates_on_start = true
telemetry_enabled = false

[applications]
catalog_url = "https://catalog.better11.io/apps.json"
auto_install_dependencies = true
verify_signatures = true
require_code_signing = false  # Warn but don't block if false

[system_tools]
always_create_restore_point = true
confirm_destructive_actions = true
backup_registry = true
safety_level = "high"  # low, medium, high, paranoid

[gui]
theme = "system"  # system, light, dark
show_advanced_options = false
remember_window_size = true
default_tab = "applications"

[logging]
level = "INFO"  # DEBUG, INFO, WARNING, ERROR
file_enabled = true
console_enabled = true
max_log_size_mb = 10
```

**Implementation Details**:
```python
# better11/config.py
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
import tomllib  # Python 3.11+ stdlib
import tomli  # Fallback for <3.11

@dataclass
class Better11Config:
    version: str = "0.3.0"
    auto_update: bool = True
    check_updates_on_start: bool = True
    telemetry_enabled: bool = False

@dataclass
class ApplicationsConfig:
    catalog_url: str = "default"
    auto_install_dependencies: bool = True
    verify_signatures: bool = True
    require_code_signing: bool = False

@dataclass
class SystemToolsConfig:
    always_create_restore_point: bool = True
    confirm_destructive_actions: bool = True
    backup_registry: bool = True
    safety_level: str = "high"

@dataclass
class GUIConfig:
    theme: str = "system"
    show_advanced_options: bool = False
    remember_window_size: bool = True
    default_tab: str = "applications"

@dataclass
class LoggingConfig:
    level: str = "INFO"
    file_enabled: bool = True
    console_enabled: bool = True
    max_log_size_mb: int = 10

@dataclass
class Config:
    better11: Better11Config = field(default_factory=Better11Config)
    applications: ApplicationsConfig = field(default_factory=ApplicationsConfig)
    system_tools: SystemToolsConfig = field(default_factory=SystemToolsConfig)
    gui: GUIConfig = field(default_factory=GUIConfig)
    logging: LoggingConfig = field(default_factory=LoggingConfig)
    
    @classmethod
    def load(cls, path: Optional[Path] = None) -> "Config":
        """Load configuration from file with defaults."""
        pass
    
    def save(self, path: Optional[Path] = None) -> None:
        """Save configuration to file."""
        pass
    
    @classmethod
    def get_default_path(cls) -> Path:
        """Get default config file path."""
        return Path.home() / ".better11" / "config.toml"
```

**Testing**:
- Load from valid TOML file
- Load from valid YAML file
- Handle missing file (use defaults)
- Handle malformed file (clear error)
- Save configuration
- Configuration validation
- Migration from old versions
- Environment variable overrides

**Deliverables**:
- `better11/config.py` - Configuration module
- `tests/test_config.py` - Test suite (15+ tests)
- Configuration schema documentation
- Migration guide for future versions

---

#### 1.2 Base Classes & Common Interfaces (Weeks 1-2)
**Priority**: CRITICAL | **Effort**: 1 week | **Owner**: TBD

Create common base classes for consistency:

**1.2.1 SystemTool Base Class**
```python
# system_tools/base.py
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional
from .safety import ensure_windows, create_restore_point, confirm_action

@dataclass
class ToolMetadata:
    name: str
    description: str
    version: str
    requires_admin: bool = True
    requires_restart: bool = False
    category: str = "general"

class SystemTool(ABC):
    """Base class for all system tools."""
    
    def __init__(self, config: Optional[dict] = None):
        self.config = config or {}
        self._metadata = self.get_metadata()
    
    @abstractmethod
    def get_metadata(self) -> ToolMetadata:
        """Return tool metadata."""
        pass
    
    @abstractmethod
    def validate_environment(self) -> None:
        """Validate environment before execution."""
        pass
    
    @abstractmethod
    def execute(self, *args, **kwargs) -> bool:
        """Execute the tool's primary function."""
        pass
    
    def pre_execute_checks(self, create_restore: bool = True) -> bool:
        """Common pre-execution safety checks."""
        ensure_windows()
        self.validate_environment()
        
        if create_restore and self._metadata.requires_admin:
            if self.config.get('always_create_restore_point', True):
                create_restore_point(f"Before {self._metadata.name}")
        
        if self._metadata.requires_admin:
            # Check admin privileges
            pass
        
        if self.config.get('confirm_destructive_actions', True):
            msg = f"Execute {self._metadata.name}?"
            if not confirm_action(msg):
                return False
        
        return True
```

**1.2.2 Updatable Interface**
```python
# better11/interfaces.py
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional

@dataclass
class Version:
    major: int
    minor: int
    patch: int
    
    def __str__(self) -> str:
        return f"{self.major}.{self.minor}.{self.patch}"
    
    def __lt__(self, other: "Version") -> bool:
        return (self.major, self.minor, self.patch) < (other.major, other.minor, other.patch)
    
    @classmethod
    def parse(cls, version_str: str) -> "Version":
        """Parse version string like '1.2.3'."""
        parts = version_str.split('.')
        return cls(int(parts[0]), int(parts[1]), int(parts[2]))

class Updatable(ABC):
    """Interface for components that can be updated."""
    
    @abstractmethod
    def get_current_version(self) -> Version:
        """Get currently installed version."""
        pass
    
    @abstractmethod
    def check_for_updates(self) -> Optional[Version]:
        """Check if updates are available. Returns new version or None."""
        pass
    
    @abstractmethod
    def download_update(self, version: Version) -> Path:
        """Download the update package."""
        pass
    
    @abstractmethod
    def install_update(self, package_path: Path) -> bool:
        """Install the downloaded update."""
        pass
    
    @abstractmethod
    def rollback_update(self) -> bool:
        """Rollback to previous version if update fails."""
        pass
```

**1.2.3 Configurable Interface**
```python
class Configurable(ABC):
    """Interface for configurable components."""
    
    @abstractmethod
    def load_config(self, config: dict) -> None:
        """Load configuration."""
        pass
    
    @abstractmethod
    def get_config_schema(self) -> dict:
        """Get JSON schema for configuration validation."""
        pass
    
    @abstractmethod
    def validate_config(self, config: dict) -> bool:
        """Validate configuration. Raises ValueError on invalid config."""
        pass
```

**Deliverables**:
- `system_tools/base.py` - SystemTool base class
- `better11/interfaces.py` - Common interfaces
- `tests/test_base_classes.py` - Base class tests
- Documentation for extending Better11

---

#### 1.3 Enhanced Logging System (Week 2)
**Priority**: HIGH | **Effort**: 3 days | **Owner**: TBD

**Requirements**:
- Structured logging with context
- Multiple output handlers (file, console, system)
- Log rotation
- Performance tracking
- User action logging (audit trail)
- Sensitive data filtering
- Log levels per module

**Implementation**:
```python
# better11/logging_config.py
import logging
import logging.handlers
from pathlib import Path
from typing import Optional

class SensitiveDataFilter(logging.Filter):
    """Filter out sensitive data from logs."""
    
    def filter(self, record: logging.LogRecord) -> bool:
        # Redact passwords, keys, tokens, etc.
        message = record.getMessage()
        # Replace patterns
        return True

def setup_logging(config: Optional[dict] = None) -> None:
    """Configure logging system."""
    config = config or {}
    
    # Create logs directory
    log_dir = Path.home() / ".better11" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    
    # Main application log
    app_handler = logging.handlers.RotatingFileHandler(
        log_dir / "better11.log",
        maxBytes=config.get('max_log_size_mb', 10) * 1024 * 1024,
        backupCount=5
    )
    
    # Audit log for user actions
    audit_handler = logging.handlers.RotatingFileHandler(
        log_dir / "audit.log",
        maxBytes=5 * 1024 * 1024,
        backupCount=10
    )
    
    # Console handler
    console_handler = logging.StreamHandler()
    
    # Format
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Configure root logger
    root = logging.getLogger()
    root.setLevel(config.get('level', 'INFO'))
    # ... add handlers
```

**Deliverables**:
- `better11/logging_config.py` - Logging configuration
- Log rotation and cleanup
- Audit trail support
- Integration with existing modules

---

### Phase 2: Security Features (Weeks 3-6)

#### 2.1 Code Signing Verification (`better11/apps/code_signing.py`)
**Priority**: CRITICAL | **Effort**: 3 weeks | **Owner**: TBD

**Requirements**:
- Verify Authenticode signatures on PE files (EXE, DLL, MSI)
- Extract signature information (publisher, timestamp, etc.)
- Certificate chain validation
- Revocation checking (CRL/OCSP) - optional with config
- Trusted publisher management
- Integration with installer verification pipeline

**API Design**:
```python
# better11/apps/code_signing.py
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Optional, List

class SignatureStatus(Enum):
    VALID = "valid"
    INVALID = "invalid"
    UNSIGNED = "unsigned"
    REVOKED = "revoked"
    EXPIRED = "expired"
    UNTRUSTED = "untrusted"

@dataclass
class CertificateInfo:
    subject: str
    issuer: str
    serial_number: str
    thumbprint: str
    valid_from: datetime
    valid_to: datetime
    
    def is_expired(self) -> bool:
        return datetime.now() > self.valid_to

@dataclass
class SignatureInfo:
    status: SignatureStatus
    certificate: Optional[CertificateInfo]
    timestamp: Optional[datetime]
    hash_algorithm: Optional[str]
    error_message: Optional[str] = None
    
    def is_trusted(self) -> bool:
        return self.status == SignatureStatus.VALID

class CodeSigningVerifier:
    """Verify Authenticode signatures on Windows executables."""
    
    def __init__(self, check_revocation: bool = False):
        self.check_revocation = check_revocation
    
    def verify_signature(self, file_path: Path) -> SignatureInfo:
        """Verify the digital signature of a file."""
        # Implementation using one of:
        # 1. PowerShell Get-AuthenticodeSignature
        # 2. Win32 WinVerifyTrust API (via ctypes/cffi)
        # 3. sigcheck.exe from Sysinternals
        pass
    
    def extract_certificate(self, file_path: Path) -> Optional[CertificateInfo]:
        """Extract certificate information."""
        pass
    
    def is_trusted_publisher(self, cert_info: CertificateInfo) -> bool:
        """Check if publisher is in trusted list."""
        pass
    
    def add_trusted_publisher(self, cert_info: CertificateInfo) -> None:
        """Add publisher to trusted list."""
        pass
```

**Implementation Approaches**:

**Option 1: PowerShell (Easiest)**
```python
def verify_with_powershell(file_path: Path) -> SignatureInfo:
    script = f"Get-AuthenticodeSignature -FilePath '{file_path}'"
    result = subprocess.run(
        ["powershell", "-NoProfile", "-Command", script],
        capture_output=True, text=True, check=True
    )
    # Parse output
    return parse_signature_output(result.stdout)
```

**Option 2: Win32 API (More Control)**
```python
from ctypes import windll, Structure, POINTER, c_void_p, c_ulong
from ctypes.wintypes import DWORD, LPCWSTR

# WinVerifyTrust API
WINTRUST_ACTION_GENERIC_VERIFY_V2 = "{...}"

def verify_with_winapi(file_path: Path) -> SignatureInfo:
    # Use WinVerifyTrust API
    # More complex but more control
    pass
```

**Option 3: Sigcheck.exe (Sysinternals)**
```python
def verify_with_sigcheck(file_path: Path) -> SignatureInfo:
    # Download sigcheck.exe if not present
    # Run: sigcheck.exe -accepteula -nobanner -q file.exe
    # Parse CSV output
    pass
```

**Recommendation**: Use **PowerShell** for initial implementation (simple, reliable), with optional **Win32 API** support for advanced features.

**Integration with Installer Verification**:
```python
# better11/apps/verification.py (existing file)
from .code_signing import CodeSigningVerifier, SignatureStatus

class DownloadVerifier:
    def __init__(self, ..., verify_signatures: bool = True):
        self.verify_signatures = verify_signatures
        self.code_signing_verifier = CodeSigningVerifier()
    
    def verify(self, file_path: Path, metadata: AppMetadata) -> bool:
        # Existing hash verification
        if not self._verify_hash(file_path, metadata):
            return False
        
        # New: Code signing verification
        if self.verify_signatures:
            sig_info = self.code_signing_verifier.verify_signature(file_path)
            if sig_info.status == SignatureStatus.UNSIGNED:
                _LOGGER.warning("File is not digitally signed: %s", file_path)
                # Warn but don't fail (configurable)
            elif not sig_info.is_trusted():
                _LOGGER.error("File has invalid signature: %s", sig_info.error_message)
                return False
        
        return True
```

**Configuration**:
```toml
[applications]
verify_signatures = true
require_signatures = false  # If true, reject unsigned files
check_revocation = false    # CRL/OCSP checking (slow)
trusted_publishers = [
    "CN=Microsoft Corporation, ...",
    "CN=Google LLC, ..."
]
```

**Testing**:
- Verify signed EXE/MSI/DLL
- Detect unsigned files
- Detect invalid signatures
- Detect expired certificates
- Detect revoked certificates (if enabled)
- Handle untrusted publishers
- Performance testing (signature verification can be slow)

**Deliverables**:
- `better11/apps/code_signing.py` - Code signing module (300-400 lines)
- `tests/test_code_signing.py` - Comprehensive tests (20+ tests)
- Integration with installer verification
- Configuration options
- Documentation with examples
- Sample signed/unsigned executables for testing

---

#### 2.2 Windows Update Management (`system_tools/updates.py`)
**Priority**: HIGH | **Effort**: 2 weeks | **Owner**: TBD

**Requirements**:
- Check for available Windows updates
- Pause/resume updates
- Configure active hours
- Install specific updates
- View update history
- Rollback updates
- Configure update policies
- Control update restarts

**API Design**:
```python
# system_tools/updates.py
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from typing import List, Optional

class UpdateType(Enum):
    CRITICAL = "critical"
    SECURITY = "security"
    DEFINITION = "definition"
    FEATURE = "feature"
    DRIVER = "driver"

class UpdateStatus(Enum):
    AVAILABLE = "available"
    DOWNLOADING = "downloading"
    PENDING_INSTALL = "pending_install"
    INSTALLED = "installed"
    FAILED = "failed"

@dataclass
class WindowsUpdate:
    id: str
    title: str
    description: str
    update_type: UpdateType
    size_mb: float
    status: UpdateStatus
    kb_article: Optional[str] = None
    support_url: Optional[str] = None
    is_mandatory: bool = False
    requires_restart: bool = False

class WindowsUpdateManager:
    """Manage Windows Update settings and operations."""
    
    def check_for_updates(self) -> List[WindowsUpdate]:
        """Check for available Windows updates."""
        pass
    
    def install_updates(self, update_ids: List[str]) -> bool:
        """Install specific updates."""
        pass
    
    def pause_updates(self, days: int = 7) -> bool:
        """Pause updates for specified days (max 35)."""
        pass
    
    def resume_updates(self) -> bool:
        """Resume updates if paused."""
        pass
    
    def set_active_hours(self, start_hour: int, end_hour: int) -> bool:
        """Set active hours to prevent restart interruptions."""
        pass
    
    def get_update_history(self, days: int = 30) -> List[WindowsUpdate]:
        """Get update installation history."""
        pass
    
    def uninstall_update(self, kb_article: str) -> bool:
        """Uninstall a specific update by KB number."""
        pass
    
    def set_metered_connection(self, enabled: bool) -> bool:
        """Configure metered connection to limit updates."""
        pass
```

**Implementation Approach**:

**Option 1: PowerShell PSWindowsUpdate Module**
```powershell
# Install-Module PSWindowsUpdate
Get-WindowsUpdate
Install-WindowsUpdate -AcceptAll -AutoReboot
```

**Option 2: Windows Update API (COM)**
```python
import win32com.client

def check_updates_com():
    session = win32com.client.Dispatch("Microsoft.Update.Session")
    searcher = session.CreateUpdateSearcher()
    results = searcher.Search("IsInstalled=0")
    return results.Updates
```

**Option 3: Registry + Services**
```python
# Simpler approach for pause/resume
def pause_updates_registry():
    # Set registry keys to pause updates
    key = r"HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    # PauseUpdatesExpiryTime
    pass
```

**Recommendation**: Combination approach:
- **PowerShell** for update checking and installation
- **Registry** for simple settings (pause, active hours)
- **Services** for controlling Windows Update service

**Testing**:
- Check for updates (mocked)
- Pause/resume updates
- Set active hours
- View update history
- Metered connection toggle
- Ensure no actual updates installed in tests

**Deliverables**:
- `system_tools/updates.py` - Update management (400-500 lines)
- `tests/test_updates.py` - Test suite (15+ tests)
- CLI integration: `better11-cli updates check/pause/resume`
- GUI tab for update management
- Documentation

---

#### 2.3 Privacy & Telemetry Control (`system_tools/privacy.py`)
**Priority**: HIGH | **Effort**: 2 weeks | **Owner**: TBD

**Requirements**:
- Control Windows telemetry levels
- Disable/enable diagnostic data
- Manage app permissions (camera, microphone, location)
- Disable advertising ID
- Control Cortana and search settings
- OneDrive integration control
- Windows Error Reporting settings
- Feedback & diagnostics settings

**API Design**:
```python
# system_tools/privacy.py
from dataclasses import dataclass
from enum import Enum
from typing import List, Dict

class TelemetryLevel(Enum):
    SECURITY = 0  # Enterprise only
    BASIC = 1
    ENHANCED = 2
    FULL = 3

class PrivacySetting(Enum):
    LOCATION = "location"
    CAMERA = "camera"
    MICROPHONE = "microphone"
    NOTIFICATIONS = "notifications"
    ACCOUNT_INFO = "account_info"
    CONTACTS = "contacts"
    CALENDAR = "calendar"
    PHONE_CALLS = "phone_calls"
    CALL_HISTORY = "call_history"
    EMAIL = "email"
    TASKS = "tasks"
    MESSAGING = "messaging"
    RADIOS = "radios"
    OTHER_DEVICES = "other_devices"
    BACKGROUND_APPS = "background_apps"
    APP_DIAGNOSTICS = "app_diagnostics"
    DOCUMENTS = "documents"
    PICTURES = "pictures"
    VIDEOS = "videos"
    FILE_SYSTEM = "file_system"

@dataclass
class PrivacyPreset:
    name: str
    description: str
    telemetry_level: TelemetryLevel
    settings: Dict[PrivacySetting, bool]
    disable_advertising_id: bool = True
    disable_cortana: bool = False

class PrivacyManager:
    """Manage Windows privacy and telemetry settings."""
    
    # Presets
    MAXIMUM_PRIVACY = PrivacyPreset(
        name="Maximum Privacy",
        description="Disable all telemetry and most app permissions",
        telemetry_level=TelemetryLevel.BASIC,
        settings={s: False for s in PrivacySetting},
        disable_advertising_id=True,
        disable_cortana=True
    )
    
    BALANCED = PrivacyPreset(
        name="Balanced",
        description="Reasonable privacy with some features enabled",
        telemetry_level=TelemetryLevel.BASIC,
        settings={
            PrivacySetting.LOCATION: True,
            PrivacySetting.BACKGROUND_APPS: True,
            # ... selective enabling
        }
    )
    
    def set_telemetry_level(self, level: TelemetryLevel) -> bool:
        """Set Windows telemetry level."""
        pass
    
    def get_telemetry_level(self) -> TelemetryLevel:
        """Get current telemetry level."""
        pass
    
    def set_app_permission(self, setting: PrivacySetting, enabled: bool) -> bool:
        """Set app permission."""
        pass
    
    def get_app_permission(self, setting: PrivacySetting) -> bool:
        """Get app permission status."""
        pass
    
    def disable_advertising_id(self) -> bool:
        """Disable advertising ID."""
        pass
    
    def disable_cortana(self) -> bool:
        """Disable Cortana."""
        pass
    
    def configure_onedrive(self, enabled: bool) -> bool:
        """Enable/disable OneDrive integration."""
        pass
    
    def apply_preset(self, preset: PrivacyPreset) -> bool:
        """Apply a privacy preset."""
        pass
    
    def disable_telemetry_services(self) -> bool:
        """Disable telemetry-related services (DiagTrack, etc.)."""
        pass
```

**Registry Locations**:
```python
TELEMETRY_KEY = r"HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
PRIVACY_KEY = r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager"
ADVERTISING_KEY = r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
CORTANA_KEY = r"HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
```

**Services to Manage**:
- DiagTrack (Connected User Experiences and Telemetry)
- dmwappushservice (Device Management Wireless Application Protocol)
- RetailDemo
- WerSvc (Windows Error Reporting)

**Testing**:
- Set/get telemetry level
- Enable/disable app permissions
- Disable advertising ID
- Apply privacy presets
- Service management
- Registry backup before changes

**Deliverables**:
- `system_tools/privacy.py` - Privacy management (400-500 lines)
- `tests/test_privacy.py` - Test suite (20+ tests)
- 3-4 privacy presets
- CLI integration
- GUI integration
- Documentation with privacy guide

---

### Phase 3: Automation & Updates (Weeks 6-9)

#### 3.1 Auto-Update System (`better11/apps/updater.py`)
**Priority**: CRITICAL | **Effort**: 2 weeks | **Owner**: TBD

**Requirements**:
- Check for application updates
- Compare versions (semantic versioning)
- Download and install updates
- Better11 self-update capability
- Update notifications
- Automatic update scheduling
- Rollback on failure
- Update manifest format

**API Design**:
```python
# better11/apps/updater.py
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional, List
from .models import AppMetadata, AppStatus
from ..interfaces import Version, Updatable

@dataclass
class UpdateInfo:
    app_id: str
    current_version: Version
    available_version: Version
    download_url: str
    release_notes: str
    release_date: datetime
    is_security_update: bool = False
    is_mandatory: bool = False
    size_mb: float = 0.0

class ApplicationUpdater(Updatable):
    """Manage application updates."""
    
    def __init__(self, app_manager, catalog_url: str):
        self.app_manager = app_manager
        self.catalog_url = catalog_url
    
    def check_for_updates(self, app_id: Optional[str] = None) -> List[UpdateInfo]:
        """Check for updates for installed applications."""
        installed = self.app_manager.list_installed()
        updates = []
        
        # Fetch latest catalog
        latest_catalog = self._fetch_latest_catalog()
        
        for app in installed:
            latest = latest_catalog.get(app.app_id)
            if latest:
                current = Version.parse(app.version)
                available = Version.parse(latest.version)
                if available > current:
                    updates.append(UpdateInfo(
                        app_id=app.app_id,
                        current_version=current,
                        available_version=available,
                        download_url=latest.uri,
                        release_notes=latest.release_notes,
                        ...
                    ))
        
        return updates
    
    def install_update(self, update_info: UpdateInfo) -> bool:
        """Download and install an update."""
        # Download new version
        # Backup current version
        # Install new version
        # Rollback on failure
        pass
    
    def schedule_updates(self, hour: int = 3) -> bool:
        """Schedule automatic updates."""
        pass
    
    def rollback_update(self, app_id: str) -> bool:
        """Rollback to previous version."""
        pass

class Better11Updater(Updatable):
    """Self-update capability for Better11."""
    
    UPDATE_CHECK_URL = "https://better11.io/api/version"
    
    def get_current_version(self) -> Version:
        from .. import __version__
        return Version.parse(__version__)
    
    def check_for_updates(self) -> Optional[UpdateInfo]:
        """Check if newer Better11 version is available."""
        pass
    
    def download_update(self, version: Version) -> Path:
        """Download Better11 update."""
        pass
    
    def install_update(self, package_path: Path) -> bool:
        """Install Better11 update (restart required)."""
        # Windows: Replace files on restart
        # Use MoveFileEx with MOVEFILE_DELAY_UNTIL_REBOOT
        pass
```

**Update Manifest Format** (in catalog):
```json
{
  "applications": [
    {
      "app_id": "example-app",
      "version": "2.0.0",
      "previous_version": "1.5.0",
      "release_date": "2026-01-15",
      "release_notes": "- New feature\n- Bug fixes",
      "is_security_update": false,
      "is_mandatory": false,
      "changelog_url": "https://...",
      "uri": "https://..."
    }
  ]
}
```

**Better11 Update API**:
```json
// GET https://better11.io/api/version
{
  "version": "0.3.0",
  "release_date": "2026-03-31",
  "download_url": "https://github.com/.../better11-0.3.0.zip",
  "sha256": "...",
  "signature": "...",
  "min_version_required": "0.2.0",
  "release_notes": "...",
  "is_security_update": false
}
```

**Update Workflow**:
1. Check for updates (on startup or manual)
2. Display available updates to user
3. User selects updates to install
4. Download updates with verification
5. Install updates (may require restart)
6. Verify installation
7. Rollback on failure

**Testing**:
- Version comparison logic
- Update detection
- Download and install updates
- Rollback functionality
- Self-update process
- Scheduled updates
- Update notifications

**Deliverables**:
- `better11/apps/updater.py` - Update system (400-500 lines)
- `tests/test_updater.py` - Test suite (20+ tests)
- Update manifest schema
- CLI commands: `better11-cli update check/install`
- GUI update notifications
- Documentation

---

#### 3.2 Startup Manager (`system_tools/startup.py`)
**Priority**: HIGH | **Effort**: 1 week | **Owner**: TBD

**Requirements**:
- List all startup programs from all locations
- Enable/disable startup items
- Manage scheduled tasks
- Estimate boot impact
- Delay startup items
- Startup recommendations

**API Design**:
```python
# system_tools/startup.py
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import List, Optional

class StartupLocation(Enum):
    REGISTRY_HKLM_RUN = "hklm_run"
    REGISTRY_HKCU_RUN = "hkcu_run"
    STARTUP_FOLDER_COMMON = "startup_common"
    STARTUP_FOLDER_USER = "startup_user"
    TASK_SCHEDULER = "task_scheduler"
    SERVICES = "services"

class StartupImpact(Enum):
    HIGH = "high"      # >3s delay
    MEDIUM = "medium"  # 1-3s delay
    LOW = "low"        # <1s delay
    UNKNOWN = "unknown"

@dataclass
class StartupItem:
    name: str
    command: str
    location: StartupLocation
    enabled: bool
    impact: StartupImpact = StartupImpact.UNKNOWN
    publisher: Optional[str] = None
    
class StartupManager:
    """Manage Windows startup programs."""
    
    def list_startup_items(self) -> List[StartupItem]:
        """List all startup programs from all locations."""
        items = []
        items.extend(self._get_registry_items())
        items.extend(self._get_startup_folder_items())
        items.extend(self._get_scheduled_tasks())
        items.extend(self._get_startup_services())
        return items
    
    def enable_startup_item(self, item: StartupItem) -> bool:
        """Enable a startup item."""
        pass
    
    def disable_startup_item(self, item: StartupItem) -> bool:
        """Disable a startup item."""
        pass
    
    def remove_startup_item(self, item: StartupItem) -> bool:
        """Permanently remove a startup item."""
        pass
    
    def delay_startup_item(self, item: StartupItem, seconds: int) -> bool:
        """Delay startup item execution."""
        pass
    
    def get_boot_time_estimate(self) -> float:
        """Estimate boot time based on startup items."""
        pass
    
    def get_recommendations(self) -> List[str]:
        """Get startup optimization recommendations."""
        pass
```

**Registry Keys to Check**:
```python
STARTUP_REGISTRY_KEYS = [
    r"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    r"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    r"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
    r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
]
```

**Startup Folders**:
```python
STARTUP_FOLDERS = [
    Path(os.environ['APPDATA']) / 'Microsoft/Windows/Start Menu/Programs/Startup',
    Path(os.environ['PROGRAMDATA']) / 'Microsoft/Windows/Start Menu/Programs/Startup',
]
```

**Testing**:
- List startup items from all locations
- Enable/disable items
- Remove items
- Handle different item types
- Backup before changes

**Deliverables**:
- `system_tools/startup.py` - Startup management (300-400 lines)
- `tests/test_startup.py` - Test suite (15+ tests)
- CLI integration
- GUI startup management tab
- Documentation

---

#### 3.3 Windows Features Manager (`system_tools/features.py`)
**Priority**: MEDIUM | **Effort**: 1 week | **Owner**: TBD

**Requirements**:
- List available Windows optional features
- Enable Windows features
- Disable Windows features
- Feature dependency resolution
- Bulk operations
- Feature presets

**API Design**:
```python
# system_tools/features.py
from dataclasses import dataclass
from enum import Enum
from typing import List, Set

class FeatureState(Enum):
    ENABLED = "enabled"
    DISABLED = "disabled"
    ENABLE_PENDING = "enable_pending"
    DISABLE_PENDING = "disable_pending"

@dataclass
class WindowsFeature:
    name: str
    display_name: str
    description: str
    state: FeatureState
    restart_required: bool = False
    dependencies: List[str] = None

@dataclass
class FeaturePreset:
    name: str
    description: str
    features_to_enable: List[str]
    features_to_disable: List[str]

class WindowsFeaturesManager:
    """Manage Windows optional features."""
    
    # Presets
    DEVELOPER_PRESET = FeaturePreset(
        name="Developer",
        description="Enable features useful for developers",
        features_to_enable=[
            "Microsoft-Windows-Subsystem-Linux",
            "VirtualMachinePlatform",
            "Microsoft-Hyper-V-All",
            "Containers",
            "HypervisorPlatform",
        ],
        features_to_disable=[]
    )
    
    MINIMAL_PRESET = FeaturePreset(
        name="Minimal",
        description="Disable unnecessary features",
        features_to_enable=[],
        features_to_disable=[
            "WorkFolders-Client",
            "Printing-XPSServices-Features",
            "MediaPlayback",
        ]
    )
    
    def list_features(self, state: Optional[FeatureState] = None) -> List[WindowsFeature]:
        """List available Windows features."""
        # Use: DISM /Online /Get-Features
        pass
    
    def enable_feature(self, feature_name: str) -> bool:
        """Enable a Windows feature."""
        # DISM /Online /Enable-Feature /FeatureName:...
        pass
    
    def disable_feature(self, feature_name: str) -> bool:
        """Disable a Windows feature."""
        pass
    
    def get_feature_dependencies(self, feature_name: str) -> List[str]:
        """Get feature dependencies."""
        pass
    
    def apply_preset(self, preset: FeaturePreset) -> bool:
        """Apply a feature preset."""
        pass
    
    def get_feature_state(self, feature_name: str) -> FeatureState:
        """Get the state of a specific feature."""
        pass
```

**Common Features**:
```python
COMMON_FEATURES = {
    "WSL": "Microsoft-Windows-Subsystem-Linux",
    "WSL2": "VirtualMachinePlatform",
    "Hyper-V": "Microsoft-Hyper-V-All",
    "Sandbox": "Containers-DisposableClientVM",
    ".NET 3.5": "NetFx3",
    "Telnet": "TelnetClient",
    "TFTP": "TFTP",
}
```

**Testing**:
- List features
- Parse feature information
- Detect dependencies
- Apply presets
- Mock DISM commands

**Deliverables**:
- `system_tools/features.py` - Features management (250-350 lines)
- `tests/test_features.py` - Test suite (12+ tests)
- 3-4 feature presets
- CLI integration
- Documentation

---

### Phase 4: Polish & Integration (Weeks 9-12)

#### 4.1 GUI Enhancements
**Priority**: HIGH | **Effort**: 2 weeks | **Owner**: TBD

**Improvements**:
1. **Better Progress Reporting**
   - Real-time progress bars
   - Async operations with proper UI updates
   - Cancellable operations
   - Progress notifications

2. **New Tabs/Features**
   - Updates tab
   - Privacy tab
   - Startup tab
   - Windows Features tab
   - Configuration editor

3. **Visual Improvements**
   - Consistent styling
   - Dark mode support (read from config)
   - Better error dialogs
   - Tooltips for all options

**Implementation**:
```python
# better11/gui.py (enhancements)
import tkinter as tk
from tkinter import ttk
import threading
import queue

class Better11GUI:
    def __init__(self):
        self.root = tk.Tk()
        self.notebook = ttk.Notebook(self.root)
        
        # Tabs
        self.create_applications_tab()
        self.create_system_tools_tab()
        self.create_updates_tab()        # NEW
        self.create_privacy_tab()        # NEW
        self.create_startup_tab()        # NEW
        self.create_features_tab()       # NEW
        self.create_settings_tab()       # NEW
    
    def create_updates_tab(self):
        """Tab for checking and installing updates."""
        pass
    
    def create_privacy_tab(self):
        """Tab for privacy and telemetry control."""
        pass
    
    def run_async_operation(self, operation, callback):
        """Run operation in thread with progress updates."""
        def worker():
            try:
                result = operation()
                self.root.after(0, lambda: callback(result, None))
            except Exception as e:
                self.root.after(0, lambda: callback(None, e))
        
        thread = threading.Thread(target=worker, daemon=True)
        thread.start()
```

**Deliverables**:
- Enhanced GUI with new tabs
- Progress reporting framework
- Dark mode support
- Updated screenshots
- GUI user guide

---

#### 4.2 CLI Enhancements
**Priority**: MEDIUM | **Effort**: 1 week | **Owner**: TBD

**New Commands**:
```bash
# Updates
better11-cli update check
better11-cli update install <app-id>
better11-cli update install-all
better11-cli self-update

# Privacy
better11-cli privacy status
better11-cli privacy set-telemetry <level>
better11-cli privacy apply-preset <preset-name>

# Startup
better11-cli startup list
better11-cli startup disable <item-name>
better11-cli startup enable <item-name>

# Windows Updates
better11-cli windows-update check
better11-cli windows-update pause <days>
better11-cli windows-update resume

# Features
better11-cli features list
better11-cli features enable <feature-name>
better11-cli features apply-preset <preset-name>

# Config
better11-cli config show
better11-cli config set <key> <value>
better11-cli config reset
```

**Implementation**:
```python
# better11/cli.py (enhancements)
def create_update_parser(subparsers):
    update_parser = subparsers.add_parser('update', help='Update management')
    update_subparsers = update_parser.add_subparsers(dest='update_command')
    
    check_parser = update_subparsers.add_parser('check', help='Check for updates')
    install_parser = update_subparsers.add_parser('install', help='Install update')
    install_parser.add_argument('app_id', help='Application ID')
    # ...
```

**Deliverables**:
- Extended CLI with new commands
- Updated CLI documentation
- Help text for all commands
- Examples in USER_GUIDE.md

---

#### 4.3 Documentation Updates
**Priority**: HIGH | **Effort**: 1 week | **Owner**: TBD

**Documents to Update**:
1. **README.md**: Add v0.3.0 features
2. **USER_GUIDE.md**: Add sections for all new features
3. **API_REFERENCE.md**: Document new modules and classes
4. **CHANGELOG.md**: Complete v0.3.0 entry
5. **SECURITY.md**: Update with code signing information
6. **INSTALL.md**: Add new dependencies

**New Documents**:
1. **PRIVACY_GUIDE.md**: Comprehensive privacy guide
2. **UPDATE_GUIDE.md**: Update system documentation
3. **CONFIGURATION_GUIDE.md**: Configuration file documentation

**Deliverables**:
- Updated documentation (all files)
- New guides (3 documents)
- Code examples
- Screenshots

---

#### 4.4 Testing & Quality Assurance
**Priority**: CRITICAL | **Effort**: Ongoing | **Owner**: TBD

**Testing Goals**:
- 60+ total tests (from 31)
- 100% coverage on critical paths
- Integration tests for new features
- Performance tests
- Security tests

**Test Organization**:
```
tests/
├── test_config.py              (NEW - 15 tests)
├── test_code_signing.py        (NEW - 20 tests)
├── test_updater.py             (NEW - 20 tests)
├── test_updates.py             (NEW - 15 tests)
├── test_privacy.py             (NEW - 20 tests)
├── test_startup.py             (NEW - 15 tests)
├── test_features.py            (NEW - 12 tests)
├── test_base_classes.py        (NEW - 10 tests)
├── integration/                (NEW)
│   ├── test_update_workflow.py
│   ├── test_privacy_presets.py
│   └── test_config_migration.py
└── ... (existing tests)
```

**Deliverables**:
- 60+ tests passing
- Integration test suite
- Performance benchmarks
- Test documentation

---

## 📦 Dependencies

### New Python Packages

Add to `requirements.txt`:
```txt
# Existing dependencies (if any)
# ...

# v0.3.0 New Dependencies
tomli>=2.0.1; python_version < '3.11'  # TOML parsing for older Python
pyyaml>=6.0                             # YAML support
cryptography>=41.0.0                    # For signature verification (alternative approach)
pywin32>=305; sys_platform == 'win32'   # Windows COM APIs
requests>=2.31.0                        # For update checking (if not already present)
psutil>=5.9.0                           # System monitoring
packaging>=23.0                         # Version comparison
```

### External Tools

Document in INSTALL.md:
- PowerShell 5.1+ or PowerShell 7
- DISM (already required)
- Windows Update service
- Optional: Sysinternals Suite for advanced features

---

## 🗓️ Milestones & Timeline

### Week 1-2: Foundation
- ✅ Configuration system
- ✅ Base classes and interfaces
- ✅ Enhanced logging
- **Deliverable**: Foundation modules with tests

### Week 3-4: Code Signing
- ✅ Code signing verification
- ✅ Integration with installer pipeline
- ✅ Configuration options
- **Deliverable**: Signature verification working

### Week 5-6: System Management
- ✅ Windows Update management
- ✅ Privacy controls
- ✅ Startup manager (partial)
- **Deliverable**: 3 new system tools

### Week 7-8: Auto-Update
- ✅ Update checking
- ✅ Update installation
- ✅ Better11 self-update
- ✅ Startup manager (complete)
- **Deliverable**: Update system functional

### Week 9-10: Features & Polish
- ✅ Windows Features manager
- ✅ GUI enhancements
- ✅ CLI enhancements
- **Deliverable**: Feature complete

### Week 11: Testing & Documentation
- ✅ Comprehensive testing
- ✅ Documentation updates
- ✅ Bug fixes
- **Deliverable**: All tests passing

### Week 12: Release Preparation
- ✅ Final testing
- ✅ Performance optimization
- ✅ Release notes
- ✅ Version bump
- **Deliverable**: v0.3.0 Release

---

## 📊 Success Metrics

### Quantitative Goals
- ✅ 60+ tests (double from v0.2.0's 31)
- ✅ All tests passing
- ✅ 7+ new modules
- ✅ Code signing for 100% of vetted installers
- ✅ Update checking working for all apps
- ✅ Zero regressions

### Qualitative Goals
- ✅ Users trust Better11 with security features
- ✅ Automated updates work reliably
- ✅ Privacy controls are comprehensive
- ✅ Documentation is clear and complete
- ✅ GUI is more responsive and polished

---

## 🚧 Risks & Mitigations

### Technical Risks

**Risk 1: Code Signing Complexity**
- **Impact**: HIGH
- **Probability**: MEDIUM
- **Mitigation**: Start with PowerShell approach; fallback to simpler verification

**Risk 2: Windows Update API Changes**
- **Impact**: MEDIUM
- **Probability**: LOW
- **Mitigation**: Use multiple approaches; test on multiple Windows versions

**Risk 3: Performance Impact**
- **Impact**: MEDIUM
- **Probability**: MEDIUM
- **Mitigation**: Profile code; optimize critical paths; async operations

**Risk 4: Breaking Changes**
- **Impact**: HIGH
- **Probability**: LOW
- **Mitigation**: Maintain backward compatibility; configuration migration

### Schedule Risks

**Risk 1: Feature Creep**
- **Impact**: HIGH
- **Probability**: MEDIUM
- **Mitigation**: Stick to plan; defer nice-to-haves to v0.4.0

**Risk 2: Testing Takes Longer**
- **Impact**: MEDIUM
- **Probability**: MEDIUM
- **Mitigation**: Test incrementally; allocate buffer time

---

## 📝 Open Questions

1. **Code Signing**: PowerShell vs Win32 API? (Recommend: PowerShell initially)
2. **Update Server**: Where to host Better11 update manifests? (GitHub releases?)
3. **Telemetry**: Should Better11 collect usage telemetry? (Recommend: No)
4. **Licensing**: Any license changes for v0.3.0? (Recommend: Keep MIT)
5. **Presets**: How many privacy/startup presets to include? (Recommend: 3-4 each)

---

## 🎯 Definition of Done

A feature is "done" when:
- ✅ Code is written and follows project standards
- ✅ Type hints are complete
- ✅ Logging is comprehensive
- ✅ Tests are written and passing (15+ per module)
- ✅ Documentation is updated
- ✅ Code review completed (if team)
- ✅ Integration tests pass
- ✅ No regressions introduced

---

## 📚 References

- [Windows Update API Documentation](https://docs.microsoft.com/en-us/windows/win32/wua_sdk/portal)
- [Authenticode Signature Verification](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [DISM Reference](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-reference)
- [Windows Privacy Settings](https://docs.microsoft.com/en-us/windows/privacy/)
- [PowerShell DSC](https://docs.microsoft.com/en-us/powershell/dsc/overview)

---

**Last Updated**: December 9, 2025  
**Document Owner**: Better11 Development Team  
**Status**: APPROVED - Ready for Implementation
