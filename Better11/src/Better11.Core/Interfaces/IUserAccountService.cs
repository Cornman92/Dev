// Copyright (c) Better11. All rights reserved.

using Better11.Core.Common;

namespace Better11.Core.Interfaces;

/// <summary>
/// Service interface for the User Account Manager feature.
/// </summary>
public interface IUserAccountService
{
    /// <summary>Gets the list of local user accounts.</summary>
    Task<Result<IReadOnlyList<LocalAccountDto>>> GetLocalAccountsAsync(CancellationToken ct = default);

    /// <summary>Creates a local account with the given username, password, and full name.</summary>
    Task<Result<bool>> CreateAccountAsync(string username, string password, string fullName, CancellationToken ct = default);

    /// <summary>Deletes a local account by username.</summary>
    Task<Result<bool>> DeleteAccountAsync(string username, CancellationToken ct = default);

    /// <summary>Enables or disables a local account.</summary>
    Task<Result<bool>> SetAccountEnabledAsync(string username, bool enabled, CancellationToken ct = default);

    /// <summary>Gets the list of local groups.</summary>
    Task<Result<IReadOnlyList<LocalGroupDto>>> GetLocalGroupsAsync(CancellationToken ct = default);

    /// <summary>Gets the members of a local group.</summary>
    Task<Result<IReadOnlyList<GroupMemberDto>>> GetGroupMembersAsync(string groupName, CancellationToken ct = default);

    /// <summary>Adds a user to a local group.</summary>
    Task<Result<bool>> AddGroupMemberAsync(string groupName, string username, CancellationToken ct = default);

    /// <summary>Removes a user from a local group.</summary>
    Task<Result<bool>> RemoveGroupMemberAsync(string groupName, string username, CancellationToken ct = default);

    /// <summary>Gets the current password policy.</summary>
    Task<Result<PasswordPolicyDto>> GetPasswordPolicyAsync(CancellationToken ct = default);

    /// <summary>Sets the password policy (min length, complexity, max age).</summary>
    Task<Result<bool>> SetPasswordPolicyAsync(int minLength, bool complexity, int maxAgeDays, CancellationToken ct = default);

    /// <summary>Gets the current auto-login configuration.</summary>
    Task<Result<AutoLoginDto>> GetAutoLoginAsync(CancellationToken ct = default);

    /// <summary>Enables auto-login for the given user and password.</summary>
    Task<Result<bool>> SetAutoLoginAsync(string username, string password, CancellationToken ct = default);

    /// <summary>Disables auto-login.</summary>
    Task<Result<bool>> DisableAutoLoginAsync(CancellationToken ct = default);

    /// <summary>Gets the list of user profiles.</summary>
    Task<Result<IReadOnlyList<UserProfileDto>>> GetUserProfilesAsync(CancellationToken ct = default);

    /// <summary>Gets recent security audit events.</summary>
    Task<Result<IReadOnlyList<SecurityAuditDto>>> GetSecurityAuditAsync(int maxEntries, CancellationToken ct = default);

    /// <summary>Gets active user sessions.</summary>
    Task<Result<IReadOnlyList<UserSessionDto>>> GetUserSessionsAsync(CancellationToken ct = default);

    /// <summary>Logs off the session with the given ID.</summary>
    Task<Result<bool>> LogoffSessionAsync(int sessionId, CancellationToken ct = default);
}
