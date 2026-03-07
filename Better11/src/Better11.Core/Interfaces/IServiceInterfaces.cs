// ============================================================================
// File: src/Better11.Core/Interfaces/IServiceInterfaces.cs
// Better11 System Enhancement Suite — All Service Interfaces
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;

namespace Better11.Core.Interfaces
{
    // ========================================================================
    // INavigationService
    // ========================================================================

    /// <summary>
    /// Defines navigation operations for the application shell.
    /// </summary>
    public interface INavigationService
    {
        /// <summary>Gets the current page type.</summary>
        Type? CurrentPage { get; }

        /// <summary>Gets a value indicating whether back navigation is possible.</summary>
        bool CanGoBack { get; }

        /// <summary>Navigates to a page.</summary>
        /// <param name="pageType">The page type.</param>
        /// <param name="parameter">Optional navigation parameter.</param>
        /// <returns>True if navigation succeeded.</returns>
        bool NavigateTo(Type pageType, object? parameter = null);

        /// <summary>Navigates to a page by key.</summary>
        /// <param name="pageKey">The page key.</param>
        /// <param name="parameter">Optional navigation parameter.</param>
        /// <returns>True if navigation succeeded.</returns>
        bool NavigateTo(string pageKey, object? parameter = null);

        /// <summary>Navigates back.</summary>
        void GoBack();

        /// <summary>Raised when navigation occurs.</summary>
        event EventHandler<Type>? Navigated;
    }

    // ========================================================================
    // IDialogService
    // ========================================================================

    /// <summary>
    /// Defines dialog and notification operations.
    /// </summary>
    public interface IDialogService
    {
        /// <summary>Shows an information dialog.</summary>
        Task ShowInfoAsync(string title, string message);

        /// <summary>Shows a warning dialog.</summary>
        Task ShowWarningAsync(string title, string message);

        /// <summary>Shows an error dialog.</summary>
        Task ShowErrorAsync(string title, string message);

        /// <summary>Shows a confirmation dialog.</summary>
        Task<bool> ShowConfirmAsync(string title, string message);
    }

    // ========================================================================
    // ISettingsService
    // ========================================================================

    /// <summary>
    /// Defines application settings persistence.
    /// </summary>
    public interface ISettingsService
    {
        /// <summary>Gets a setting value.</summary>
        T GetValue<T>(string key, T defaultValue);

        /// <summary>Sets a setting value.</summary>
        void SetValue<T>(string key, T value);

        /// <summary>Saves all settings to disk.</summary>
        Task SaveAsync(CancellationToken cancellationToken = default);

        /// <summary>Loads all settings from disk.</summary>
        Task LoadAsync(CancellationToken cancellationToken = default);
    }

    // ========================================================================
    // IPackageService
    // ========================================================================

    /// <summary>
    /// Defines package management operations.
    /// </summary>
    public interface IPackageService
    {
        /// <summary>Gets all installed packages.</summary>
        Task<Result<IReadOnlyList<PackageDto>>> GetInstalledPackagesAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Gets available package updates.</summary>
        Task<Result<IReadOnlyList<PackageDto>>> GetAvailableUpdatesAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Installs a package.</summary>
        Task<Result> InstallPackageAsync(
            string packageId,
            string source,
            CancellationToken cancellationToken = default);

        /// <summary>Uninstalls a package.</summary>
        Task<Result> UninstallPackageAsync(
            string packageId,
            CancellationToken cancellationToken = default);

        /// <summary>Updates a package.</summary>
        Task<Result> UpdatePackageAsync(
            string packageId,
            CancellationToken cancellationToken = default);

        /// <summary>Searches for packages.</summary>
        Task<Result<IReadOnlyList<PackageDto>>> SearchPackagesAsync(
            string query,
            CancellationToken cancellationToken = default);
    }

    /// <summary>Package data transfer object.</summary>
    public sealed class PackageDto
    {
        /// <summary>Gets or sets the package identifier.</summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>Gets or sets the display name.</summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>Gets or sets the installed version.</summary>
        public string Version { get; set; } = string.Empty;

