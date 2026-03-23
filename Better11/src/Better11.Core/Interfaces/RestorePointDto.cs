// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>System restore point DTO.</summary>
public sealed class RestorePointDto
{
    /// <summary>Gets or sets the sequence number.</summary>
    public int SequenceNumber { get; set; }

    /// <summary>Gets or sets the description.</summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>Gets or sets the creation time.</summary>
    public string CreationTime { get; set; } = string.Empty;

    /// <summary>Gets or sets the restore point type.</summary>
    public string RestorePointType { get; set; } = string.Empty;
}
