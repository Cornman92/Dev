// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.Services;

using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Privacy;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

public sealed class PrivacyServiceTests : IDisposable
{
    private readonly Mock<IPowerShellService> _psMock;
    private readonly Mock<ILogger<PrivacyService>> _loggerMock;
    private readonly PrivacyService _service;
    private bool _disposed;

    public PrivacyServiceTests()
    {
        _psMock = new Mock<IPowerShellService>();
        _loggerMock = new Mock<ILogger<PrivacyService>>();
        _service = new PrivacyService(_psMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task GetPrivacyAuditAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var expectedResult = new PrivacyAuditDto
        {
            Score = 80,
            CurrentProfile = "Balanced",
            Settings = new[]
            {
                new PrivacySettingDto { Id = "P1", Name = "Telemetry", IsEnabled = false }
            }
        };

        _psMock.Setup(x => x.InvokeCommandAsync<PrivacyAuditDto>(
            AppConstants.Modules.Privacy,
            "Get-B11PrivacyAudit",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(expectedResult));

        // Act
        var result = await _service.GetPrivacyAuditAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
    }

    [Fact]
    public async Task ApplyPrivacyProfileAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var profileName = "Strict";

        _psMock.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Privacy,
            "Set-B11PrivacyProfile",
            It.Is<IDictionary<string, object>>(p => p.ContainsKey("ProfileName")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.ApplyPrivacyProfileAsync(profileName);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task SetPrivacySettingAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var settingId = "P1";
        var enabled = false;

        _psMock.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Privacy,
            "Set-B11PrivacySetting",
            It.Is<IDictionary<string, object>>(p =>
                p.ContainsKey("SettingId") &&
                p.ContainsKey("Enabled")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.SetPrivacySettingAsync(settingId, enabled);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    public void Dispose()
    {
        if (!_disposed)
        {
            _service.Dispose();
            _disposed = true;
        }
    }
}
