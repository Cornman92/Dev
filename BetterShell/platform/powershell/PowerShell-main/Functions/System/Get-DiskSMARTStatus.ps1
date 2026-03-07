function Get-DiskSMARTStatus {
    [CmdletBinding()]
    param()

    Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus | Select-Object InstanceName, PredictFailure
}
