// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>Auto-login configuration.</summary>
public sealed class AutoLoginDto
{
    /// <summary>Gets or sets a value indicating whether auto-login is enabled.</summary>
    public bool Enabled { get; set; }

    /// <summary>Gets or sets the auto-login username.</summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>Gets or sets the domain.</summary>
    public string Domain { get; set; } = string.Empty;
}
