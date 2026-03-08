// ============================================================================
// Better11 System Enhancement Suite — UserAccountServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.Services.UserAccount;
using FluentAssertions;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="UserAccountService"/>.
/// </summary>
public sealed class UserAccountServiceTests
{
    private const string ModuleName = "B11.UserAccount";

    private readonly Mock<IPowerShellService> _mockPs;
    private readonly UserAccountService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="UserAccountServiceTests"/> class.
    /// </summary>
    public UserAccountServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _service = new UserAccountService(_mockPs.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new UserAccountService(null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task GetLocalAccountsAsync_InvokesExpectedCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<LocalAccountDto>(
            ModuleName,
            "Get-B11LocalAccount",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<LocalAccountDto>>.Success(Array.Empty<LocalAccountDto>()));

        var result = await _service.GetLocalAccountsAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        _mockPs.Verify(x => x.InvokeCommandListAsync<LocalAccountDto>(
            ModuleName,
            "Get-B11LocalAccount",
            null,
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateAccountAsync_PassesUsernamePasswordAndFullName()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<bool>(
            ModuleName,
            "New-B11LocalAccount",
            It.Is<IDictionary<string, object>>(parameters =>
                (string)parameters["Username"] == "tester"
                && (string)parameters["Password"] == "secret"
                && (string)parameters["FullName"] == "Test User"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));

        var result = await _service.CreateAccountAsync("tester", "secret", "Test User", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task GetGroupMembersAsync_PassesGroupName()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<GroupMemberDto>(
            ModuleName,
            "Get-B11GroupMember",
            It.Is<IDictionary<string, object>>(parameters =>
                (string)parameters["GroupName"] == "Administrators"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<GroupMemberDto>>.Success(Array.Empty<GroupMemberDto>()));

        var result = await _service.GetGroupMembersAsync("Administrators", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task SetPasswordPolicyAsync_PassesPolicyValues()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<bool>(
            ModuleName,
            "Set-B11PasswordPolicy",
            It.Is<IDictionary<string, object>>(parameters =>
                (int)parameters["MinLength"] == 12
                && (bool)parameters["Complexity"]
                && (int)parameters["MaxAgeDays"] == 90),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));

        var result = await _service.SetPasswordPolicyAsync(12, true, 90, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task LogoffSessionAsync_PassesSessionId()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<bool>(
            ModuleName,
            "Stop-B11UserSession",
            It.Is<IDictionary<string, object>>(parameters =>
                (int)parameters["SessionId"] == 7),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));

        var result = await _service.LogoffSessionAsync(7, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }
}