        /// <summary>Gets or sets the available version.</summary>
        public string? AvailableVersion { get; set; }

        /// <summary>Gets or sets the package source.</summary>
        public string Source { get; set; } = string.Empty;

        /// <summary>Gets or sets the publisher.</summary>
        public string Publisher { get; set; } = string.Empty;

        /// <summary>Gets a value indicating whether an update is available.</summary>
        public bool HasUpdate => !string.IsNullOrEmpty(AvailableVersion)
            && AvailableVersion != Version;
    }

    // ========================================================================
    // IDriverService
    // ========================================================================

    /// <summary>
    /// Defines driver management operations.
    /// </summary>
    public interface IDriverService
    {
        /// <summary>Gets all installed drivers.</summary>
        Task<Result<IReadOnlyList<DriverDto>>> GetInstalledDriversAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Scans for driver updates.</summary>
        Task<Result<IReadOnlyList<DriverDto>>> ScanForUpdatesAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Updates a driver.</summary>
        Task<Result> UpdateDriverAsync(
            string deviceId,
            CancellationToken cancellationToken = default);

        /// <summary>Creates a driver backup.</summary>
        Task<Result<string>> BackupDriverAsync(
            string deviceId,
            string backupPath,
            CancellationToken cancellationToken = default);

        /// <summary>Rolls back a driver.</summary>
        Task<Result> RollbackDriverAsync(
            string deviceId,
            CancellationToken cancellationToken = default);
    }

    /// <summary>Driver data transfer object.</summary>
    public sealed class DriverDto
    {
        /// <summary>Gets or sets the device ID.</summary>
        public string DeviceId { get; set; } = string.Empty;

        /// <summary>Gets or sets the device name.</summary>
        public string DeviceName { get; set; } = string.Empty;

        /// <summary>Gets or sets the driver version.</summary>
        public string DriverVersion { get; set; } = string.Empty;

        /// <summary>Gets or sets the driver date.</summary>
        public DateTime DriverDate { get; set; }

        /// <summary>Gets or sets the manufacturer.</summary>
        public string Manufacturer { get; set; } = string.Empty;

        /// <summary>Gets or sets the device category.</summary>
        public string Category { get; set; } = string.Empty;

        /// <summary>Gets or sets the driver status.</summary>
        public string Status { get; set; } = string.Empty;

        /// <summary>Gets or sets a value indicating whether an update is available.</summary>
        public bool HasUpdate { get; set; }
    }

    // ========================================================================
    // IStartupService
    // ========================================================================

    /// <summary>
    /// Defines startup item management.
    /// </summary>
    public interface IStartupService
    {
        /// <summary>Gets all startup items.</summary>
        Task<Result<IReadOnlyList<StartupItemDto>>> GetStartupItemsAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Enables a startup item.</summary>
        Task<Result> EnableStartupItemAsync(
            string itemId,
            CancellationToken cancellationToken = default);

        /// <summary>Disables a startup item.</summary>
        Task<Result> DisableStartupItemAsync(
            string itemId,
            CancellationToken cancellationToken = default);

        /// <summary>Removes a startup item.</summary>
        Task<Result> RemoveStartupItemAsync(
            string itemId,
            CancellationToken cancellationToken = default);
    }

    /// <summary>Startup item data transfer object.</summary>
    public sealed class StartupItemDto
    {
        /// <summary>Gets or sets the item identifier.</summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>Gets or sets the display name.</summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>Gets or sets the publisher.</summary>
        public string Publisher { get; set; } = string.Empty;

        /// <summary>Gets or sets the command.</summary>
        public string Command { get; set; } = string.Empty;

        /// <summary>Gets or sets the location (Registry/Folder).</summary>
        public string Location { get; set; } = string.Empty;

        /// <summary>Gets or sets the startup impact.</summary>
        public string Impact { get; set; } = string.Empty;

        /// <summary>Gets or sets a value indicating whether the item is enabled.</summary>
        public bool IsEnabled { get; set; }
    }

    // ========================================================================
    // IScheduledTaskService
    // ========================================================================

