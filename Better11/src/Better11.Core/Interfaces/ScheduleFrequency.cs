// ============================================================================
// File: src/Better11.Core/Interfaces/ScheduleFrequency.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

namespace Better11.Core.Interfaces;

/// <summary>
/// Frequency options for scheduled backups.
/// </summary>
public enum ScheduleFrequency
{
    /// <summary>Run once only.</summary>
    Once,

    /// <summary>Run every hour.</summary>
    Hourly,

    /// <summary>Run every day.</summary>
    Daily,

    /// <summary>Run every week.</summary>
    Weekly,

    /// <summary>Run every month.</summary>
    Monthly,
}
