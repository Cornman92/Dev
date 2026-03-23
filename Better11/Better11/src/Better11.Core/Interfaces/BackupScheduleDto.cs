// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>Backup schedule DTO.</summary>
public sealed class BackupScheduleDto
{
    /// <summary>Gets or sets the schedule name.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Gets or sets the source path.</summary>
    public string SourcePath { get; set; } = string.Empty;

    /// <summary>Gets or sets the destination path.</summary>
    public string DestinationPath { get; set; } = string.Empty;

    /// <summary>Gets or sets the frequency (e.g. Daily, Weekly).</summary>
    public string Frequency { get; set; } = string.Empty;

    /// <summary>Gets or sets the retention in days.</summary>
    public int RetentionDays { get; set; }

    /// <summary>Gets or sets the next run time.</summary>
    public string NextRun { get; set; } = string.Empty;

    /// <summary>Gets or sets a value indicating whether the schedule is enabled.</summary>
    public bool Enabled { get; set; }
}
