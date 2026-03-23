// ============================================================================
// File: tests/Better11.Tests/UserAccount/UserAccountServiceTests.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Interfaces;
using Better11.Services.UserAccount;
using Moq;
using Xunit;

namespace Better11.Tests.UserAccount;

public class UserAccountServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly UserAccountService _sut;

    public UserAccountServiceTests() { _mockPs = new Mock<IPowerShellService>(); _sut = new UserAccountService(_mockPs.Object); }

    [Fact] public void Constructor_NullService_Throws() => Assert.Throws<ArgumentNullException>(() => new UserAccountService(null!));

    [Fact] public async Task GetLocalAccountsAsync_Works()
    { _mockPs.Setup(p => p.InvokeListAsync<LocalAccountDto>("B11.UserAccount", "Get-B11LocalAccount", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<LocalAccountDto>>.Ok(new List<LocalAccountDto>())); Assert.True((await _sut.GetLocalAccountsAsync()).IsSuccess); }

    [Fact] public async Task CreateAccountAsync_PassesParams()
    { _mockPs.Setup(p => p.InvokeAsync<bool>("B11.UserAccount", "New-B11LocalAccount", It.Is<Dictionary<string, object>>(d => (string)d["Username"] == "test"), It.IsAny<CancellationToken>())).ReturnsAsync(Result<bool>.Ok(true)); Assert.True((await _sut.CreateAccountAsync("test", "pass", "Test")).IsSuccess); }

    [Fact] public async Task DeleteAccountAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<bool>("B11.UserAccount", "Remove-B11LocalAccount", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<bool>.Ok(true)); Assert.True((await _sut.DeleteAccountAsync("test")).IsSuccess); }

    [Fact] public async Task SetAccountEnabledAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<bool>("B11.UserAccount", "Set-B11AccountEnabled", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<bool>.Ok(true)); Assert.True((await _sut.SetAccountEnabledAsync("test", true)).IsSuccess); }

    [Fact] public async Task GetLocalGroupsAsync_Works()
    { _mockPs.Setup(p => p.InvokeListAsync<LocalGroupDto>("B11.UserAccount", "Get-B11LocalGroup", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<LocalGroupDto>>.Ok(new List<LocalGroupDto>())); Assert.True((await _sut.GetLocalGroupsAsync()).IsSuccess); }

    [Fact] public async Task GetGroupMembersAsync_PassesGroup()
    { _mockPs.Setup(p => p.InvokeListAsync<GroupMemberDto>("B11.UserAccount", "Get-B11GroupMember", It.Is<Dictionary<string, object>>(d => (string)d["GroupName"] == "Admins"), It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<GroupMemberDto>>.Ok(new List<GroupMemberDto>())); Assert.True((await _sut.GetGroupMembersAsync("Admins")).IsSuccess); }

    [Fact] public async Task AddGroupMemberAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<bool>("B11.UserAccount", "Add-B11GroupMember", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<bool>.Ok(true)); Assert.True((await _sut.AddGroupMemberAsync("Admins", "user")).IsSuccess); }

    [Fact] public async Task RemoveGroupMemberAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<bool>("B11.UserAccount", "Remove-B11GroupMember", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<bool>.Ok(true)); Assert.True((await _sut.RemoveGroupMemberAsync("Admins", "user")).IsSuccess); }

    [Fact] public async Task GetPasswordPolicyAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<PasswordPolicyDto>("B11.UserAccount", "Get-B11PasswordPolicy", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<PasswordPolicyDto>.Ok(new PasswordPolicyDto())); Assert.True((await _sut.GetPasswordPolicyAsync()).IsSuccess); }

    [Fact] public async Task SetPasswordPolicyAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<bool>("B11.UserAccount", "Set-B11PasswordPolicy", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<bool>.Ok(true)); Assert.True((await _sut.SetPasswordPolicyAsync(8, true, 90)).IsSuccess); }

    [Fact] public async Task GetAutoLoginAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<AutoLoginDto>("B11.UserAccount", "Get-B11AutoLogin", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<AutoLoginDto>.Ok(new AutoLoginDto())); Assert.True((await _sut.GetAutoLoginAsync()).IsSuccess); }

    [Fact] public async Task SetAutoLoginAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<bool>("B11.UserAccount", "Set-B11AutoLogin", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<bool>.Ok(true)); Assert.True((await _sut.SetAutoLoginAsync("user", "pass")).IsSuccess); }

    [Fact] public async Task DisableAutoLoginAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<bool>("B11.UserAccount", "Disable-B11AutoLogin", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<bool>.Ok(true)); Assert.True((await _sut.DisableAutoLoginAsync()).IsSuccess); }

    [Fact] public async Task GetUserProfilesAsync_Works()
    { _mockPs.Setup(p => p.InvokeListAsync<UserProfileDto>("B11.UserAccount", "Get-B11UserProfile", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<UserProfileDto>>.Ok(new List<UserProfileDto>())); Assert.True((await _sut.GetUserProfilesAsync()).IsSuccess); }

    [Fact] public async Task GetSecurityAuditAsync_Works()
    { _mockPs.Setup(p => p.InvokeListAsync<SecurityAuditDto>("B11.UserAccount", "Get-B11SecurityAudit", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<SecurityAuditDto>>.Ok(new List<SecurityAuditDto>())); Assert.True((await _sut.GetSecurityAuditAsync(50)).IsSuccess); }

    [Fact] public async Task GetUserSessionsAsync_Works()
    { _mockPs.Setup(p => p.InvokeListAsync<UserSessionDto>("B11.UserAccount", "Get-B11UserSession", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<UserSessionDto>>.Ok(new List<UserSessionDto>())); Assert.True((await _sut.GetUserSessionsAsync()).IsSuccess); }

    [Fact] public async Task LogoffSessionAsync_Works()
    { _mockPs.Setup(p => p.InvokeAsync<bool>("B11.UserAccount", "Stop-B11UserSession", It.IsAny<Dictionary<string, object>>(), It.IsAny<CancellationToken>())).ReturnsAsync(Result<bool>.Ok(true)); Assert.True((await _sut.LogoffSessionAsync(1)).IsSuccess); }
}
