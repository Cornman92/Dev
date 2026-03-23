# GaymerPC TUI User Guide

A comprehensive guide for using the Terminal User Interfaces (TUIs) created
for the GaymerPC ecosystem

## 🚀 Quick Start

### Installation**Prerequisites: **- Python 3.7+ with pip

- PowerShell 5.1+ (Windows)

- Git (optional)
**Install Python Dependencies:**```bash

pip install textual

```text**Clone the Repository:**```bash

git clone <<https://github.com/Cornman92/gaymerpc-suite.git>>
cd gaymerpc-suite

```text

### Launch TUIs

#### Python TUIs (Textual Framework)

```bash

## Launch File Manager TUI

python GaymerPC/src/file_manager/ui/tui.py

## Launch GaymerPC Suite TUI

python GaymerPC/gaymerpc_tui.py

## Launch Environment Config TUI

python env-config/env_config_tui.py

## Launch Ownership Toolkit TUI

python OwnershipToolkit/ownership_tui.py

## Launch Electron App TUI

python electron-app/electron_tui.py

```text

### PowerShell TUIs (Native PowerShell)

```powershell

## Launch File Manager TUI (2)

.\GaymerPC\Scripts\Show-FileManagerTUI.ps1

## Launch GaymerPC Suite TUI (2)

.\GaymerPC\Scripts\Show-GaymerPCTUI.ps1

## Launch Environment Config TUI (2)

.\env-config\Show-EnvConfigTUI.ps1

## Launch Ownership Toolkit TUI (2)

.\OwnershipToolkit\Show-OwnershipTUI.ps1

## Launch Electron App TUI (2)

.\electron-app\Show-ElectronTUI.ps1

```text

### Unified Launcher

```bash

## Interactive launcher (recommended)

python launch_tuis.py

## Command line launcher

python launch_tuis.py file_manager
python launch_tuis.py --test
python launch_tuis.py --info

```text

## 📋 TUI Overview

### 1. File Manager TUI**Purpose:**Interactive file browser and management tool**Key Features:**-**Directory Navigation:**Browse files and folders with tree view

-**File Operations:**Copy, move, delete, rename files and directories

-**Advanced Search:**Pattern matching, size filters, date filters, content search

-**Duplicate Detection:**Find and manage duplicate files

-**File Organization:**Organize files by type, date, or size

-**System Integration:**Monitor system resources, processes, and
services**Navigation:**-**Arrow Keys:**Navigate through files and
directories

-**Enter:**Open directory or select file

-**Tab:**Switch between panels

-**F1-F10:**Quick access to common operations

-**Ctrl+C:**Copy selected files

-**Ctrl+V:**Paste files

-**Delete:**Delete selected files

### 2. GaymerPC Suite TUI**Purpose:**Unified project management interface**Key Features:**-**Project Overview:**View all GaymerPC components and their status

-**Module Management:**Install, update, and manage PowerShell modules

-**Tool Integration:**Launch other TUIs and tools

-**System Administration:**Access system management tools

-**Development Tools:**Code quality, testing, and build
management**Navigation:**-**Number Keys (1-5):**Select project categories

-**Enter:**Launch selected tool or view details

-**Tab:**Navigate between sections

-**Space:**Select/deselect items

### 3. Environment Configuration TUI**Purpose:**Multi-environment configuration management**Key Features:**-**Environment Switching:**Switch between dev/staging/prod/testing

-**Variable Management:**Edit environment variables with validation

-**Configuration Files:**Create, edit, delete config files

-**Import/Export:**Support for JSON, YAML, .env, and PowerShell formats

-**Validation:**Check for missing variables and placeholder
values**Usage:**1. Select environment (1-4)

1. Choose operation (1-20)

2. Follow prompts for file selection and editing

### 4. Ownership Toolkit TUI**Purpose:**PowerShell module and script management**Key Features:**-**Module Overview:**View installed modules and their status

-**Script Library:**Browse and execute utility scripts

-**Module Installation:**Install and update PowerShell modules

-**Test Execution:**Run test suites and view results

-**Search Functionality:**Find modules and scripts by name or
content**Usage:**1. Select category (1-10)

1. Choose specific operation

2. Follow prompts for execution

### 5. Electron App TUI**Purpose:**Development and build management for Electron applications**Key Features:**-**Development Workflow:**Start dev server, run tests, lint code

-**Build Management:**Create development and production builds

-**Package Creation:**Generate installers for multiple platforms

-**Distribution:**Manage releases and deployments

-**Build History:**Track build operations and results**Usage:**1. Select
development or build operation

