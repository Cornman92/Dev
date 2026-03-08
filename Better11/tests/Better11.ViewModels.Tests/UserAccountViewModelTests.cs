// ============================================================================
// Better11 System Enhancement Suite — UserAccountViewModelTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.UserAccount;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.ViewModels.Tests;

/// <summary>
/// Unit tests for <see cref="UserAccountViewModel"/>.
/// </summary>
public sealed class UserAccountViewModelTests
{
    private readonly Mock<IUserAccountService> _mockService;
    private readonly Mock<ILogger<UserAccountViewModel>> _mockLogger;
    private readonly UserAccountViewModel _viewModel;

    /// <summary>
    /// Initializes a new instance of the <see cref="UserAccountViewModelTests"/> class.
    /// </summary>
    public UserAccountViewModelTests()
    {
        _mockService = new Mock<IUserAccountService>();
        _mockLogger = new Mock<ILogger<UserAccountViewModel>>();

        _mockService.Setup(x => x.GetLocalAccountsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<LocalAccountDto>>.Success(new[]
            {
                new LocalAccountDto { Username = "Admin", Enabled = true },
            }));
        _mockService.Setup(x => x.GetLocalGroupsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<LocalGroupDto>>.Success(new[]
            {
                new LocalGroupDto { Name = "Administrators", MemberCount = 1 },
            }));
        _mockService.Setup(x => x.GetUserSessionsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<UserSessionDto>>.Success(new[]
            {
                new UserSessionDto { SessionId = 1, Username = "Admin" },
            }));
        _mockService.Setup(x => x.GetUserProfilesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<UserProfileDto>>.Success(Array.Empty<UserProfileDto>()));
        _mockService.Setup(x => x.GetPasswordPolicyAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PasswordPolicyDto>.Success(new PasswordPolicyDto
            {
                MinLength = 8,
                MaxAgeDays = 90,
                ComplexityEnabled = true,
                LockoutThreshold = 5,
            }));
        _mockService.Setup(x => x.GetAutoLoginAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<AutoLoginDto>.Success(new AutoLoginDto
            {
                Enabled = true,
                Username = "Admin",
            }));
        _mockService.Setup(x => x.CreateAccountAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));
        _mockService.Setup(x => x.GetGroupMembersAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<GroupMemberDto>>.Success(new[]
            {
                new GroupMemberDto { Name = "Admin", ObjectClass = "User" },
            }));
        _mockService.Setup(x => x.AddGroupMemberAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));

        _viewModel = new UserAccountViewModel(_mockService.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_SetsPageTitleAndInitializesCommands()
    {
        _viewModel.PageTitle.Should().Be("User Account Management");
        _viewModel.LoadAllCommand.Should().NotBeNull();
        _viewModel.LoadAccountsCommand.Should().NotBeNull();
        _viewModel.LoadGroupsCommand.Should().NotBeNull();
        _viewModel.LoadSessionsCommand.Should().NotBeNull();
        _viewModel.CreateAccountCommand.Should().NotBeNull();
        _viewModel.DeleteAccountCommand.Should().NotBeNull();
        _viewModel.ToggleAccountCommand.Should().NotBeNull();
        _viewModel.LoadGroupMembersCommand.Should().NotBeNull();
        _viewModel.AddMemberCommand.Should().NotBeNull();
        _viewModel.RemoveMemberCommand.Should().NotBeNull();
        _viewModel.ApplyPasswordPolicyCommand.Should().NotBeNull();
        _viewModel.SetAutoLoginCommand.Should().NotBeNull();
        _viewModel.DisableAutoLoginCommand.Should().NotBeNull();
        _viewModel.LoadAuditCommand.Should().NotBeNull();
        _viewModel.LogoffSessionCommand.Should().NotBeNull();
    }

    [Fact]
    public async Task InitializeAsync_LoadsAccountsGroupsSessionsAndPolicy()
    {
        await _viewModel.InitializeAsync();

        _viewModel.IsInitialized.Should().BeTrue();
        _viewModel.AccountCount.Should().Be(1);
        _viewModel.Accounts.Should().ContainSingle();
        _viewModel.Groups.Should().ContainSingle();
        _viewModel.Sessions.Should().ContainSingle();
        _viewModel.PolicyMinLength.Should().Be(8);
        _viewModel.PolicyComplexity.Should().BeTrue();
        _viewModel.AutoLoginEnabled.Should().BeTrue();
        _viewModel.AutoLoginUser.Should().Be("Admin");
    }

    [Fact]
    public async Task CreateAccountCommand_SetsValidationError_WhenUsernameMissing()
    {
        await _viewModel.CreateAccountCommand.ExecuteAsync(null);

        _viewModel.ErrorMessage.Should().Be("Username is required.");
        _mockService.Verify(x => x.CreateAccountAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task CreateAccountCommand_CallsServiceAndClearsInputs_WhenValid()
    {
        _viewModel.NewUsername = "tester";
        _viewModel.NewPassword = "secret";
        _viewModel.NewFullName = "Test User";

        await _viewModel.CreateAccountCommand.ExecuteAsync(null);

        _viewModel.SuccessMessage.Should().Be("Account 'tester' created successfully.");
        _viewModel.NewUsername.Should().BeEmpty();
        _viewModel.NewPassword.Should().BeEmpty();
        _viewModel.NewFullName.Should().BeEmpty();
        _mockService.Verify(x => x.CreateAccountAsync("tester", "secret", "Test User", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task AddMemberCommand_UsesSelectedGroupAndReloadsMembers()
    {
        _viewModel.SelectedGroup = new LocalGroupDto { Name = "Administrators" };
        _viewModel.MemberUsername = "tester";

        await _viewModel.AddMemberCommand.ExecuteAsync(null);
        await WaitForConditionAsync(() => _viewModel.GroupMembers.Count == 1);

        _viewModel.SuccessMessage.Should().Be("User 'tester' added to group 'Administrators'.");
        _viewModel.MemberUsername.Should().BeEmpty();
        _viewModel.GroupMembers.Should().ContainSingle();
        _mockService.Verify(x => x.AddGroupMemberAsync("Administrators", "tester", It.IsAny<CancellationToken>()), Times.Once);
        _mockService.Verify(x => x.GetGroupMembersAsync("Administrators", It.IsAny<CancellationToken>()), Times.Once);
    }

    private static async Task WaitForConditionAsync(Func<bool> predicate)
    {
        for (var attempt = 0; attempt < 20; attempt++)
        {
            if (predicate())
            {
                return;
            }

            await Task.Delay(10);
        }
    }
}
