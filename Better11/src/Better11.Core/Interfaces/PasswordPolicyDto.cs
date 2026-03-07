// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>Password policy settings.</summary>
public sealed class PasswordPolicyDto
{
    /// <summary>Gets or sets the minimum password length.</summary>
    public int MinLength { get; set; }

    /// <summary>Gets or sets a value indicating whether complexity is required.</summary>
    public bool ComplexityEnabled { get; set; }

    /// <summary>Gets or sets the maximum password age in days.</summary>
    public int MaxAgeDays { get; set; }

    /// <summary>Gets or sets the minimum password age in days.</summary>
    public int MinAgeDays { get; set; }

    /// <summary>Gets or sets the password history count.</summary>
    public int HistoryCount { get; set; }

    /// <summary>Gets or sets the lockout threshold.</summary>
    public int LockoutThreshold { get; set; }

    /// <summary>Gets or sets the lockout duration in minutes.</summary>
    public int LockoutDurationMinutes { get; set; }
}
