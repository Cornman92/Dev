namespace Better11.Core.Models;

public record ServiceItem
{
    public string Name { get; init; } = string.Empty;
    public string DisplayName { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string StartType { get; init; } = string.Empty;
    public string Account { get; init; } = string.Empty;
    public bool CanStop { get; init; }
    public bool CanPause { get; init; }
}
