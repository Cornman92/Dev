// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>User profile information.</summary>
public sealed class UserProfileDto
{
    /// <summary>Gets or sets the username.</summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>Gets or sets the profile path.</summary>
    public string ProfilePath { get; set; } = string.Empty;

    /// <summary>Gets or sets the profile size in MB.</summary>
    public long SizeMb { get; set; }

    /// <summary>Gets or sets the SID.</summary>
    public string Sid { get; set; } = string.Empty;

    /// <summary>Gets or sets the last use time.</summary>
    public string LastUseTime { get; set; } = string.Empty;

    /// <summary>Gets or sets a value indicating whether the profile is loaded.</summary>
    public bool IsLoaded { get; set; }
}
