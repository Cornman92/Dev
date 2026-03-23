// ============================================================================
// File: src/Better11.Core/Interfaces/BackupStatus.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

namespace Better11.Core.Interfaces;

/// <summary>
/// Status of a backup operation or record.
/// </summary>
public enum BackupStatus
{
    /// <summary>Backup completed successfully.</summary>
    Success,

    /// <summary>Backup failed.</summary>
    Failed,

    /// <summary>Backup is in progress.</summary>
    InProgress,

    /// <summary>Backup is scheduled but not yet run.</summary>
    Pending,

    /// <summary>Backup was cancelled.</summary>
    Cancelled,

    /// <summary>Backup integrity check failed.</summary>
    Corrupted,
}