1. Choose target platform or build type

2. Monitor progress and results

## 🎯 Advanced Usage

### File Manager Operations

#### Search Operations

```bash

## Pattern Search

Select option 5, then 1, enter "*.txt" for all text files

## Content Search

Select option 5, then 2, enter "password" to find files containing "password"

## Size Search

Select option 5, then 4, then 2, enter "100MB" for files over 100MB

## Date Search

Select option 5, then 4, then 3, enter "7" for files modified in last 7 days

```text

### File Selection

```bash

## Select by pattern

Select option 's', then 2, enter "*.log" for all log files

## Select by type

Select option 's', then 3, enter ".txt" for all text files

## Batch operations

Select files, then use options 2-4 for copy/move/delete operations

```text

### Environment Configuration

#### Multi-Environment Workflow

```bash

## Switch to production environment

Select option 7, then 2

## Edit production variables

Select option 2, then select config file

## Validate configuration

Select option 11 to check for issues

## Export for deployment

Select option 12, then 1 for JSON format

```text

### Module Management

#### PowerShell Module Operations

```bash

## View module statistics

Select option 1 for overview

## Install/update modules

Select option 2 to import all modules

## Search for specific functionality

Select option 5, enter "backup" to find backup-related modules

## Execute utility scripts

Select option 7, then choose script to run

```text

## 🔧 Configuration

### Environment Variables

Create `.env`files in the`envs/` directory:
**Development Environment: **```env

NODE_ENV=development
PORT=3000
DB_HOST=localhost
DEBUG=true

```text**Production Environment:**```env

NODE_ENV=production
PORT=80
DB_HOST=prod-db.example.com
DEBUG=false
SSL_CERT=/path/to/cert.pem

```text

### PowerShell Profile Integration

Add to your PowerShell profile:

```powershell

## Import GaymerPC modules

Import-Module "C:\path\to\gaymerpc-suite\Modules"

## Add TUI functions

function Launch-FileManagerTUI { &
"C:\path\to\gaymerpc-suite\GaymerPC\Scripts\Show-FileManagerTUI.ps1" }
function Launch-GaymerPCTUI { &
"C:\path\to\gaymerpc-suite\GaymerPC\Scripts\Show-GaymerPCTUI.ps1" }

```text

## 🚨 Troubleshooting

### Common Issues**"Module not found" errors:**- Ensure all dependencies are installed

- Check Python path and PowerShell module paths

- Run as Administrator for system modules**"Terminal too small" errors:**-
- Increase terminal window size (120x50 minimum recommended)

- TUIs will adapt but may have display issues**"Permission denied"
- errors:**- Run PowerShell as Administrator for system operations

- Check file/folder permissions

- Ensure antivirus isn't blocking operations**Import errors:**- Install
- missing dependencies: `pip install textual`- Check Python version
- compatibility (3.7+)

- Verify file paths are correct

### Getting Help

Each TUI includes:

-**Built-in help:**Option descriptions and usage tips

-**Error messages:**Specific guidance for issues

-**Status indicators:**Real-time operation feedback

-**Log files:**Detailed operation history

### Performance Optimization**For large directories:**- Use search filters to limit results

- Enable pagination for large file lists

- Use background operations for long-running tasks**For better
- performance:**- Close unused TUIs when not in use

- Use SSD storage for better I/O performance

- Monitor system resources during intensive operations

## 📚 Examples and Use Cases

### Example 1: File Organization Workflow

```bash

## Launch File Manager TUI (3)

python GaymerPC/src/file_manager/ui/tui.py

## Navigate to target directory

## Use 'n' to navigate, enter directory name

## Search for large files

## Select option 5 > 4 > 2, enter "500MB"

## Select and move files

## Select option 's' > 2, enter "*.zip"

## Select option 2, enter destination directory

## Verify organization

## Select option 1 to view updated directory

```text

### Example 2: Environment Setup

```bash

## Launch Environment Config TUI (3)

python env-config/env_config_tui.py

## Switch to production environment (2)

## Select option 7 > 2

## Create production config

## Select option 5 to create new file

## Select option 4 to save as "app.production.env"

## Edit variables

## Select option 2 > select file > edit values

## Validate and export

## Select option 11 > 12 > 1 for JSON export

```text

### Example 3: Module Management

```powershell

## Launch Ownership Toolkit TUI (3)

.\OwnershipToolkit\Show-OwnershipTUI.ps1

## View module statistics (2)

## Select option 1

## Install all modules

## Select option 2

## Search for backup functionality

## Select option 5, enter "backup"

## Run backup script

## Select option 7 > select backup script

```text

