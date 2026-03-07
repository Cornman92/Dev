@echo off
title Ultimate PE/RE/Hybrid Builder
color 0B

set ROOT=D:\My-Win[PE][RE]
set OUT=%ROOT%\Output
set WIMS=%OUT%\WIMs
set ISOOUT=%OUT%\ISO

echo ============================================
echo   ULTIMATE PE/RE/HYBRID BUILD AUTOMATION
echo ============================================
echo.

REM -----------------------------------------------------------
REM Create directories
REM -----------------------------------------------------------
echo [+] Creating required directories...
mkdir "%WIMS%" >nul 2>&1
mkdir "%ISOOUT%" >nul 2>&1
mkdir "%ROOT%\CombinedISO" >nul 2>&1

REM -----------------------------------------------------------
REM Build WinPE WIM
REM -----------------------------------------------------------
echo [+] Building WinPE image...
dism /Mount-WIM /WimFile:%ROOT%\WinPE\base\boot.wim /index:1 /MountDir:%ROOT%\WinPE\mount

powershell -ExecutionPolicy Bypass -File "%ROOT%\Tool-AutoSetup.ps1" -MountDir "%ROOT%\WinPE\mount" -ToolRoot "%ROOT%"

echo [+] Injecting WinPE drivers...
dism /Image:%ROOT%\WinPE\mount /Add-Driver /Driver:%ROOT%\WinPE\drivers\ /Recurse

echo [+] Committing WinPE build...
dism /Unmount-WIM /MountDir:%ROOT%\WinPE\mount /Commit

copy "%ROOT%\WinPE\base\boot.wim" "%WIMS%\WinPE_Custom.wim" /Y


REM -----------------------------------------------------------
REM Build WinRE WIM
REM -----------------------------------------------------------
echo [+] Building WinRE image...
dism /Mount-WIM /WimFile:%ROOT%\WinRE\base\winre.wim /index:1 /MountDir:%ROOT%\WinRE\mount

powershell -ExecutionPolicy Bypass -File "%ROOT%\Tool-AutoSetup.ps1" -MountDir "%ROOT%\WinRE\mount" -ToolRoot "%ROOT%"

echo [+] Injecting WinRE drivers...
dism /Image:%ROOT%\WinRE\mount /Add-Driver /Driver:%ROOT%\WinRE\drivers\ /Recurse

echo [+] Committing WinRE build...
dism /Unmount-WIM /MountDir:%ROOT%\WinRE\mount /Commit

copy "%ROOT%\WinRE\base\winre.wim" "%WIMS%\WinRE_Custom.wim" /Y


REM -----------------------------------------------------------
REM Build Hybrid WIM
REM -----------------------------------------------------------
echo [+] Building Hybrid image...
dism /Mount-WIM /WimFile:%ROOT%\Hybrid\base\hybrid.wim /index:1 /MountDir:%ROOT%\Hybrid\mount

powershell -ExecutionPolicy Bypass -File "%ROOT%\Tool-AutoSetup.ps1" -MountDir "%ROOT%\Hybrid\mount" -ToolRoot "%ROOT%"

echo [+] Injecting Hybrid drivers...
dism /Image:%ROOT%\Hybrid\mount /Add-Driver /Driver:%ROOT%\Hybrid\drivers\ /Recurse

echo [+] Committing Hybrid build...
dism /Unmount-WIM /MountDir:%ROOT%\Hybrid\mount /Commit

copy "%ROOT%\Hybrid\base\hybrid.wim" "%WIMS%\Hybrid_Custom.wim" /Y


REM -----------------------------------------------------------
REM Create Combined WIM
REM -----------------------------------------------------------
echo [+] Creating Combined WIM...

dism /Export-Image /SourceImageFile:%WIMS%\WinPE_Custom.wim /SourceIndex:1 /DestinationImageFile:%WIMS%\Combined.wim /Compress:max
dism /Export-Image /SourceImageFile:%WIMS%\WinRE_Custom.wim /SourceIndex:1 /DestinationImageFile:%WIMS%\Combined.wim /Compress:max
dism /Export-Image /SourceImageFile:%WIMS%\Hybrid_Custom.wim /SourceIndex:1 /DestinationImageFile:%WIMS%\Combined.wim /Compress:max


REM -----------------------------------------------------------
REM Create BCD for Combined Boot Menu
REM -----------------------------------------------------------
echo [+] Creating BCD boot menu...

set BCDSTORE=%ROOT%\Combined\BCD
bcdedit /createstore %BCDSTORE%

REM --- WinPE
for /f "tokens=2 delims={}" %%i in ('bcdedit /store %BCDSTORE% /create /d "WinPE Deployment Environment" /application osloader') do set PEID={%%i}
bcdedit /store %BCDSTORE% /set %PEID% device ramdisk=[boot]\sources\Combined.wim,{ramdiskoptions}
bcdedit /store %BCDSTORE% /set %PEID% path \windows\system32\boot\winload.exe

REM --- WinRE
for /f "tokens=2 delims={}" %%i in ('bcdedit /store %BCDSTORE% /create /d "WinRE Advanced Recovery" /application osloader') do set REID={%%i}
bcdedit /store %BCDSTORE% /set %REID% device ramdisk=[boot]\sources\Combined.wim,{ramdiskoptions}
bcdedit /store %BCDSTORE% /set %REID% path \windows\system32\boot\winload.exe

REM --- Hybrid
for /f "tokens=2 delims={}" %%i in ('bcdedit /store %BCDSTORE% /create /d "Hybrid Ultimate Tools" /application osloader') do set HYID={%%i}
bcdedit /store %BCDSTORE% /set %HYID% device ramdisk=[boot]\sources\Combined.wim,{ramdiskoptions}
bcdedit /store %BCDSTORE% /set %HYID% path \windows\system32\boot\winload.exe

REM --- Boot Menu Order + Timeout
bcdedit /store %BCDSTORE% /set {bootmgr} timeout 10
bcdedit /store %BCDSTORE% /set {bootmgr} displayorder %PEID% %REID% %HYID%


REM -----------------------------------------------------------
REM Build Multi-Boot ISO
REM -----------------------------------------------------------
echo [+] Building Multi-Boot ISO...

set BUILDDIR=%ROOT%\CombinedISO
mkdir "%BUILDDIR%\boot" >nul 2>&1
mkdir "%BUILDDIR%\sources" >nul 2>&1

copy "%BCDSTORE%" "%BUILDDIR%\boot\BCD" /Y
copy "%WIMS%\Combined.wim" "%BUILDDIR%\sources\boot.wim" /Y

oscdimg -n -m -b%ROOT%\Boot\etfsboot.com -u2 -udfver102 ^
-bootdata:2#p0,e,b%ROOT%\Boot\etfsboot.com#pEF,e,b%ROOT%\Boot\efisys.bin ^
%BUILDDIR% "%ISOOUT%\Combined-Environment.iso"


REM -----------------------------------------------------------
REM Done
REM -----------------------------------------------------------
echo.
echo ============================================
echo   Build Complete!
echo   Output ISO: %ISOOUT%\Combined-Environment.iso
echo ============================================
pause
exit