    /// <summary>
    /// Defines scheduled task management.
    /// </summary>
    public interface IScheduledTaskService
    {
        /// <summary>Gets all scheduled tasks.</summary>
        Task<Result<IReadOnlyList<ScheduledTaskDto>>> GetScheduledTasksAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Enables a scheduled task.</summary>
        Task<Result> EnableTaskAsync(
            string taskPath,
            CancellationToken cancellationToken = default);

        /// <summary>Disables a scheduled task.</summary>
        Task<Result> DisableTaskAsync(
            string taskPath,
            CancellationToken cancellationToken = default);

        /// <summary>Runs a scheduled task immediately.</summary>
        Task<Result> RunTaskAsync(
            string taskPath,
            CancellationToken cancellationToken = default);
    }

    /// <summary>Scheduled task data transfer object.</summary>
    public sealed class ScheduledTaskDto
    {
        /// <summary>Gets or sets the task path.</summary>
        public string TaskPath { get; set; } = string.Empty;

        /// <summary>Gets or sets the task name.</summary>
        public string TaskName { get; set; } = string.Empty;

        /// <summary>Gets or sets the state.</summary>
        public string State { get; set; } = string.Empty;

        /// <summary>Gets or sets the last run time.</summary>
        public DateTime? LastRunTime { get; set; }

        /// <summary>Gets or sets the next run time.</summary>
        public DateTime? NextRunTime { get; set; }

        /// <summary>Gets or sets the author.</summary>
        public string Author { get; set; } = string.Empty;

        /// <summary>Gets or sets the description.</summary>
        public string Description { get; set; } = string.Empty;
    }

    // ========================================================================
    // INetworkService
    // ========================================================================

    /// <summary>
    /// Defines network management operations.
    /// </summary>
    public interface INetworkService
    {
        /// <summary>Gets all network adapters.</summary>
        Task<Result<IReadOnlyList<NetworkAdapterDto>>> GetAdaptersAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Gets DNS configuration.</summary>
        Task<Result<DnsConfigDto>> GetDnsConfigAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Sets DNS servers.</summary>
        Task<Result> SetDnsServersAsync(
            string adapterId,
            string primaryDns,
            string secondaryDns,
            CancellationToken cancellationToken = default);

        /// <summary>Flushes the DNS cache.</summary>
        Task<Result> FlushDnsCacheAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Runs a network connectivity test.</summary>
        Task<Result<NetworkDiagnosticsDto>> RunDiagnosticsAsync(
            CancellationToken cancellationToken = default);
    }

    /// <summary>Network adapter data transfer object.</summary>
    public sealed class NetworkAdapterDto
    {
        /// <summary>Gets or sets the adapter ID.</summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>Gets or sets the name.</summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>Gets or sets the status.</summary>
        public string Status { get; set; } = string.Empty;

        /// <summary>Gets or sets the IP address.</summary>
        public string IpAddress { get; set; } = string.Empty;

        /// <summary>Gets or sets the MAC address.</summary>
        public string MacAddress { get; set; } = string.Empty;

        /// <summary>Gets or sets the speed in Mbps.</summary>
        public long SpeedMbps { get; set; }

        /// <summary>Gets or sets the adapter type.</summary>
        public string AdapterType { get; set; } = string.Empty;
    }

    /// <summary>DNS configuration data transfer object.</summary>
    public sealed class DnsConfigDto
    {
        /// <summary>Gets or sets the primary DNS server.</summary>
        public string PrimaryDns { get; set; } = string.Empty;

        /// <summary>Gets or sets the secondary DNS server.</summary>
        public string SecondaryDns { get; set; } = string.Empty;

        /// <summary>Gets or sets the DNS suffix.</summary>
        public string DnsSuffix { get; set; } = string.Empty;
    }

    /// <summary>Network diagnostics data transfer object.</summary>
    public sealed class NetworkDiagnosticsDto
    {
        /// <summary>Gets or sets the internet connectivity status.</summary>
        public bool IsConnected { get; set; }

        /// <summary>Gets or sets the latency in ms.</summary>
        public int LatencyMs { get; set; }

