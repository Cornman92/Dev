namespace Better11.Core.Models;

public record SystemInfo
{
    public string ComputerName { get; init; } = string.Empty;
    public string OSName { get; init; } = string.Empty;
    public string OSVersion { get; init; } = string.Empty;
    public string OSBuild { get; init; } = string.Empty;
    public string Architecture { get; init; } = string.Empty;
    public string Processor { get; init; } = string.Empty;
    public int ProcessorCores { get; init; }
    public long TotalMemoryBytes { get; init; }
    public long AvailableMemoryBytes { get; init; }
    public string GpuName { get; init; } = string.Empty;
    public string BiosVersion { get; init; } = string.Empty;
    public bool IsUefi { get; init; }
    public bool IsSecureBootEnabled { get; init; }
    public bool IsTpmPresent { get; init; }
    public TimeSpan Uptime { get; init; }
    public DateTime LastBootTime { get; init; }
    public int HealthScore { get; init; }

    public string TotalMemoryFormatted => $"{TotalMemoryBytes / (1024.0 * 1024 * 1024):F1} GB";
    public string UptimeFormatted => Uptime.TotalDays >= 1
        ? $"{(int)Uptime.TotalDays}d {Uptime.Hours}h"
        : $"{Uptime.Hours}h {Uptime.Minutes}m";
}
