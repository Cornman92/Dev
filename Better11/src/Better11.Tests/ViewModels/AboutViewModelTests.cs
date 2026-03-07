// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.ViewModels;

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.About;
using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

public class AboutViewModelTests
{
    private readonly Mock<ISystemInfoService> _sysInfoMock = new();

    [Fact]
    public async Task InitializeAsync_Should_PopulateSystemInfoAndComponents()
    {
        // Arrange
        var info = new SystemInfoDto { ComputerName = "TEST-PC", OsName = "Windows 11" };
        _sysInfoMock.Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));

        var vm = CreateVm();

        // Act
        await vm.InitializeAsync();

        // Assert
        vm.SystemInformation.Should().NotBeNull();
        vm.SystemInformation!.ComputerName.Should().Be("TEST-PC");
        vm.Components.Should().NotBeEmpty();
        vm.Components.Any(c => c.Name == "WinUI 3").Should().BeTrue();
    }

    [Fact]
    public void StaticProperties_Should_ReturnConstants()
    {
        AboutViewModel.AppDisplayName.Should().NotBeNullOrWhiteSpace();
        AboutViewModel.AppVersion.Should().NotBeNullOrWhiteSpace();
        AboutViewModel.Copyright.Should().NotBeNullOrWhiteSpace();
    }

    private AboutViewModel CreateVm() => new(_sysInfoMock.Object, NullLogger<AboutViewModel>.Instance);
}