        /// <summary>Gets or sets the download speed in Mbps.</summary>
        public double DownloadSpeedMbps { get; set; }

        /// <summary>Gets or sets the upload speed in Mbps.</summary>
        public double UploadSpeedMbps { get; set; }

        /// <summary>Gets or sets the DNS resolution time in ms.</summary>
        public int DnsResolutionMs { get; set; }
    }

    // ========================================================================
    // IDiskCleanupService
    // ========================================================================

    /// <summary>
    /// Defines disk cleanup operations.
    /// </summary>
    public interface IDiskCleanupService
    {
        /// <summary>Scans for cleanable items.</summary>
        Task<Result<DiskScanResultDto>> ScanAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Cleans selected categories.</summary>
        Task<Result<CleanupResultDto>> CleanAsync(
            IReadOnlyList<string> categories,
            CancellationToken cancellationToken = default);

        /// <summary>Gets disk space information.</summary>
        Task<Result<IReadOnlyList<DiskSpaceDto>>> GetDiskSpaceAsync(
            CancellationToken cancellationToken = default);
    }

    /// <summary>Disk scan result.</summary>
    public sealed class DiskScanResultDto
    {
        /// <summary>Gets or sets the cleanable categories.</summary>
        public IReadOnlyList<CleanupCategoryDto> Categories { get; set; } =
            Array.Empty<CleanupCategoryDto>();

        /// <summary>Gets or sets the total reclaimable bytes.</summary>
        public long TotalReclaimableBytes { get; set; }
    }

    /// <summary>Cleanup category.</summary>
    public sealed class CleanupCategoryDto
    {
        /// <summary>Gets or sets the category name.</summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>Gets or sets the description.</summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>Gets or sets the reclaimable bytes.</summary>
        public long ReclaimableBytes { get; set; }

        /// <summary>Gets or sets the file count.</summary>
        public int FileCount { get; set; }

        /// <summary>Gets or sets a value indicating whether it is selected by default.</summary>
        public bool IsSelectedByDefault { get; set; }
    }

    /// <summary>Cleanup result.</summary>
    public sealed class CleanupResultDto
    {
        /// <summary>Gets or sets the bytes freed.</summary>
        public long BytesFreed { get; set; }

        /// <summary>Gets or sets the files removed.</summary>
        public int FilesRemoved { get; set; }

        /// <summary>Gets or sets the errors encountered.</summary>
        public IReadOnlyList<string> Errors { get; set; } = Array.Empty<string>();
    }

    /// <summary>Disk space information.</summary>
    public sealed class DiskSpaceDto
    {
        /// <summary>Gets or sets the drive letter.</summary>
        public string DriveLetter { get; set; } = string.Empty;

        /// <summary>Gets or sets the volume label.</summary>
        public string VolumeLabel { get; set; } = string.Empty;

        /// <summary>Gets or sets the total size in bytes.</summary>
        public long TotalBytes { get; set; }

        /// <summary>Gets or sets the free space in bytes.</summary>
        public long FreeBytes { get; set; }

        /// <summary>Gets the used space in bytes.</summary>
        public long UsedBytes => TotalBytes - FreeBytes;

        /// <summary>Gets the usage percentage.</summary>
        public double UsagePercent => TotalBytes > 0
            ? (double)UsedBytes / TotalBytes * 100.0
            : 0.0;
    }

    // ========================================================================
    // ISystemInfoService
    // ========================================================================

    /// <summary>
    /// Defines system information retrieval operations.
    /// </summary>
    public interface ISystemInfoService
    {
        /// <summary>Gets comprehensive system information.</summary>
        Task<Result<SystemInfoDto>> GetSystemInfoAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Gets current performance metrics.</summary>
        Task<Result<PerformanceMetricsDto>> GetPerformanceMetricsAsync(
            CancellationToken cancellationToken = default);
    }

    /// <summary>System information data transfer object.</summary>
    public sealed class SystemInfoDto
    {
        /// <summary>Gets or sets the computer name.</summary>
        public string ComputerName { get; set; } = string.Empty;

        /// <summary>Gets or sets the OS name.</summary>
        public string OsName { get; set; } = string.Empty;

