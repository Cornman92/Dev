function Build-ISO {
    Write-Log "Building Multi-Boot ISO..."

    oscdimg -n -m -bD:\My-Win[PE][RE]\Boot\etfsboot.com `
        -u2 -udfver102 `
        -bootdata:2#p0,e,bD:\My-Win[PE][RE]\Boot\etfsboot.com#pEF,e,bD:\My-Win[PE][RE]\Boot\efisys.bin `
        D:\My-Win[PE][RE]\CombinedISO `
        D:\My-Win[PE][RE]\Output\ISO\Combined-Environment.iso
}