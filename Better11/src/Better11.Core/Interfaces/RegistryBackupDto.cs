// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>Registry backup entry DTO.</summary>
public sealed class RegistryBackupDto
{
    /// <summary>Gets or sets the backup name.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Gets or sets the registry key path.</summary>
    public string KeyPath { get; set; } = string.Empty;

    /// <summary>Gets or sets the backup file path.</summary>
    public string FilePath { get; set; } = string.Empty;

    /// <summary>Gets or sets the creation time.</summary>
    public string Created { get; set; } = string.Empty;

    /// <summary>Gets or sets the size in KB.</summary>
    public long SizeKb { get; set; }
}