        /// <summary>Gets or sets the OS version.</summary>
        public string OsVersion { get; set; } = string.Empty;

        /// <summary>Gets or sets the OS build.</summary>
        public string OsBuild { get; set; } = string.Empty;

        /// <summary>Gets or sets the CPU name.</summary>
        public string CpuName { get; set; } = string.Empty;

        /// <summary>Gets or sets the CPU cores.</summary>
        public int CpuCores { get; set; }

        /// <summary>Gets or sets the total RAM in GB.</summary>
        public double TotalRamGb { get; set; }

        /// <summary>Gets or sets the GPU name.</summary>
        public string GpuName { get; set; } = string.Empty;

        /// <summary>Gets or sets the system uptime.</summary>
        public TimeSpan Uptime { get; set; }

        /// <summary>Gets or sets the Windows activation status.</summary>
        public string ActivationStatus { get; set; } = string.Empty;

        /// <summary>Gets or sets the BIOS version.</summary>
        public string BiosVersion { get; set; } = string.Empty;

        /// <summary>Gets or sets the motherboard model.</summary>
        public string Motherboard { get; set; } = string.Empty;
    }

    /// <summary>Performance metrics data transfer object.</summary>
    public sealed class PerformanceMetricsDto
    {
        /// <summary>Gets or sets the CPU usage percentage.</summary>
        public double CpuUsagePercent { get; set; }

        /// <summary>Gets or sets the memory usage percentage.</summary>
        public double MemoryUsagePercent { get; set; }

        /// <summary>Gets or sets the available memory in GB.</summary>
        public double AvailableMemoryGb { get; set; }

        /// <summary>Gets or sets the disk read speed in MB/s.</summary>
        public double DiskReadMbps { get; set; }

        /// <summary>Gets or sets the disk write speed in MB/s.</summary>
        public double DiskWriteMbps { get; set; }

        /// <summary>Gets or sets the network send in KB/s.</summary>
        public double NetworkSendKbps { get; set; }

        /// <summary>Gets or sets the network receive in KB/s.</summary>
        public double NetworkReceiveKbps { get; set; }

        /// <summary>Gets or sets the GPU usage percentage.</summary>
        public double GpuUsagePercent { get; set; }

        /// <summary>Gets or sets the process count.</summary>
        public int ProcessCount { get; set; }
    }

    // ========================================================================
    // IOptimizationService
    // ========================================================================

    /// <summary>
    /// Defines system optimization operations.
    /// </summary>
    public interface IOptimizationService
    {
        /// <summary>Gets available optimization categories.</summary>
        Task<Result<IReadOnlyList<OptimizationCategoryDto>>> GetCategoriesAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Applies optimizations.</summary>
        Task<Result<OptimizationResultDto>> ApplyOptimizationsAsync(
            IReadOnlyList<string> tweakIds,
            CancellationToken cancellationToken = default);

        /// <summary>Creates a restore point before optimization.</summary>
        Task<Result<string>> CreateRestorePointAsync(
            string description,
            CancellationToken cancellationToken = default);
    }

    /// <summary>Optimization category.</summary>
    public sealed class OptimizationCategoryDto
    {
        /// <summary>Gets or sets the category name.</summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>Gets or sets the description.</summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>Gets or sets the tweaks in this category.</summary>
        public IReadOnlyList<TweakDto> Tweaks { get; set; } = Array.Empty<TweakDto>();
    }

    /// <summary>Individual tweak.</summary>
    public sealed class TweakDto
    {
        /// <summary>Gets or sets the tweak identifier.</summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>Gets or sets the display name.</summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>Gets or sets the description.</summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>Gets or sets a value indicating whether it is currently applied.</summary>
        public bool IsApplied { get; set; }

        /// <summary>Gets or sets the risk level.</summary>
        public string RiskLevel { get; set; } = "Low";
    }

    /// <summary>Optimization result.</summary>
    public sealed class OptimizationResultDto
    {
        /// <summary>Gets or sets the number of tweaks applied.</summary>
        public int TweaksApplied { get; set; }

