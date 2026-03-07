// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>Active user session information.</summary>
public sealed class UserSessionDto
{
    /// <summary>Gets or sets the session ID.</summary>
    public int SessionId { get; set; }

    /// <summary>Gets or sets the username.</summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>Gets or sets the session state.</summary>
    public string State { get; set; } = string.Empty;

    /// <summary>Gets or sets the session type.</summary>
    public string SessionType { get; set; } = string.Empty;

    /// <summary>Gets or sets the logon time.</summary>
    public string LogonTime { get; set; } = string.Empty;

    /// <summary>Gets or sets the idle time.</summary>
    public string IdleTime { get; set; } = string.Empty;
}
