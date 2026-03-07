function Show-ProgressBar {
    param(
        [int]$Percent,
        [string]$Message
    )

    Write-Progress -Activity $Message -Status "$Percent% Complete" -PercentComplete $Percent
}