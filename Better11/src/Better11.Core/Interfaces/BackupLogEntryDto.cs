// ============================================================================
// File: src/Better11.Core/Interfaces/BackupLogEntryDto.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

namespace Better11.Core.Interfaces;

/// <summary>
/// Represents a single entry in the backup history log.
/// </summary>
public sealed class BackupLogEntryDto
{
    /// <summary>Gets or sets the log entry identifier.</summary>
    public string Id { get; set; } = Guid.NewGuid().ToString("N");

    /// <summary>Gets or sets the timestamp.</summary>
    public string Timestamp { get; set; } = DateTime.UtcNow.ToString("o");

    /// <summary>Gets or sets the backup type.</summary>
    public BackupType BackupType { get; set; }

    /// <summary>Gets or sets the operation (Backup, Restore, Delete, Verify).</summary>
    public string Operation { get; set; } = string.Empty;

    /// <summary>Gets or sets the target description.</summary>
    public string Target { get; set; } = string.Empty;

    /// <summary>Gets or sets the status.</summary>
    public BackupStatus Status { get; set; } = BackupStatus.Success;

    /// <summary>Gets or sets the result message or error details.</summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>Gets or sets the duration in milliseconds.</summary>
    public long DurationMs { get; set; }
}
