# 🛠️ GaymerPC Ultimate Suite - Installation Guide

## 📋 **Pre-Installation Checklist**Before installing GaymerPC Ultimate Suite

ensure your system meets the requirements and you have the necessary permissions

### **System Requirements**-**Operating System**: Windows 11 Pro x64 24H2 (recommended)

-**CPU**: Intel i5-9600K or equivalent (6 cores, 3.7GHz base)

-**GPU**: NVIDIA RTX 3060 Ti or equivalent (8GB VRAM)

-**RAM**: 32GB DDR4-3200 (minimum 16GB)

-**Storage**: 50GB free space on SSD (recommended)

-**Network**: Internet connection for dependency downloads

### **Software Requirements**-**Python**: 3.11 or higher

-**PowerShell**: 7.0 or higher

-**Git**: Latest version

-**NVIDIA Drivers**: Latest Game Ready drivers

-**Visual Studio Code**: Recommended for development

### **Administrator Privileges**Some features require administrator privileges

- GPU power limit adjustments

- System service management

- Registry modifications

- Driver installations

---

## 🚀**Installation Methods**###**Method 1: Quick Installation (Recommended)**####**Step 1: Download and Clone**```bash

## Open PowerShell as Administrator

## Navigate to your desired installation directory

cd C:\Users\%USERNAME%\Desktop

## Clone the repository

git clone <<https://github.com/C-Man-Dev/GaymerPC-Suite.git>>
cd GaymerPC-Suite

```powershell

### **Step 2: Run Automated Setup**```bash

## Run the automated setup script

.\setup.ps1

## This will

## - Install Python dependencies

## - Install Node.js dependencies

## - Setup Docker (optional)

## - Configure environment variables

## - Validate system requirements

```

### **Step 3: Verify Installation**```bash

## Run the test suite

python test-setup.py

## Launch the main interface

.\Scripts\Show-GaymerPCTUI.ps1

```powershell

### **Method 2: Manual Installation**####**Step 1: Download Repository**```bash

## Download ZIP file from GitHub

## Extract to desired location

## Navigate to extracted folder

cd GaymerPC-Suite

```

### **Step 2: Install Python Dependencies**```bash

## Install core dependencies

pip install -r requirements.txt

## Install optional dependencies for full functionality

pip install scikit-learn SpeechRecognition pyttsx3 pyaudio matplotlib
pandas numpy schedule joblib

```powershell

### **Step 3: Install Node.js Dependencies**```bash

## Install Node.js dependencies

npm install

## Install development dependencies (optional)

npm install --save-dev electron

```

### **Step 4: Configure Environment**```bash

## Copy environment template

copy .env.template .env

## Edit .env file with your system information

## Set your hardware specifications

## Configure paths and preferences

```powershell

### **Step 5: Setup Pre-commit Hooks**```bash

## Install pre-commit

pip install pre-commit

## Install hooks

pre-commit install

## Run on all files (optional)

pre-commit run --all-files

```

---

## 🔧**Component-Specific Installation**###**Gaming Suite

Installation**####**Prerequisites**- NVIDIA GPU with latest drivers

- nvidia-smi accessible in PATH

- Administrator privileges for GPU settings

### **Installation Steps**```bash

## Navigate to Gaming Suite

cd GaymerPC\Gaming-Suite

## Install gaming-specific dependencies

pip install GPUtil psutil winreg wmi

## Test GPU detection

python -c "import GPUtil; print(GPUtil.getGPUs())"

## Launch Gaming Suite

.\Scripts\Launch-GamingSuite.ps1 -Mode TUI

```powershell

### **Verification**```bash

## Run gaming suite tests

python test-gaming-features.py

## Check GPU detection

nvidia-smi

## Test profile application

.\Scripts\Launch-GamingSuite.ps1 -Mode Optimizer -Profile competitive

```

### **AI Command Center Installation**####**Prerequisites**- Microphone and speakers/headphones

- Internet connection for speech recognition

- Audio drivers properly installed

#### **Installation Steps**```bash

## Navigate to AI Command Center

cd GaymerPC\AI-Command-Center

## Install AI-specific dependencies

pip install scikit-learn pandas numpy schedule
pip install SpeechRecognition pyttsx3 pyaudio

## Test speech recognition

python -c "import speech_recognition as sr; print('Speech recognition ready')"

