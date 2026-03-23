schtasks /create /tn "ConnorOS-Universal-PostInstall" `
  /tr "powershell.exe -ExecutionPolicy Bypass -File C:\Winutil\ConnorOS-Universal.ps1" `
  /sc onstart /ru SYSTEM /f
schtasks /create /tn "ConnorOS-Universal-PostInstall" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\Winutil\ConnorOS-Universal.ps1" /sc onstart /ru SYSTEM /f
