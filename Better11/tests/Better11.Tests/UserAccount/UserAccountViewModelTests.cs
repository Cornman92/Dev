// ============================================================================
// File: tests/Better11.Tests/UserAccount/UserAccountViewModelTests.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Interfaces;
using Better11.ViewModels.UserAccount;
using Moq;
using Xunit;

namespace Better11.Tests.UserAccount;

public class UserAccountViewModelTests
{
    private readonly Mock<IUserAccountService> _mockService;
    private readonly UserAccountViewModel _sut;

    public UserAccountViewModelTests()
    {
        _mockService = new Mock<IUserAccountService>();
        SetupDefaults();
        _sut = new UserAccountViewModel(_mockService.Object);
    }

    private void SetupDefaults()
    {
        _mockService.Setup(s => s.GetLocalAccountsAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<LocalAccountDto>>.Ok(new List<LocalAccountDto> { new() { Username = "Admin", Enabled = true } }));
        _mockService.Setup(s => s.GetLocalGroupsAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<LocalGroupDto>>.Ok(new List<LocalGroupDto>()));
        _mockService.Setup(s => s.GetPasswordPolicyAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Result<PasswordPolicyDto>.Ok(new PasswordPolicyDto { MinLength = 8 }));
        _mockService.Setup(s => s.GetAutoLoginAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Result<AutoLoginDto>.Ok(new AutoLoginDto()));
        _mockService.Setup(s => s.GetUserProfilesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<UserProfileDto>>.Ok(new List<UserProfileDto>()));
    }

    [Fact] public void Constructor_NullService_Throws() => Assert.Throws<ArgumentNullException>(() => new UserAccountViewModel(null!));
    [Fact] public void Constructor_InitializesCollections() { Assert.NotNull(_sut.Accounts); Assert.NotNull(_sut.Groups); Assert.NotNull(_sut.GroupMembers); Assert.NotNull(_sut.Profiles); Assert.NotNull(_sut.AuditEvents); Assert.NotNull(_sut.Sessions); }
    [Fact] public void Constructor_InitializesAllCommands()
    {
        Assert.NotNull(_sut.RefreshCommand); Assert.NotNull(_sut.CreateAccountCommand); Assert.NotNull(_sut.DeleteAccountCommand);
        Assert.NotNull(_sut.ToggleAccountCommand); Assert.NotNull(_sut.LoadGroupMembersCommand); Assert.NotNull(_sut.AddMemberCommand);
        Assert.NotNull(_sut.RemoveMemberCommand); Assert.NotNull(_sut.ApplyPasswordPolicyCommand); Assert.NotNull(_sut.SetAutoLoginCommand);
        Assert.NotNull(_sut.DisableAutoLoginCommand); Assert.NotNull(_sut.LoadAuditCommand); Assert.NotNull(_sut.LoadSessionsCommand);
        Assert.NotNull(_sut.LogoffSessionCommand);
    }

    [Fact] public void IsLoading_DefaultsFalse() => Assert.False(_sut.IsLoading);
    [Fact] public void AccountCount_DefaultsZero() => Assert.Equal(0, _sut.AccountCount);
    [Fact] public void AutoLoginEnabled_DefaultsFalse() => Assert.False(_sut.AutoLoginEnabled);
    [Fact] public void PolicyComplexity_DefaultsFalse() => Assert.False(_sut.PolicyComplexity);
    [Fact] public void PolicyMinLength_DefaultsZero() => Assert.Equal(0, _sut.PolicyMinLength);

    [Fact] public void PropertyChanged_Raises()
    { var raised = false; _sut.PropertyChanged += (s, e) => { if (e.PropertyName == nameof(_sut.AccountCount)) raised = true; }; _sut.AccountCount = 5; Assert.True(raised); }

    // DTO defaults
    [Fact] public void LocalAccountDto_Defaults() { var d = new LocalAccountDto(); Assert.False(d.Enabled); Assert.False(d.IsAdmin); }
    [Fact] public void LocalGroupDto_Defaults() { var d = new LocalGroupDto(); Assert.Equal(0, d.MemberCount); }
    [Fact] public void GroupMemberDto_Defaults() { var d = new GroupMemberDto(); Assert.Equal(string.Empty, d.ObjectClass); }
    [Fact] public void PasswordPolicyDto_Defaults() { var d = new PasswordPolicyDto(); Assert.False(d.ComplexityEnabled); Assert.Equal(0, d.MinLength); }
    [Fact] public void AutoLoginDto_Defaults() { var d = new AutoLoginDto(); Assert.False(d.Enabled); }
    [Fact] public void UserProfileDto_Defaults() { var d = new UserProfileDto(); Assert.False(d.IsLoaded); }
    [Fact] public void SecurityAuditDto_Defaults() { var d = new SecurityAuditDto(); Assert.Equal(0, d.EventId); }
    [Fact] public void UserSessionDto_Defaults() { var d = new UserSessionDto(); Assert.Equal(0, d.SessionId); }

    [Fact] public async Task InitializeAsync_LoadsData()
    { await _sut.InitializeAsync(); Assert.Contains("ready", _sut.StatusMessage, StringComparison.OrdinalIgnoreCase); Assert.Equal(1, _sut.AccountCount); Assert.Equal(8, _sut.PolicyMinLength); }

    [Fact] public async Task InitializeAsync_HandlesErrors()
    { _mockService.Setup(s => s.GetLocalAccountsAsync(It.IsAny<CancellationToken>())).ThrowsAsync(new InvalidOperationException("fail")); await _sut.InitializeAsync(); Assert.Contains("Error", _sut.StatusMessage); }
}
