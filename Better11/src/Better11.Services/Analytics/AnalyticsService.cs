using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Analytics;

/// <summary>
/// Implements basic analytics and telemetry logging for Better11.
/// Respects the user's telemetry opt-out setting; when disabled, no events are logged or sent.
/// </summary>
public class AnalyticsService : IAnalyticsService
{
    private readonly ILogger<AnalyticsService> _logger;
    private readonly ISettingsService _settings;

    /// <summary>
    /// Initializes a new instance of the <see cref="AnalyticsService"/> class.
    /// </summary>
    /// <param name="logger">The logger instance.</param>
    /// <param name="settings">The settings service to read telemetry opt-in.</param>
    public AnalyticsService(ILogger<AnalyticsService> logger, ISettingsService settings)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _settings = settings ?? throw new ArgumentNullException(nameof(settings));
    }

    /// <summary>
    /// Returns true if telemetry is enabled (user opt-in).
    /// </summary>
    private bool IsTelemetryEnabled => _settings.GetValue(SettingsConstants.Telemetry, false);

    /// <summary>
    /// Tracks an analytics event with optional properties.
    /// </summary>
    /// <param name="eventName">The name of the event to track.</param>
    /// <param name="properties">Optional key-value pairs describing the event.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A task representing the operation.</returns>
    public Task TrackEventAsync(string eventName, IDictionary<string, string>? properties = null, CancellationToken cancellationToken = default)
    {
        if (!IsTelemetryEnabled)
        {
            return Task.CompletedTask;
        }

        _logger.LogInformation("Analytics Event: {EventName}", eventName);
        if (properties != null && properties.Count > 0)
        {
            foreach (var prop in properties)
            {
                _logger.LogInformation("  - {Key}: {Value}", prop.Key, prop.Value);
            }
        }

        return Task.CompletedTask;
    }

    /// <summary>
    /// Tracks an exception with optional properties.
    /// </summary>
    /// <param name="exception">The exception to track.</param>
    /// <param name="properties">Optional key-value pairs describing the context.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A task representing the operation.</returns>
    public Task TrackExceptionAsync(Exception exception, IDictionary<string, string>? properties = null, CancellationToken cancellationToken = default)
    {
        if (!IsTelemetryEnabled)
        {
            return Task.CompletedTask;
        }

        _logger.LogError(exception, "Analytics Exception Recorded");
        if (properties != null && properties.Count > 0)
        {
            foreach (var prop in properties)
            {
                _logger.LogError("  - {Key}: {Value}", prop.Key, prop.Value);
            }
        }

        return Task.CompletedTask;
    }

    /// <summary>
    /// Tracks a page view.
    /// </summary>
    /// <param name="pageName">The name of the page being viewed.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A task representing the operation.</returns>
    public Task TrackPageViewAsync(string pageName, CancellationToken cancellationToken = default)
    {
        if (!IsTelemetryEnabled)
        {
            return Task.CompletedTask;
        }

        _logger.LogInformation("Analytics Page View: {PageName}", pageName);
        return Task.CompletedTask;
    }
}
