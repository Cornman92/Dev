// ============================================================================
// File: src/Better11.Core/Interfaces/BackupType.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

namespace Better11.Core.Interfaces;

/// <summary>
/// Types of backups supported by the Backup &amp; Restore Manager.
/// </summary>
public enum BackupType
{
    /// <summary>Windows System Restore point.</summary>
    SystemRestore,

    /// <summary>Registry hive or key export.</summary>
    Registry,

    /// <summary>Application configuration folder snapshot.</summary>
    AppConfig,

    /// <summary>Combined disaster recovery bundle.</summary>
    DisasterRecovery,

    /// <summary>Differential backup (changes only).</summary>
    Differential,
}
