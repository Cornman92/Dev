#Requires -Version 7.0
using namespace System.Collections.Concurrent
using namespace System.Collections.Generic
using namespace System.Threading.Tasks

$script:JobQueue = [ConcurrentQueue[hashtable]]::new()
$script:JobResults = [ConcurrentDictionary[string, hashtable]]::new()

function Invoke-B11Parallel {
    [CmdletBinding()][OutputType([PSCustomObject[]])]
    param([Parameter(Mandatory,ValueFromPipeline)][object[]]$InputObject, [Parameter(Mandatory)][scriptblock]$ScriptBlock, [int]$ThrottleLimit = [Environment]::ProcessorCount, [int]$TimeoutSeconds = 300)
    begin { $items = [List[object]]::new() }
    process { foreach ($obj in $InputObject) { $items.Add($obj) } }
    end {
        $results = [ConcurrentBag[PSCustomObject]]::new()
        $items | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
            $r = [PSCustomObject]@{ Input = $_; Output = $null; Success = $true; Error = $null; Duration = [timespan]::Zero }
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            try { $r.Output = & $using:ScriptBlock $_ } catch { $r.Success = $false; $r.Error = $_.ToString() }
            $sw.Stop(); $r.Duration = $sw.Elapsed
            ($using:results).Add($r)
        }
        $results | Sort-Object { $_.Input }
    }
}

function New-B11ParallelJob {
    [CmdletBinding()][OutputType([PSCustomObject])]
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][scriptblock]$ScriptBlock, [hashtable]$Parameters = @{})
    $id = "job_$(Get-Random -Maximum 999999)"
    $job = @{ Id = $id; Name = $Name; ScriptBlock = $ScriptBlock; Parameters = $Parameters; Status = 'Queued'; CreatedAt = [datetime]::UtcNow }
    $script:JobQueue.Enqueue($job)
    $null = $script:JobResults.TryAdd($id, $job)
    [PSCustomObject]@{ PSTypeName = 'B11.ParallelJob'; Id = $id; Name = $Name; Status = 'Queued' }
}

function Start-B11JobQueue {
    [CmdletBinding()][OutputType([PSCustomObject[]])]
    param([int]$MaxConcurrent = [Environment]::ProcessorCount)
    $batch = [List[hashtable]]::new()
    $item = $null
    while ($script:JobQueue.TryDequeue([ref]$item)) { $batch.Add($item) }
    $results = [List[PSCustomObject]]::new()
    $batch | ForEach-Object -ThrottleLimit $MaxConcurrent -Parallel {
        $j = $_; $j.Status = 'Running'
        try { $j.Output = & $j.ScriptBlock @($j.Parameters); $j.Status = 'Completed' } catch { $j.Status = 'Failed'; $j.Error = $_.ToString() }
        $j.FinishedAt = [datetime]::UtcNow
    }
    foreach ($j in $batch) { $results.Add([PSCustomObject]@{ PSTypeName = 'B11.JobResult'; Id = $j.Id; Name = $j.Name; Status = $j.Status; Error = $j.Error }) }
    $results
}

function Get-B11ParallelJob {
    [CmdletBinding()][OutputType([PSCustomObject])]
    param([string]$Id, [string]$Status)
    $jobs = $script:JobResults.Values
    if ($Id) { $jobs = $jobs | Where-Object { $_.Id -eq $Id } }
    if ($Status) { $jobs = $jobs | Where-Object { $_.Status -eq $Status } }
    foreach ($j in $jobs) { [PSCustomObject]@{ PSTypeName = 'B11.ParallelJob'; Id = $j.Id; Name = $j.Name; Status = $j.Status; CreatedAt = $j.CreatedAt } }
}

function Wait-B11ParallelJob {
    [CmdletBinding()][OutputType([PSCustomObject])]
    param([Parameter(Mandatory)][string]$Id, [int]$TimeoutSeconds = 120)
    $deadline = [datetime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([datetime]::UtcNow -lt $deadline) {
        if ($script:JobResults.ContainsKey($Id) -and $script:JobResults[$Id].Status -in @('Completed','Failed')) { break }
        Start-Sleep -Milliseconds 100
    }
    Get-B11ParallelJob -Id $Id
}

function Clear-B11JobQueue {
    [CmdletBinding(SupportsShouldProcess)][OutputType([void])]
    param()
    if ($PSCmdlet.ShouldProcess('Job queue', 'Clear all queued jobs')) {
        $item = $null; while ($script:JobQueue.TryDequeue([ref]$item)) { }
    }
}

function Get-B11ParallelStatistics {
    [CmdletBinding()][OutputType([PSCustomObject])]
    param()
    $all = $script:JobResults.Values
    [PSCustomObject]@{ PSTypeName = 'B11.ParallelStats'; Total = $all.Count; Queued = ($all | Where-Object { $_.Status -eq 'Queued' }).Count; Running = ($all | Where-Object { $_.Status -eq 'Running' }).Count; Completed = ($all | Where-Object { $_.Status -eq 'Completed' }).Count; Failed = ($all | Where-Object { $_.Status -eq 'Failed' }).Count }
}

function Invoke-B11ParallelPipeline {
    [CmdletBinding()][OutputType([PSCustomObject[]])]
    param([Parameter(Mandatory)][object[]]$InputObject, [Parameter(Mandatory)][scriptblock[]]$Stages, [int]$ThrottleLimit = [Environment]::ProcessorCount)
    $current = $InputObject
    foreach ($stage in $Stages) {
        $current = $current | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel { & $using:stage $_ }
    }
    $current
}

function Stop-B11ParallelJob {
    [CmdletBinding(SupportsShouldProcess)][OutputType([void])]
    param([Parameter(Mandatory)][string]$Id)
    if ($PSCmdlet.ShouldProcess($Id, 'Cancel parallel job')) {
        if ($script:JobResults.ContainsKey($Id)) { $script:JobResults[$Id].Status = 'Cancelled' }
    }
}

function Measure-B11ParallelPerformance {
    [CmdletBinding()][OutputType([PSCustomObject])]
    param([Parameter(Mandatory)][scriptblock]$ScriptBlock, [Parameter(Mandatory)][object[]]$InputObject, [int[]]$ThrottleLimits = @(1, 2, 4, 8))
    $results = foreach ($limit in $ThrottleLimits) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $InputObject | ForEach-Object -ThrottleLimit $limit -Parallel { & $using:ScriptBlock $_ } | Out-Null
        $sw.Stop()
        [PSCustomObject]@{ ThrottleLimit = $limit; Duration = $sw.Elapsed; ItemsPerSecond = [math]::Round($InputObject.Count / $sw.Elapsed.TotalSeconds, 2) }
    }
    $results
}

Export-ModuleMember -Function @(
    'Invoke-B11Parallel', 'New-B11ParallelJob', 'Start-B11JobQueue',
    'Get-B11ParallelJob', 'Wait-B11ParallelJob', 'Clear-B11JobQueue',
    'Get-B11ParallelStatistics', 'Invoke-B11ParallelPipeline',
    'Stop-B11ParallelJob', 'Measure-B11ParallelPerformance'
)
