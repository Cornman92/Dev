// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>Security audit event.</summary>
public sealed class SecurityAuditDto
{
    /// <summary>Gets or sets the event timestamp.</summary>
    public string Timestamp { get; set; } = string.Empty;

    /// <summary>Gets or sets the event type.</summary>
    public string EventType { get; set; } = string.Empty;

    /// <summary>Gets or sets the account name.</summary>
    public string AccountName { get; set; } = string.Empty;

    /// <summary>Gets or sets the event source.</summary>
    public string Source { get; set; } = string.Empty;

    /// <summary>Gets or sets the event ID.</summary>
    public int EventId { get; set; }

    /// <summary>Gets or sets the result.</summary>
    public string Result { get; set; } = string.Empty;
}
