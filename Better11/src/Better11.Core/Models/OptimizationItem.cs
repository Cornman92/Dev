namespace Better11.Core.Models;

public record OptimizationItem
{
    public string Id { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public string Category { get; init; } = string.Empty;
    public SafetyTier Safety { get; init; }
    public bool IsEnabled { get; init; }
    public bool IsReversible { get; init; } = true;
    public string? UndoCommand { get; init; }
    public string ApplyCommand { get; init; } = string.Empty;
}

public enum SafetyTier { Safe, Moderate, Advanced, Expert }