        /// <summary>Gets or sets tweaks that failed.</summary>
        public IReadOnlyList<string> FailedTweaks { get; set; } = Array.Empty<string>();

        /// <summary>Gets or sets whether a reboot is required.</summary>
        public bool RebootRequired { get; set; }
    }

    // ========================================================================
    // IPrivacyService
    // ========================================================================

    /// <summary>
    /// Defines privacy management operations.
    /// </summary>
    public interface IPrivacyService
    {
        /// <summary>Gets the current privacy audit.</summary>
        Task<Result<PrivacyAuditDto>> GetPrivacyAuditAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Applies a privacy profile.</summary>
        Task<Result> ApplyPrivacyProfileAsync(
            string profileName,
            CancellationToken cancellationToken = default);

        /// <summary>Sets a specific privacy setting.</summary>
        Task<Result> SetPrivacySettingAsync(
            string settingId,
            bool enabled,
            CancellationToken cancellationToken = default);
    }

    /// <summary>Privacy audit result.</summary>
    public sealed class PrivacyAuditDto
    {
        /// <summary>Gets or sets the privacy score (0-100).</summary>
        public int Score { get; set; }

        /// <summary>Gets or sets the current profile name.</summary>
        public string CurrentProfile { get; set; } = string.Empty;

        /// <summary>Gets or sets privacy settings.</summary>
        public IReadOnlyList<PrivacySettingDto> Settings { get; set; } =
            Array.Empty<PrivacySettingDto>();
    }

    /// <summary>Individual privacy setting.</summary>
    public sealed class PrivacySettingDto
    {
        /// <summary>Gets or sets the setting ID.</summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>Gets or sets the display name.</summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>Gets or sets the category.</summary>
        public string Category { get; set; } = string.Empty;

        /// <summary>Gets or sets the description.</summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>Gets or sets a value indicating whether it is enabled.</summary>
        public bool IsEnabled { get; set; }

        /// <summary>Gets or sets the recommended state.</summary>
        public bool RecommendedState { get; set; }
    }

    // ========================================================================
    // ISecurityService
    // ========================================================================

    /// <summary>
    /// Defines security management operations.
    /// </summary>
    public interface ISecurityService
    {
        /// <summary>Gets the security status.</summary>
        Task<Result<SecurityStatusDto>> GetSecurityStatusAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Runs a security scan.</summary>
        Task<Result<SecurityScanDto>> RunSecurityScanAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Applies a security hardening action.</summary>
        Task<Result> ApplyHardeningAsync(
            string actionId,
            CancellationToken cancellationToken = default);
    }

    /// <summary>Security status.</summary>
    public sealed class SecurityStatusDto
    {
        /// <summary>Gets or sets the overall security score.</summary>
        public int Score { get; set; }

        /// <summary>Gets or sets the firewall status.</summary>
        public string FirewallStatus { get; set; } = string.Empty;

        /// <summary>Gets or sets the antivirus status.</summary>
        public string AntivirusStatus { get; set; } = string.Empty;

        /// <summary>Gets or sets the Windows Update status.</summary>
        public string UpdateStatus { get; set; } = string.Empty;

        /// <summary>Gets or sets UAC level.</summary>
        public string UacLevel { get; set; } = string.Empty;

        /// <summary>Gets or sets the BitLocker status.</summary>
        public string BitLockerStatus { get; set; } = string.Empty;
    }

    /// <summary>Security scan result.</summary>
    public sealed class SecurityScanDto
    {
        /// <summary>Gets or sets the issues found.</summary>
        public IReadOnlyList<SecurityIssueDto> Issues { get; set; } =
            Array.Empty<SecurityIssueDto>();

        /// <summary>Gets or sets the total issues count.</summary>
        public int TotalIssues => Issues.Count;
    }

    /// <summary>Individual security issue.</summary>
    public sealed class SecurityIssueDto
    {
        /// <summary>Gets or sets the issue ID.</summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>Gets or sets the issue title.</summary>
        public string Title { get; set; } = string.Empty;

        /// <summary>Gets or sets the severity.</summary>
        public string Severity { get; set; } = string.Empty;

