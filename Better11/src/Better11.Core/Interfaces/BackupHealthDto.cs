// ============================================================================
// File: src/Better11.Core/Interfaces/BackupHealthDto.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

namespace Better11.Core.Interfaces;

/// <summary>
/// Represents the overall health status of the backup system.
/// </summary>
public sealed class BackupHealthDto
{
    /// <summary>Gets or sets the total backup count.</summary>
    public int TotalBackups { get; set; }

    /// <summary>Gets or sets the total storage used in bytes.</summary>
    public long TotalSizeBytes { get; set; }

    /// <summary>Gets or sets the count of healthy (verified) backups.</summary>
    public int HealthyCount { get; set; }

    /// <summary>Gets or sets the count of corrupted backups.</summary>
    public int CorruptedCount { get; set; }

    /// <summary>Gets or sets the age of the oldest backup in days.</summary>
    public int OldestBackupDays { get; set; }

    /// <summary>Gets or sets the age of the newest backup in days.</summary>
    public int NewestBackupDays { get; set; }

    /// <summary>Gets or sets the count of active schedules.</summary>
    public int ActiveSchedules { get; set; }

    /// <summary>Gets or sets a value indicating whether any backup is overdue.</summary>
    public bool HasOverdueBackups { get; set; }
}
