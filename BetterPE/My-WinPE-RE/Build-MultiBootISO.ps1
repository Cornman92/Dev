$root = "D:\My-Win[PE][RE]"
$isoOut = "$root\Output\ISO\Combined-Environment.iso"
$boot = "$root\Boot\etfsboot.com"
$efi = "$root\Boot\efisys.bin"

$buildDir = "$root\CombinedISO"
New-Item -ItemType Directory -Force -Path $buildDir

Copy-Item "$root\Combined\BCD" "$buildDir\boot\BCD" -Force
Copy-Item "$root\Output\WIMs\Combined.wim" "$buildDir\sources\boot.wim" -Force

oscdimg -n -m -b$boot -u2 -udfver102 `
     -bootdata:2#p0,e,b$boot#pEF,e,b$efi `
     $buildDir $isoOut