## Launch AI Command Center

.\Scripts\Launch-AICommandCenter.ps1 -Mode TUI

```powershell

### **Microphone Setup**1.**Windows Settings**→**Privacy &

Security**→**Microphone**2.**Allow apps to access your
microphone**→**On**3.**Allow desktop apps to access your
microphone**→**On**4.**Test microphone**in Windows Sound settings

#### **Verification**```bash

## Run AI Command Center tests

python test-ai-command-center.py

## Test voice commands

.\Scripts\Launch-AICommandCenter.ps1 -Mode Voice -EnableVoice

## Say "Hey C-Man, hello"

```

---

## 🐳**Docker Installation (Optional)**###**Prerequisites**- Docker Desktop installed

- WSL2 enabled (Windows)

- 8GB RAM available for containers

### **Installation Steps**```bash (2)

## Build Docker image

docker build -t gaymerpc-suite:latest

## Run container

docker-compose up -d

## Access container

docker exec -it gaymerpc_suite bash

```powershell

### **Docker Compose Configuration**```yaml

version: '3.8'
services:
  gaymerpc:
    build: .
    container_name: gaymerpc_suite
    volumes:

      - .:/app
    environment:

      - GAYMERPC_USER=${GAYMERPC_USER}
      - GAYMERPC_HARDWARE_CPU=${GAYMERPC_HARDWARE_CPU}
      - GAYMERPC_HARDWARE_GPU=${GAYMERPC_HARDWARE_GPU}
      - GAYMERPC_HARDWARE_RAM=${GAYMERPC_HARDWARE_RAM}
    ports:

      - "8000:8000"

```---

## 🔐**Security Configuration**###**Firewall Rules**Configure Windows Firewall to allow GaymerPC components

```powershell

## Allow Python applications

New-NetFirewallRule -DisplayName "GaymerPC Python" -Direction Inbound
-Protocol TCP -LocalPort 8000 -Action Allow

## Allow PowerShell scripts

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

```### **Antivirus Exclusions**Add these paths to your antivirus exclusions:

-`C:\Users\%USERNAME%\GaymerPC-Suite\`-`%APPDATA%\GaymerPC\`-`%TEMP%\GaymerPC\`

### **User Account Control (UAC)**Some features require UAC elevation

- GPU power limit changes

- System service management

- Registry modifications

---

## 📊**Performance Optimization**###**System Optimization**####**Power Plan Configuration**```powershell

## Set high performance power plan

powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

## Disable USB selective suspend

powercfg -setacvalueindex SCHEME_CURRENT
2a737441-1930-4408-8cf2-0c6e7c3e3d3f 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

## Apply settings

powercfg -setactive SCHEME_CURRENT

```powershell

### **Windows Search Optimization**```powershell

## Disable Windows Search indexing for performance

Set-Service -Name "WSearch" -StartupType Disabled
Stop-Service -Name "WSearch"

```

### **Visual Effects Optimization**```powershell

## Disable visual effects for better performance

Set-ItemProperty -Path
  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name
  "VisualFXSetting" -Value 2

```powershell

### **Gaming Optimization**####**NVIDIA Control Panel Settings**1.**Open NVIDIA

Control Panel**2.**Manage 3D Settings**→**Global Settings**3.**Power management
mode**:**Prefer maximum performance**4.**Vertical
sync**:**Off**5.**Multi-display/mixed GPU acceleration**:**Single display
performance mode**####**Windows Game Mode**```powershell

## Enable Windows Game Mode

Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name
"AllowAutoGameMode" -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name
"AutoGameModeEnabled" -Value 1

```

---

## 🧪**Testing and Validation**###**System Validation**```bash

## Run comprehensive system test

python test-setup.py

## Expected output

## ✅ All critical imports successful

## ✅ System information retrieved

## ✅ File structure validated

## ✅ GaymerPC structure validated

```powershell

### **Gaming Suite Validation**```bash

## Run gaming suite tests (2)

python test-gaming-features.py

## Expected output (2)

## ✅ Critical Imports: PASS

## ✅ GPU Detection: PASS

## ✅ NVIDIA SMI: PASS

## ✅ Gaming Modules: PASS

## ✅ TUI Components: PASS

## ✅ PowerShell Scripts: PASS

## ✅ File Structure: PASS

## ✅ Performance Benchmarks: PASS

