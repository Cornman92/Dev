$root = "D:\My-Win[PE][RE]"

$folders = @(
    "$root\WinPE\base", "$root\WinPE\mount", "$root\WinPE\drivers\NVMe", "$root\WinPE\drivers\USB",
    "$root\WinPE\tools", "$root\WinPE\modules", "$root\WinPE\scripts",

    "$root\WinRE\base", "$root\WinRE\mount", "$root\WinRE\drivers\NVMe", "$root\WinRE\drivers\USB",
    "$root\WinRE\tools", "$root\WinRE\modules", "$root\WinRE\scripts",

    "$root\Hybrid\base", "$root\Hybrid\mount", "$root\Hybrid\drivers\NVMe", "$root\Hybrid\drivers\USB",
    "$root\Hybrid\tools", "$root\Hybrid\modules", "$root\Hybrid\scripts",

    "$root\Combined\Menu", "$root\Combined\Output",
    "$root\Output\WIMs", "$root\Output\ISO",
    "$root\Presets"
)

foreach ($folder in $folders) {
    New-Item -Path $folder -ItemType Directory -Force
}