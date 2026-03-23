. ".\modules\snapshot.ps1"
$dir=".\state\snapshots"
New-Item $dir -ItemType Directory -Force|Out-Null
New-Snapshot "$dir\snapshot-$(Get-Date -Format yyyyMMddHHmmss).json"
