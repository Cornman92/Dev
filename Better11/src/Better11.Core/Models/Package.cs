namespace Better11.Core.Models;

public record Package
{
    public string Id { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Version { get; init; } = string.Empty;
    public string? AvailableVersion { get; init; }
    public PackageSource Source { get; init; }
    public string? Publisher { get; init; }
    public string? Description { get; init; }
    public bool IsInstalled { get; init; }
    public bool HasUpdate => !string.IsNullOrEmpty(AvailableVersion) && AvailableVersion != Version;
}

public enum PackageSource
{
    WinGet,
    Chocolatey,
    Scoop,
    NuGet,
    AppX,
    Msix,
}
