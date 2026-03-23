namespace Better11.Core.Models;

public record StartupItem
{
    public string Name { get; init; } = string.Empty;
    public string Command { get; init; } = string.Empty;
    public string Location { get; init; } = string.Empty;
    public string Publisher { get; init; } = string.Empty;
    public bool IsEnabled { get; init; }
    public StartupImpact Impact { get; init; }
}

public enum StartupImpact { None, Low, Medium, High, NotMeasured }
