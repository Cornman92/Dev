// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Interfaces;

/// <summary>Group membership entry.</summary>
public sealed class GroupMemberDto
{
    /// <summary>Gets or sets the member name.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Gets or sets the SID.</summary>
    public string Sid { get; set; } = string.Empty;

    /// <summary>Gets or sets the object class.</summary>
    public string ObjectClass { get; set; } = string.Empty;

    /// <summary>Gets or sets the principal source.</summary>
    public string PrincipalSource { get; set; } = string.Empty;
}
