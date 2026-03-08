// ============================================================================
// File: src/Better11.App/App.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.App.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Serilog;
using Serilog.Formatting.Compact;

namespace Better11.App
{
    /// <summary>
    /// Application entry point with dependency injection.
    /// </summary>
    public partial class App : Application
    {
        /// <summary>Gets the current app instance.</summary>
        public static new App Current => (App)Application.Current;

        private readonly System.Diagnostics.Stopwatch _startupStopwatch = System.Diagnostics.Stopwatch.StartNew();
        private Window? _window;

        /// <summary>Gets the service provider.</summary>
        public IServiceProvider Services { get; }

        /// <summary>Gets the main dispatcher queue for UI thread access.</summary>
        public static DispatcherQueue? MainDispatcherQueue { get; private set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="App"/> class.
        /// </summary>
        public App()
        {
            // Configure Serilog for comprehensive logging
            var logDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Better11",
                "Logs");
            Directory.CreateDirectory(logDir);

            var logPath = Path.Combine(logDir, $"better11-{DateTime.Now:yyyyMMdd}.log");
            var jsonLogPath = Path.Combine(logDir, $"better11-{DateTime.Now:yyyyMMdd}.json");

            var loggerConfiguration = new LoggerConfiguration()
                .MinimumLevel.Debug()
                .Enrich.FromLogContext()
                .Enrich.WithProperty("Application", "Better11")
                .Enrich.WithProperty("Version", typeof(App).Assembly.GetName().Version?.ToString())
                .WriteTo.Console()
                .WriteTo.File(logPath,
                    rollingInterval: RollingInterval.Day,
                    retainedFileCountLimit: 30,
                    outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} {Level:u3}] [{SourceContext}] {Message:lj}{NewLine}{Exception}")
                .WriteTo.File(new CompactJsonFormatter(), jsonLogPath,
                    rollingInterval: RollingInterval.Day,
                    retainedFileCountLimit: 30);

            var eventLogSinkEnabled = false;
            try
            {
                if (System.Diagnostics.EventLog.SourceExists("Better11"))
                {
                    loggerConfiguration = loggerConfiguration.WriteTo.EventLog("Better11", manageEventSource: false);
                    eventLogSinkEnabled = true;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Better11 Event Log sink unavailable: {ex}");
            }

            Log.Logger = loggerConfiguration.CreateLogger();
            if (!eventLogSinkEnabled)
            {
                Log.Warning("Windows Event Log sink disabled because the Better11 event source is unavailable.");
            }

            var serviceCollection = new ServiceCollection();

            serviceCollection.AddLogging(builder =>
            {
                builder.SetMinimumLevel(LogLevel.Debug);
                builder.AddDebug();
                builder.AddSerilog();
            });

            serviceCollection.AddBetter11();

            Services = serviceCollection.BuildServiceProvider();

            // Log application startup
            var logger = Services.GetRequiredService<ILogger<App>>();
            logger.LogInformation("Better11 Application starting up - Version {Version}",
                typeof(App).Assembly.GetName().Version);
            logger.LogInformation("Startup (constructor to DI ready): {ElapsedMs} ms", _startupStopwatch.ElapsedMilliseconds);

            InitializeComponent();

            // WinUI 3 does not support OnUnhandledException override; subscribe to the event instead.
            UnhandledException += OnUnhandledExceptionHandler;
        }

        private void OnUnhandledExceptionHandler(object sender, Microsoft.UI.Xaml.UnhandledExceptionEventArgs e)
        {
            try
            {
                var logger = Services.GetRequiredService<ILogger<App>>();
                logger.LogError(e.Exception, "Unhandled exception occurred: {Message}", e.Message);
                logger.LogDebug("Exception details: {Exception}", e.Exception.ToString());
            }
            catch
            {
                Log.Error(e.Exception, "Critical unhandled exception - logging failed");
            }
        }

        /// <summary>Gets a service from the DI container.</summary>
        /// <typeparam name="T">The service type.</typeparam>
        /// <returns>The service instance.</returns>
        public static T GetService<T>()
            where T : class
        {
            return Current.Services.GetRequiredService<T>();
        }

        /// <inheritdoc/>
        protected override void OnLaunched(LaunchActivatedEventArgs args)
        {
            try
            {
                MainDispatcherQueue = DispatcherQueue.GetForCurrentThread();

                var logger = Services.GetRequiredService<ILogger<App>>();
                logger.LogInformation("Application launched successfully");
                if (Application.Current is App app)
                {
                    logger.LogInformation("Startup (App to MainWindow activated): {ElapsedMs} ms", app._startupStopwatch.ElapsedMilliseconds);
                }

                _window = new MainWindow();
                _window.Closed += (s, _) =>
                {
                    try
                    {
                        var log = Services.GetRequiredService<ILogger<App>>();
                        log.LogInformation("Application shutting down");
                        Log.CloseAndFlush();
                    }
                    catch (Exception ex)
                    {
                        Log.Error(ex, "Error during application shutdown");
                    }
                };
                _window.Activate();

                logger.LogInformation("Main window activated");
            }
            catch (Exception ex)
            {
                var logger = Services.GetRequiredService<ILogger<App>>();
                logger.LogError(ex, "Failed to launch application");

                // Show error dialog to user
                ShowErrorDialog("Application startup failed", ex.Message);
            }
        }

        /// <summary>
        /// Shows an error dialog to the user.
        /// </summary>
        private static void ShowErrorDialog(string title, string message)
        {
            // In a real implementation, this would show a proper WinUI dialog
            // For now, we'll just log to the Windows Event Log
            Log.Error("Application Error - {Title}: {Message}", title, message);
        }
    }
}
