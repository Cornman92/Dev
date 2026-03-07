
dism /Export-Image /SourceImageFile:WinPE_Custom.wim /SourceIndex:1 /DestinationImageFile:Combined.wim /Compress:Max /CheckIntegrity
dism /Export-Image /SourceImageFile:WinRE_Custom.wim /SourceIndex:1 /DestinationImageFile:Combined.wim /Compress:Max /CheckIntegrity
dism /Export-Image /SourceImageFile:Hybrid_Custom.wim /SourceIndex:1 /DestinationImageFile:Combined.wim /Compress:Max /CheckIntegrity
