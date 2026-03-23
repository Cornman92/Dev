// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.ViewModels;

using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.UserAccount;
using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

public class UserAccountViewModelTests
{
    private readonly Mock<IUserAccountService> _serviceMock = new();

    [Fact]
    public async Task InitializeAsyncShouldPopulateAccountsAndGroups()
    {
        // Arrange - null sync context so RunOnUIThread runs inline in tests
        var previous = SynchronizationContext.Current;
        SynchronizationContext.SetSynchronizationContext(null);
        try
        {
            var accounts = new List<LocalAccountDto> { new() { Username = "Admin" } };
            var groups = new List<LocalGroupDto> { new() { Name = "Administrators" } };
            var sessions = new List<UserSessionDto> { new() { Username = "Admin" } };
            var profiles = new List<UserProfileDto> { new() { Username = "Admin" } };
            var policy = new PasswordPolicyDto { MinLength = 8 };
            var autologin = new AutoLoginDto { Enabled = false };

            _serviceMock.Setup(s => s.GetLocalAccountsAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<IReadOnlyList<LocalAccountDto>>.Success(accounts));
            _serviceMock.Setup(s => s.GetLocalGroupsAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<IReadOnlyList<LocalGroupDto>>.Success(groups));
            _serviceMock.Setup(s => s.GetUserSessionsAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<IReadOnlyList<UserSessionDto>>.Success(sessions));
            _serviceMock.Setup(s => s.GetUserProfilesAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<IReadOnlyList<UserProfileDto>>.Success(profiles));
            _serviceMock.Setup(s => s.GetPasswordPolicyAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<PasswordPolicyDto>.Success(policy));
            _serviceMock.Setup(s => s.GetAutoLoginAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<AutoLoginDto>.Success(autologin));

            var vm = CreateVm();

            // Act
            await vm.InitializeAsync();

            // Assert
            vm.Accounts.Should().HaveCount(1);
            vm.Groups.Should().HaveCount(1);
            vm.Sessions.Should().HaveCount(1);
            vm.IsBusy.Should().BeFalse();
        }
        finally
        {
            SynchronizationContext.SetSynchronizationContext(previous);
        }
    }

    [Fact]
    public async Task RemoveMemberAsyncShouldCallServiceWhenGroupSelected()
    {
        // Arrange
        var vm = CreateVm();
        var group = new LocalGroupDto { Name = "Users" };
        vm.SelectedGroup = group;
        var username = "TestUser";

        _serviceMock.Setup(s => s.RemoveGroupMemberAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));
        _serviceMock.Setup(s => s.GetGroupMembersAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<GroupMemberDto>>.Success(new List<GroupMemberDto>()));

        // Act
        await vm.RemoveMemberCommand.ExecuteAsync(username);

        // Assert
        _serviceMock.Verify(s => s.RemoveGroupMemberAsync("Users", "TestUser", It.IsAny<CancellationToken>()), Times.Once);
        vm.HasSuccess.Should().BeTrue();
    }

    private UserAccountViewModel CreateVm() => new(_serviceMock.Object, NullLogger<UserAccountViewModel>.Instance);
}
