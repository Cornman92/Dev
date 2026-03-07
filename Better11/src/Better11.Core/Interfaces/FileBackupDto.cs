// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>File backup entry DTO.</summary>
public sealed class FileBackupDto
{
    /// <summary>Gets or sets the backup name.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Gets or sets the source path.</summary>
    public string SourcePath { get; set; } = string.Empty;

    /// <summary>Gets or sets the destination path.</summary>
    public string DestinationPath { get; set; } = string.Empty;

    /// <summary>Gets or sets the creation time.</summary>
    public string Created { get; set; } = string.Empty;

    /// <summary>Gets or sets the size in MB.</summary>
    public long SizeMb { get; set; }

    /// <summary>Gets or sets a value indicating whether the backup is compressed.</summary>
    public bool Compressed { get; set; }

    /// <summary>Gets or sets a value indicating whether the backup is encrypted.</summary>
    public bool Encrypted { get; set; }

    /// <summary>Gets or sets the file count.</summary>
    public int FileCount { get; set; }
}
