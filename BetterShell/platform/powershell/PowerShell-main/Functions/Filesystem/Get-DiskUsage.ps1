function Get-DiskUsage {
    [CmdletBinding()]
    param()

    Get-PSDrive | Where-Object {$_.Provider -like '*FileSystem*'} | Select-Object Name, Used, Free, @{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}}, @{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}
}