## 🔮 Advanced Features

### Custom Scripts and Automation**Create custom file operations: **```powershell

## Add to PowerShell profile

function Organize-Downloads {
& "C:\path\to\gaymerpc-suite\GaymerPC\Scripts\Show-FileManagerTUI.ps1"
  -Path "$HOME\Downloads"
}

```text**Automated cleanup:**```powershell

## Schedule with Task Scheduler

schtasks /create /tn "Daily Cleanup" /tr "powershell -File
'C:\path\to\cleanup-script.ps1'" /sc daily /st 02:00

```text

### Integration with Other Tools**VS Code Integration:**```json

// Add to settings.json
{
    "terminal.integrated.shellArgs.windows": [
        "-NoExit",
        "-Command", "& 'C:\\path\\to\\gaymerpc-suite\\launch_tuis.py'"
    ]
}

```text**Git Integration:**```bash

## Add aliases to .gitconfig

[alias]
    tui = !python C:/path/to/gaymerpc-suite/launch_tuis.py
    fm = !python C:/path/to/gaymerpc-suite/GaymerPC/src/file_manager/ui/tui.py

```text

## 📞 Support and Community

### Getting Help (2)

**Built-in Help:**- All TUIs include contextual help and option descriptions

- Use `--help`flag with launcher for command-line options

- Check error messages for specific troubleshooting
- steps**Documentation:**- This user guide covers all major features

- Check`TUI_PROJECT_SUMMARY.md`for technical details

- Review`TUIs_README.md` for quick reference**Community:**- GitHub Issues:
- Report bugs and request features

- Discussions: Share tips and ask questions

- Wiki: Contribute tutorials and examples

### Contributing**Development Setup:**```bash

git clone <<https://github.com/Cornman92/gaymerpc-suite.git>>
cd gaymerpc-suite
pip install -r requirements.txt

```text**Running Tests:**```bash

python test_tuis.py          # Python TUI tests

.\Test-PowerShellTUIs.ps1    # PowerShell TUI tests

```text**Code Style:**- Follow PEP 8 for Python code

- Use PowerShell best practices for PowerShell code

- Include comprehensive docstrings and comments

## 🎯 Best Practices

### File Management

-**Regular cleanup:**Use automated cleanup for temporary files

-**Organized structure:**Maintain consistent directory organization

-**Backup strategy:**Regular backups before major operations

-**Search efficiency:**Use specific patterns rather than broad searches

### Environment Management

-**Environment isolation:**Keep environments separate and well-documented

-**Variable validation:**Always validate configurations before deployment

-**Version control:**Track configuration changes with your codebase

-**Security:**Never commit sensitive data to version control

### Module Management (2)

-**Regular updates:**Keep modules current for security and features

-**Dependency management:**Track and update module dependencies

-**Testing:**Test module functionality after updates

-**Documentation:**Maintain documentation for custom modules

## 📈 Performance Tips

### System Resources

-**Memory usage:**TUIs are lightweight but close unused instances

-**CPU usage:**Background operations may use CPU for large file operations

-**Disk I/O:**Large file operations benefit from SSD storage

-**Network:**Some operations may require internet connectivity

### Optimization Strategies

-**Batch operations:**Process multiple files together when possible

-**Search filters:**Use specific criteria to limit result sets

-**Caching:**Results are cached for improved performance

-**Background processing:**Long operations run in background when possible

## 🔐 Security Considerations

### File Operations

-**Permission checks:**TUIs respect Windows file permissions

-**Safe deletion:**Confirmation prompts for destructive operations

-**Audit trails:**Operation history for compliance

-**Access control:**Run with appropriate user privileges

### Configuration Management

-**Sensitive data:**Never store passwords in plain text

-**Environment isolation:**Keep production credentials secure

-**Access logging:**Track who accesses sensitive configurations

-**Encryption:**Use encryption for sensitive configuration data

## 🚀 Future Enhancements

### Planned Features

-**Web interface:**Remote access via web browser

-**Mobile apps:**iOS/Android companion applications

-**Cloud integration:**Direct cloud storage support

-**Plugin system:**Custom extensions and integrations

-**AI assistance:**Intelligent file organization and suggestions

### Community Contributions

-**Extension API:**Framework for custom TUI extensions

-**Theme system:**Customizable appearance and layouts

-**Localization:**Multi-language support

-**Accessibility:**Enhanced support for screen readers and assistive technologies

---
**Last Updated:**2024**Version:**1.0.0**Support:**GitHub Issues and Discussions
