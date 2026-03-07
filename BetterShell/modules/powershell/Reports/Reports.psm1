function New-AuroraReport {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Data,[string]$OutDir = (Join-Path $PSScriptRoot '..\..\Output'))
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $jsonPath = Join-Path $OutDir ("report_{0}.json" -f $ts)
    $htmlPath = Join-Path $OutDir ("report_{0}.html" -f $ts)
    ($Data | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $jsonPath -Encoding UTF8
    $html = @"
<!DOCTYPE html><html><head><meta charset='utf-8'><title>Aurora Report</title>
<style>body{font-family:Segoe UI, Arial;margin:24px}pre{white-space:pre-wrap}</style></head><body>
<h1>Aurora Report</h1><p>Generated: $(Get-Date -Format o)</p>
<pre>$([System.Web.HttpUtility]::HtmlEncode(($Data | ConvertTo-Json -Depth 6)))</pre>
</body></html>
"@
    $html | Set-Content -LiteralPath $htmlPath -Encoding UTF8
    [pscustomobject]@{ Json=$jsonPath; Html=$htmlPath }
}
Export-ModuleMember -Function New-AuroraReport
