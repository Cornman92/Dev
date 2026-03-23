function Test-Tool { param([string]$Name,[string[]]$Candidates) foreach ($c in $Candidates) { if (Test-Path $c) { return $c } } $p=Get-Command $Name -ErrorAction SilentlyContinue; if($p){return $p.Path}; return $null }
function Start-AuroraBenchmarks {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([switch]$Disk,[switch]$CPU,[switch]$GPU,[switch]$Memory,[string]$OutDir=(Join-Path $PSScriptRoot '..\..\Output'))
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
    $runs=@()
    if($Disk){ $cdm=Test-Tool -Name 'CrystalDiskMark.exe' -Candidates @('C:\Program Files\CrystalDiskMark\CrystalDiskMark.exe','C:\Program Files (x86)\CrystalDiskMark\CrystalDiskMark.exe'); if($cdm){ $runs+=[pscustomobject]@{Name='CrystalDiskMark';Path=$cdm;Args='';Type='Disk'} } }
    if($CPU){ $cine=Test-Tool -Name 'Cinebench.exe' -Candidates @('C:\Program Files\Maxon\Cinebench 2024\Cinebench.exe'); if($cine){ $runs+=[pscustomobject]@{Name='Cinebench';Path=$cine;Args='';Type='CPU'} } }
    if($GPU){ $ung=Test-Tool -Name 'Unigine_Superposition.exe' -Candidates @('C:\Program Files (x86)\Unigine\Superposition Benchmark\bin\Unigine_Superposition.exe'); if($ung){ $runs+=[pscustomobject]@{Name='Unigine Superposition';Path=$ung;Args='';Type='GPU'} } }
    if($Memory){ $aida=Test-Tool -Name 'aida64.exe' -Candidates @('C:\Program Files (x86)\FinalWire\AIDA64 Extreme\aida64.exe'); if($aida){ $runs+=[pscustomobject]@{Name='AIDA64';Path=$aida;Args='/BENCHMEM';Type='Memory'} } }
    $results=@()
    foreach($r in $runs){
        if($PSCmdlet.ShouldProcess($r.Name,'Launch benchmark')){
            try{ $p=Start-Process -FilePath $r.Path -ArgumentList $r.Args -PassThru; $results+=[pscustomobject]@{Tool=$r.Name;Started=$true;Pid=$p.Id;Type=$r.Type} }
            catch{ $results+=[pscustomobject]@{Tool=$r.Name;Started=$false;Error=$_.Exception.Message;Type=$r.Type} }
        } else { $results+=[pscustomobject]@{Tool=$r.Name;WhatIf=$true;Type=$r.Type} }
    }
    return $results
}
Export-ModuleMember -Function Start-AuroraBenchmarks
