namespace Better11.Core.Models;

public record Driver
{
    public string DeviceName { get; init; } = string.Empty;
    public string ClassName { get; init; } = string.Empty;
    public string DriverVersion { get; init; } = string.Empty;
    public string? AvailableVersion { get; init; }
    public DateTime DriverDate { get; init; }
    public string Manufacturer { get; init; } = string.Empty;
    public string InfName { get; init; } = string.Empty;
    public DriverStatus Status { get; init; }
    public bool HasUpdate => !string.IsNullOrEmpty(AvailableVersion) && AvailableVersion != DriverVersion;
}

public enum DriverStatus
{
    OK,
    Degraded,
    Error,
    Unknown,
    Disabled,
}
