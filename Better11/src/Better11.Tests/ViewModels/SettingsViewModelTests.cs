// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.ViewModels;

using Better11.Core.Interfaces;
using Better11.ViewModels.Settings;
using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

public class SettingsViewModelTests
{
    private readonly Mock<ISettingsService> _serviceMock = new();

    [Fact]
    public async Task InitializeAsync_Should_PopulateValues()
    {
        // Arrange - null sync context so RunOnUIThread runs inline in tests
        var previous = SynchronizationContext.Current;
        SynchronizationContext.SetSynchronizationContext(null);
        try
        {
            _serviceMock.Setup(s => s.LoadAsync(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);
            _serviceMock.Setup(s => s.GetValue("AppTheme", "System")).Returns("Dark");
            _serviceMock.Setup(s => s.GetValue("AutoUpdate", true)).Returns(false);
            _serviceMock.Setup(s => s.GetValue("EnableTelemetry", true)).Returns(false);
            _serviceMock.Setup(s => s.GetValue("IsFirstRunCompleted", false)).Returns(true);

            var vm = CreateVm();

            // Act
            await vm.InitializeAsync();

            // Assert
            vm.AppTheme.Should().Be("Dark");
            vm.EnableAutoUpdate.Should().BeFalse();
            vm.EnableTelemetry.Should().BeFalse();
            vm.IsFirstRunCompleted.Should().BeTrue();
        }
        finally
        {
            SynchronizationContext.SetSynchronizationContext(previous);
        }
    }

    [Fact]
    public async Task Save_Should_PersistCurrentValuesToService()
    {
        // Arrange
        var vm = CreateVm();
        vm.AppTheme = "Light";

        // Act
        await vm.SaveSettingsCommand.ExecuteAsync(null);

        // Assert
        _serviceMock.Verify(s => s.SetValue("AppTheme", "Light"), Times.Once);
    }

    [Fact]
    public async Task SaveAsync_Should_InvokeServiceSave()
    {
        // Arrange
        var vm = CreateVm();

        // Act
        await vm.SaveSettingsCommand.ExecuteAsync(null);

        // Assert
        _serviceMock.Verify(s => s.SaveAsync(It.IsAny<CancellationToken>()), Times.Once);
        vm.HasSuccess.Should().BeTrue();
    }

    private SettingsViewModel CreateVm() => new(_serviceMock.Object, NullLogger<SettingsViewModel>.Instance);
}
