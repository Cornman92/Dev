// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>Local group information.</summary>
public sealed class LocalGroupDto
{
    /// <summary>Gets or sets the group name.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Gets or sets the SID.</summary>
    public string Sid { get; set; } = string.Empty;

    /// <summary>Gets or sets the description.</summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>Gets or sets the member count.</summary>
    public int MemberCount { get; set; }
}