## ✅ Gaming Optimization: PASS

```

### **AI Command Center Validation**```bash

## Run AI Command Center tests (2)

python test-ai-command-center.py

## Expected output (3)

## ✅ Critical Imports: PASS (or PARTIAL)

## ✅ AI Modules: PASS

## ✅ TUI Components: PASS (2)

## ✅ PowerShell Scripts: PASS (2)

## ✅ File Structure: PASS (2)

## ✅ Voice Command Features: PASS

## ✅ Predictive Optimization: PASS

## ✅ Intelligent Automation: PASS

## ✅ Integration Features: PASS

## ✅ Performance Benchmarks: PASS (2)

```powershell

---

## 🔄**Updates and Maintenance**###**Automatic Updates**```bash

## Pull latest changes

git pull origin main

## Update dependencies

pip install -r requirements.txt --upgrade

## Run setup again for new features

.\setup.ps1

```

### **Manual Updates**```bash

## Update specific components

cd GaymerPC\Gaming-Suite
git pull origin main
pip install -r requirements.txt --upgrade

cd ..\AI-Command-Center
git pull origin main
pip install -r requirements.txt --upgrade

```powershell

### **Backup and Restore**```bash

## Backup configuration

.\Scripts\Backup-Configuration.ps1

## Restore configuration

.\Scripts\Restore-Configuration.ps1 -BackupFile "backup_20251015.json"

```

---

## 🆘**Troubleshooting Installation**###**Common Issues**####**Python Not Found**```bash

## Add Python to PATH

setx PATH "%PATH%;C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python311"
setx PATH
"%PATH%;C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python311\Scripts"

## Restart PowerShell and try again

python --version
pip --version

```powershell

### **PowerShell Execution Policy**```powershell

## Set execution policy

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

## Verify policy

Get-ExecutionPolicy -Scope CurrentUser

```

### **NVIDIA Drivers Not Found**```bash

## Download latest drivers from NVIDIA

## Install with clean installation option

## Verify installation

nvidia-smi

## If nvidia-smi not in PATH, add NVIDIA directory

setx PATH "%PATH%;C:\Program Files\NVIDIA Corporation\NVSMI"

```powershell

### **Microphone Not Working**```bash

## Check microphone permissions

## Windows Settings → Privacy & Security → Microphone

## Allow desktop apps to access microphone

## Test microphone

python -c "import pyaudio; p = pyaudio.PyAudio(); print('Microphones:',
p.get_device_count())"

```

### **Dependencies Installation Failed**```bash

## Upgrade pip first

python -m pip install --upgrade pip

## Install with verbose output

pip install -r requirements.txt -v

## Install packages individually if batch fails

pip install psutil
pip install GPUtil
pip install textual
pip install rich

```### **Log Files**Check these log files for detailed error information:

-**Setup Logs**:`Logs\setup_YYYYMMDD.log`-**Gaming
Suite**:`GaymerPC\Gaming-Suite\Logs\`-**AI Command
Center**:`GaymerPC\AI-Command-Center\Logs\`### **Getting Help**If you encounter
issues:
1.**Check the troubleshooting section**above
2.**Review log files**for error details
3.**Search existing issues**on GitHub
4.**Create a new issue**with detailed information
5.**Join our Discord**for real-time support

---

## ✅**Installation Complete**Once installation is complete, you should have

- ✅**GaymerPC Ultimate Suite**installed and configured

- ✅**Gaming Suite**with RTX 3060 Ti optimization

- ✅**AI Command Center**with voice commands

- ✅**All dependencies**installed and working

- ✅**Test suites**passing validation

- ✅**System optimized**for gaming and AI workloads

### **Next Steps**1.**Launch Gaming

Suite**:`.\GaymerPC\Gaming-Suite\Scripts\Launch-GamingSuite.ps1 -Mode
TUI`2.**Enable AI
Commands**:`.\GaymerPC\AI-Command-Center\Scripts\Launch-AICommandCenter.ps1
-Mode Voice -EnableVoice`3.**Read the documentation**:` docs\README.md`

4.**Join the community**: [Discord Server](<https://discord.gg/gaymerpc>)
**Welcome to GaymerPC Ultimate Suite!**🎮✨

---
*Last updated: October 15, 2025*

*Version: 1.0.0*

* Author: C-Man Development Team*
