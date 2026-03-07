// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.Services;

using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Network;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

public sealed class NetworkServiceTests : IDisposable
{
    private readonly Mock<IPowerShellService> _psMock;
    private readonly Mock<ILogger<NetworkService>> _loggerMock;
    private readonly NetworkService _service;
    private bool _disposed;

    public NetworkServiceTests()
    {
        _psMock = new Mock<IPowerShellService>();
        _loggerMock = new Mock<ILogger<NetworkService>>();
        _service = new NetworkService(_psMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task GetAdaptersAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var expectedResult = new[]
        {
            new NetworkAdapterDto { Id = "Eth0", Name = "Ethernet", Status = "Up" }
        };

        _psMock.Setup(x => x.InvokeCommandListAsync<NetworkAdapterDto>(
            AppConstants.Modules.Network,
            "Get-B11NetworkAdapters",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<NetworkAdapterDto>>.Success(expectedResult));

        // Act
        var result = await _service.GetAdaptersAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
    }

    [Fact]
    public async Task GetDnsConfigAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var expectedResult = new DnsConfigDto
        {
            PrimaryDns = "1.1.1.1",
            SecondaryDns = "8.8.8.8"
        };

        _psMock.Setup(x => x.InvokeCommandAsync<DnsConfigDto>(
            AppConstants.Modules.Network,
            "Get-B11DnsConfig",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DnsConfigDto>.Success(expectedResult));

        // Act
        var result = await _service.GetDnsConfigAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
    }

    [Fact]
    public async Task SetDnsServersAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var adapterId = "Eth0";
        var primary = "1.1.1.1";
        var secondary = "8.8.8.8";

        _psMock.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Network,
            "Set-B11DnsServers",
            It.Is<IDictionary<string, object>>(p =>
                p.ContainsKey("AdapterId") &&
                p.ContainsKey("PrimaryDns") &&
                p.ContainsKey("SecondaryDns")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.SetDnsServersAsync(adapterId, primary, secondary);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task FlushDnsCacheAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        _psMock.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Network,
            "Clear-B11DnsCache",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.FlushDnsCacheAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task RunDiagnosticsAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var expectedResult = new NetworkDiagnosticsDto { IsConnected = true, LatencyMs = 15 };

        _psMock.Setup(x => x.InvokeCommandAsync<NetworkDiagnosticsDto>(
            AppConstants.Modules.Network,
            "Test-B11NetworkDiagnostics",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<NetworkDiagnosticsDto>.Success(expectedResult));

        // Act
        var result = await _service.RunDiagnosticsAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
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
