// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>Local user account information.</summary>
public sealed class LocalAccountDto
{
    /// <summary>Gets or sets the username.</summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>Gets or sets the full name.</summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>Gets or sets the SID.</summary>
    public string Sid { get; set; } = string.Empty;

    /// <summary>Gets or sets a value indicating whether the account is enabled.</summary>
    public bool Enabled { get; set; }

    /// <summary>Gets or sets a value indicating whether the account is an administrator.</summary>
    public bool IsAdmin { get; set; }

    /// <summary>Gets or sets the description.</summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>Gets or sets the last login time.</summary>
    public string LastLogin { get; set; } = string.Empty;

    /// <summary>Gets or sets a value indicating whether the password never expires.</summary>
    public bool PasswordNeverExpires { get; set; }

    /// <summary>Gets or sets a value indicating whether the account is locked out.</summary>
    public bool IsLockedOut { get; set; }
}
