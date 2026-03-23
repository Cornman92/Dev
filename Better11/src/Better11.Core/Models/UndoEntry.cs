namespace Better11.Core.Models;

public record UndoEntry
{
    public string Id { get; init; } = Guid.NewGuid().ToString("N");
    public string OperationName { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public DateTime Timestamp { get; init; } = DateTime.UtcNow;
    public string Module { get; init; } = string.Empty;
    public string UndoCommand { get; init; } = string.Empty;
    public Dictionary<string, string> Metadata { get; init; } = new();
    public bool IsReverted { get; init; }
}
