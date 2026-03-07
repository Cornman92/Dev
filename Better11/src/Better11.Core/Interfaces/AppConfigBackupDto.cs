// ============================================================================
// File: src/Better11.Core/Interfaces/AppConfigBackupDto.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.Generic;

namespace Better11.Core.Interfaces;

/// <summary>
/// Represents an application configuration snapshot.
/// </summary>
public sealed class AppConfigBackupDto
{
    /// <summary>Gets or sets the unique identifier.</summary>
    public string Id { get; set; } = Guid.NewGuid().ToString("N");

    /// <summary>Gets or sets the backup name.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Gets or sets the application name.</summary>
    public string AppName { get; set; } = string.Empty;

    /// <summary>Gets or sets the source folder paths that were backed up.</summary>
    public List<string> SourcePaths { get; set; } = new();

    /// <summary>Gets or sets the backup archive file path.</summary>
    public string ArchivePath { get; set; } = string.Empty;

    /// <summary>Gets or sets the file size in bytes.</summary>
    public long SizeBytes { get; set; }

    /// <summary>Gets or sets the creation date.</summary>
    public string CreatedDate { get; set; } = DateTime.UtcNow.ToString("o");

    /// <summary>Gets or sets the file count in the backup.</summary>
    public int FileCount { get; set; }

    /// <summary>Gets or sets the backup status.</summary>
    public BackupStatus Status { get; set; } = BackupStatus.Success;
}
