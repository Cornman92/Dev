// ============================================================================
// Better11 System Enhancement Suite — NetworkServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Network;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="NetworkService"/>.
/// </summary>
public sealed class NetworkServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<NetworkService>> _mockLogger;
    private readonly NetworkService _service;

    public NetworkServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<NetworkService>>();
        _service = new NetworkService(_mockPs.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new NetworkService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    // ========================================================================
    // GetAdaptersAsync
    // ========================================================================

    [Fact]
    public async Task GetAdaptersAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        var expected = new List<NetworkAdapterDto>
        {
            new() { Id = "eth0", Name = "Ethernet", Status = "Up", SpeedMbps = 1000 },
            new() { Id = "wifi0", Name = "Wi-Fi", Status = "Up", SpeedMbps = 300 },
        };
        _mockPs.Setup(x => x.InvokeCommandListAsync<NetworkAdapterDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<NetworkAdapterDto>>.Success(expected));

        var result = await _service.GetAdaptersAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(2);
        result.Value![0].SpeedMbps.Should().Be(1000);
    }

    [Fact]
    public async Task GetAdaptersAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<NetworkAdapterDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<NetworkAdapterDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetAdaptersAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetAdaptersAsync_InvokesCorrectCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<NetworkAdapterDto>(
            AppConstants.Modules.Network, "Get-B11NetworkAdapters",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<NetworkAdapterDto>>.Success(new List<NetworkAdapterDto>()));

        await _service.GetAdaptersAsync(CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandListAsync<NetworkAdapterDto>(
            AppConstants.Modules.Network, "Get-B11NetworkAdapters",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // GetDnsConfigAsync
    // ========================================================================

    [Fact]
    public async Task GetDnsConfigAsync_ReturnsSuccess_WithDnsSettings()
    {
        var expected = new DnsConfigDto
        {
            PrimaryDns = "8.8.8.8",
            SecondaryDns = "8.8.4.4",
            DnsSuffix = "home.lan",
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<DnsConfigDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DnsConfigDto>.Success(expected));

        var result = await _service.GetDnsConfigAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.PrimaryDns.Should().Be("8.8.8.8");
        result.Value.SecondaryDns.Should().Be("8.8.4.4");
    }

    [Fact]
    public async Task GetDnsConfigAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<DnsConfigDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DnsConfigDto>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetDnsConfigAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    // ========================================================================
    // SetDnsServersAsync
    // ========================================================================

    [Fact]
    public async Task SetDnsServersAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.SetDnsServersAsync("eth0", "1.1.1.1", "1.0.0.1", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task SetDnsServersAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure("Access denied", "B11_ACCESS_DENIED"));

        var result = await _service.SetDnsServersAsync("eth0", "1.1.1.1", "1.0.0.1", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task SetDnsServersAsync_PassesAllParameters()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Network, "Set-B11DnsServers",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("AdapterId") && (string)d["AdapterId"] == "eth0" &&
                d.ContainsKey("PrimaryDns") && (string)d["PrimaryDns"] == "1.1.1.1" &&
                d.ContainsKey("SecondaryDns") && (string)d["SecondaryDns"] == "1.0.0.1"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _service.SetDnsServersAsync("eth0", "1.1.1.1", "1.0.0.1", CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Network, "Set-B11DnsServers",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("AdapterId") && (string)d["AdapterId"] == "eth0" &&
                d.ContainsKey("PrimaryDns") && (string)d["PrimaryDns"] == "1.1.1.1" &&
                d.ContainsKey("SecondaryDns") && (string)d["SecondaryDns"] == "1.0.0.1"),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // FlushDnsCacheAsync
    // ========================================================================

    [Fact]
    public async Task FlushDnsCacheAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.FlushDnsCacheAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task FlushDnsCacheAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.FlushDnsCacheAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    // ========================================================================
    // RunDiagnosticsAsync
    // ========================================================================

    [Fact]
    public async Task RunDiagnosticsAsync_ReturnsSuccess_WithMetrics()
    {
        var expected = new NetworkDiagnosticsDto
        {
            IsConnected = true,
            LatencyMs = 15,
            DownloadSpeedMbps = 500.5,
            UploadSpeedMbps = 100.2,
            DnsResolutionMs = 5,
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<NetworkDiagnosticsDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<NetworkDiagnosticsDto>.Success(expected));

        var result = await _service.RunDiagnosticsAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.IsConnected.Should().BeTrue();
        result.Value.LatencyMs.Should().Be(15);
        result.Value.DownloadSpeedMbps.Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task RunDiagnosticsAsync_ReturnsFailure_WhenNoConnection()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<NetworkDiagnosticsDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<NetworkDiagnosticsDto>.Failure(ErrorCodes.PowerShell, "No network"));

        var result = await _service.RunDiagnosticsAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task RunDiagnosticsAsync_PropagatesCancellation()
    {
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        _mockPs.Setup(x => x.InvokeCommandAsync<NetworkDiagnosticsDto>(
            AppConstants.Modules.Network, "Test-B11NetworkDiagnostics",
            It.IsAny<IDictionary<string, object>>(), cts.Token))
            .ThrowsAsync(new OperationCanceledException());

        var result = await _service.RunDiagnosticsAsync(cts.Token);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be(ErrorCodes.Cancelled);
    }
}
