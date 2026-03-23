// Copyright (c) Better11. All rights reserved.

using Better11.Core.Common;
using Better11.Core.Interfaces;

namespace Better11.Services.UserAccount;

/// <summary>
/// Service for managing user accounts, groups, password policy, and autologin via PowerShell.
/// </summary>
public sealed class UserAccountService : IUserAccountService
{
    private const string Module = "B11.UserAccount";
    private readonly IPowerShellService _ps;

    /// <summary>
    /// Initializes a new instance of the <see cref="UserAccountService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service instance.</param>
    public UserAccountService(IPowerShellService ps)
    {
        ArgumentNullException.ThrowIfNull(ps);
        _ps = ps;
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<LocalAccountDto>>> GetLocalAccountsAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<LocalAccountDto>(Module, "Get-B11LocalAccount", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> CreateAccountAsync(string username, string password, string fullName, CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<bool>(Module, "New-B11LocalAccount", new Dictionary<string, object> { ["Username"] = username, ["Password"] = password, ["FullName"] = fullName }, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> DeleteAccountAsync(string username, CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<bool>(Module, "Remove-B11LocalAccount", new Dictionary<string, object> { ["Username"] = username }, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> SetAccountEnabledAsync(string username, bool enabled, CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<bool>(Module, "Set-B11AccountEnabled", new Dictionary<string, object> { ["Username"] = username, ["Enabled"] = enabled }, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<LocalGroupDto>>> GetLocalGroupsAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<LocalGroupDto>(Module, "Get-B11LocalGroup", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<GroupMemberDto>>> GetGroupMembersAsync(string groupName, CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<GroupMemberDto>(Module, "Get-B11GroupMember", new Dictionary<string, object> { ["GroupName"] = groupName }, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> AddGroupMemberAsync(string groupName, string username, CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<bool>(Module, "Add-B11GroupMember", new Dictionary<string, object> { ["GroupName"] = groupName, ["Username"] = username }, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> RemoveGroupMemberAsync(string groupName, string username, CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<bool>(Module, "Remove-B11GroupMember", new Dictionary<string, object> { ["GroupName"] = groupName, ["Username"] = username }, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<PasswordPolicyDto>> GetPasswordPolicyAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<PasswordPolicyDto>(Module, "Get-B11PasswordPolicy", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> SetPasswordPolicyAsync(int minLength, bool complexity, int maxAgeDays, CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<bool>(Module, "Set-B11PasswordPolicy", new Dictionary<string, object> { ["MinLength"] = minLength, ["Complexity"] = complexity, ["MaxAgeDays"] = maxAgeDays }, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<AutoLoginDto>> GetAutoLoginAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<AutoLoginDto>(Module, "Get-B11AutoLogin", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> SetAutoLoginAsync(string username, string password, CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<bool>(Module, "Set-B11AutoLogin", new Dictionary<string, object> { ["Username"] = username, ["Password"] = password }, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> DisableAutoLoginAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<bool>(Module, "Disable-B11AutoLogin", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<UserProfileDto>>> GetUserProfilesAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<UserProfileDto>(Module, "Get-B11UserProfile", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<SecurityAuditDto>>> GetSecurityAuditAsync(int maxEntries, CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<SecurityAuditDto>(Module, "Get-B11SecurityAudit", new Dictionary<string, object> { ["MaxEntries"] = maxEntries }, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<UserSessionDto>>> GetUserSessionsAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<UserSessionDto>(Module, "Get-B11UserSession", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> LogoffSessionAsync(int sessionId, CancellationToken ct = default) =>
        await _ps.InvokeCommandAsync<bool>(Module, "Stop-B11UserSession", new Dictionary<string, object> { ["SessionId"] = sessionId }, ct).ConfigureAwait(false);
}
