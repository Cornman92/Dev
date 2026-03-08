#pragma warning disable CS1591

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Customization;

/// <summary>
/// Stubbed image-servicing service for the phase-2 offline image workflow.
/// </summary>
public sealed class ImageServicingService : IImageServicingService
{
    private readonly ILogger<ImageServicingService> _logger;

    public ImageServicingService(ILogger<ImageServicingService> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public Task<Result<MountedImageDto>> MountImageAsync(
        string imagePath,
        string mountPath,
        int imageIndex,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "Offline image mount requested for {ImagePath} (index {Index}) at {MountPath}, but the phase-2 workflow is not active yet.",
            imagePath,
            imageIndex,
            mountPath);
        return Task.FromResult(Result<MountedImageDto>.Failure(
            "Offline image servicing is scaffolded but not enabled in this wave."));
    }

    public Task<Result> UnmountImageAsync(
        string mountPath,
        bool saveChanges,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "Offline image unmount requested for {MountPath} (saveChanges={SaveChanges}), but the phase-2 workflow is not active yet.",
            mountPath,
            saveChanges);
        return Task.FromResult(Result.Failure(
            "Offline image servicing is scaffolded but not enabled in this wave."));
    }

    public Task<Result<IReadOnlyList<MountedImageDto>>> GetMountedImagesAsync(
        CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Result<IReadOnlyList<MountedImageDto>>.Success(Array.Empty<MountedImageDto>()));
    }
}

#pragma warning restore CS1591