        /// <summary>Gets or sets the description.</summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>Gets or sets the remediation action ID.</summary>
        public string RemediationActionId { get; set; } = string.Empty;
    }

    // ========================================================================
    // IUpdateService
    // ========================================================================

    /// <summary>
    /// Defines Windows Update management operations.
    /// </summary>
    public interface IUpdateService
    {
        /// <summary>Checks for available updates.</summary>
        Task<Result<IReadOnlyList<WindowsUpdateDto>>> CheckForUpdatesAsync(
            CancellationToken cancellationToken = default);

        /// <summary>Installs selected updates.</summary>
        Task<Result> InstallUpdatesAsync(
            IReadOnlyList<string> updateIds,
            CancellationToken cancellationToken = default);

        /// <summary>Gets update history.</summary>
        Task<Result<IReadOnlyList<WindowsUpdateDto>>> GetUpdateHistoryAsync(
            CancellationToken cancellationToken = default);
    }

    /// <summary>Windows Update data transfer object.</summary>
    public sealed class WindowsUpdateDto
    {
        /// <summary>Gets or sets the update ID.</summary>
        public string Id { get; set; } = string.Empty;

        /// <summary>Gets or sets the title.</summary>
        public string Title { get; set; } = string.Empty;

        /// <summary>Gets or sets the description.</summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>Gets or sets the KB number.</summary>
        public string KbNumber { get; set; } = string.Empty;

        /// <summary>Gets or sets the size in bytes.</summary>
        public long SizeBytes { get; set; }

        /// <summary>Gets or sets the category.</summary>
        public string Category { get; set; } = string.Empty;

        /// <summary>Gets or sets a value indicating whether it is installed.</summary>
        public bool IsInstalled { get; set; }

        /// <summary>Gets or sets the install date.</summary>
        public DateTime? InstalledDate { get; set; }
    }

    // ========================================================================
    // IAppUpdateService
    // ========================================================================

    /// <summary>
    /// Defines application (Better11) update check, download, and install operations.
    /// </summary>
    public interface IAppUpdateService
    {
        /// <summary>Checks for a newer application version; returns update info if available.</summary>
        Task<Result<AppUpdateInfo?>> CheckForUpdatesAsync(CancellationToken cancellationToken = default);

        /// <summary>Downloads the update package to a temporary file and returns its path.</summary>
        Task<Result<string>> DownloadUpdateAsync(AppUpdateInfo updateInfo, CancellationToken cancellationToken = default);

        /// <summary>Installs the update from the downloaded package path (e.g. launches MSIX installer).</summary>
        Task<Result> InstallUpdateAsync(string downloadedPath, CancellationToken cancellationToken = default);
    }

    /// <summary>Application update information from the version manifest.</summary>
    public sealed class AppUpdateInfo
    {
        /// <summary>Gets or sets the available version string (e.g. "1.1.0").</summary>
        public string Version { get; set; } = string.Empty;

        /// <summary>Gets or sets the download URL for the update package (e.g. MSIX).</summary>
        public string DownloadUrl { get; set; } = string.Empty;

        /// <summary>Gets or sets optional release notes or description.</summary>
        public string ReleaseNotes { get; set; } = string.Empty;

        /// <summary>Gets or sets the published date of the release.</summary>
        public DateTimeOffset? PublishDate { get; set; }
    }

    // ========================================================================
    // IAnalyticsService
    // ========================================================================

    /// <summary>
    /// Defines analytics and telemetry tracking capabilities.
    /// </summary>
    public interface IAnalyticsService
    {
        /// <summary>Tracks a custom event.</summary>
        Task TrackEventAsync(string eventName, IDictionary<string, string>? properties = null, CancellationToken cancellationToken = default);

        /// <summary>Tracks an exception.</summary>
        Task TrackExceptionAsync(Exception exception, IDictionary<string, string>? properties = null, CancellationToken cancellationToken = default);

        /// <summary>Tracks a page view.</summary>
        Task TrackPageViewAsync(string pageName, CancellationToken cancellationToken = default);
    }
}
