// ============================================================================
// File: src/Better11.ViewModels/DiskCleanup/DiskCleanupViewModel.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.DiskCleanup
{
    /// <summary>
    /// Display item for a cleanup category with selection state (for binding).
    /// </summary>
    public sealed partial class CleanupCategoryItem : ObservableObject
    {
        /// <summary>Category name.</summary>
        public string Name { get; init; } = string.Empty;

        /// <summary>Description.</summary>
        public string Description { get; init; } = string.Empty;

        /// <summary>Glyph for list icon.</summary>
        public string Icon { get; init; } = "\uE9D9";

        /// <summary>File count.</summary>
        public int ItemCount { get; init; }

        /// <summary>Formatted size string.</summary>
        public string Size { get; init; } = string.Empty;

        /// <summary>Risk level label.</summary>
        public string RiskLevel { get; init; } = "Low";

        /// <summary>Background for risk badge.</summary>
        public string RiskBackground { get; init; } = "#2EA043";

        /// <summary>Foreground for risk badge.</summary>
        public string RiskForeground { get; init; } = "#FFFFFF";

        /// <summary>Reclaimable bytes (for summing selected).</summary>
        public long ReclaimableBytes { get; init; }

        /// <summary>Selected for cleanup.</summary>
        [ObservableProperty]
        private bool _isSelected;
    }

    /// <summary>
    /// ViewModel for the Disk Cleanup page.
    /// </summary>
    public sealed partial class DiskCleanupViewModel : BaseViewModel
    {
        private readonly IDiskCleanupService _service;

        /// <summary>
        /// Initializes a new instance of the <see cref="DiskCleanupViewModel"/> class.
        /// </summary>
        public DiskCleanupViewModel(IDiskCleanupService service, ILogger<DiskCleanupViewModel> logger)
            : base(logger)
        {
            _service = service ?? throw new ArgumentNullException(nameof(service));
            PageTitle = "Disk Cleanup";
        }

        /// <summary>Gets or sets the scan result.</summary>
        [ObservableProperty]
        private DiskScanResultDto? _scanResult;

        /// <summary>Gets the disk space info.</summary>
        public ObservableCollection<DiskSpaceDto> DiskSpaces { get; } = new();

        /// <summary>Gets category items for the list (with selection).</summary>
        public ObservableCollection<CleanupCategoryItem> Categories { get; } = new();

        /// <summary>Gets or sets the total reclaimable display text.</summary>
        [ObservableProperty]
        private string _reclaimableText = "Scan to see reclaimable space";

        /// <summary>Total space string (first drive or combined).</summary>
        public string TotalSpace => FormatBytes(FirstDisk?.TotalBytes ?? 0);

        /// <summary>Used space string.</summary>
        public string UsedSpace => FormatBytes(FirstDisk?.UsedBytes ?? 0);

        /// <summary>Free space string.</summary>
        public string FreeSpace => FormatBytes(FirstDisk?.FreeBytes ?? 0);

        /// <summary>Total reclaimable string from last scan.</summary>
        public string TotalReclaimable => ReclaimableText;

        /// <summary>Used percentage (0–100) for progress bar.</summary>
        public double UsedPercentage => FirstDisk?.UsagePercent ?? 0;

        /// <summary>Whether a scan is in progress.</summary>
        public bool IsScanning => IsBusy;

        /// <summary>Scan progress 0–100.</summary>
        public double ScanProgress => IsBusy ? 50 : 100;

        /// <summary>Status text during scan.</summary>
        public string ScanStatusText => LoadingMessage;

        /// <summary>Select/deselect all categories.</summary>
        [ObservableProperty]
        private bool _isAllSelected;

        /// <summary>Number of selected categories.</summary>
        public int SelectedCategoryCount => Categories.Count(c => c.IsSelected);

        /// <summary>Formatted reclaimable size for selected categories.</summary>
        public string SelectedReclaimable => FormatBytes(Categories.Where(c => c.IsSelected).Sum(c => c.ReclaimableBytes));

        private DiskSpaceDto? FirstDisk => DiskSpaces.FirstOrDefault();

        partial void OnIsAllSelectedChanged(bool value)
        {
            foreach (var c in Categories)
            {
                c.IsSelected = value;
            }

            OnPropertyChanged(nameof(SelectedCategoryCount));
            OnPropertyChanged(nameof(SelectedReclaimable));
        }

        /// <inheritdoc/>
        protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
        {
            await LoadDataAsync(cancellationToken).ConfigureAwait(false);
        }

        [RelayCommand]
        private async Task RefreshAsync(CancellationToken cancellationToken = default)
        {
            await LoadDataAsync(cancellationToken).ConfigureAwait(false);
        }

        [RelayCommand]
        private async Task LoadDataAsync(CancellationToken cancellationToken = default)
        {
            await SafeExecuteAsync(
                async ct =>
                {
                    var diskResult = await _service.GetDiskSpaceAsync(ct).ConfigureAwait(false);
                    if (diskResult.IsSuccess)
                    {
                        RunOnUIThread(() =>
                        {
                            DiskSpaces.Clear();
                            foreach (var d in diskResult.Value)
                            {
                                DiskSpaces.Add(d);
                            }

                            NotifyDiskSpaceChanged();
                        });
                    }
                },
                "Loading Disk Cleanup...",
                cancellationToken).ConfigureAwait(false);
        }

        [RelayCommand]
        private async Task ScanAsync(CancellationToken ct = default)
        {
            await SafeExecuteAsync(
                async token =>
                {
                    var result = await _service.ScanAsync(token).ConfigureAwait(false);
                    if (result.IsSuccess)
                    {
                        ScanResult = result.Value;
                        var mb = result.Value.TotalReclaimableBytes / (1024.0 * 1024.0);
                        ReclaimableText = $"{mb:F1} MB can be recovered";
                        RunOnUIThread(() => SyncCategoriesFromScan());
                    }
                    else
                    {
                        SetErrorFromResult(result);
                    }
                },
                "Scanning...",
                ct).ConfigureAwait(false);
        }

        [RelayCommand]
        private async Task CleanAsync(CancellationToken ct = default)
        {
            var selected = Categories.Where(c => c.IsSelected).Select(c => c.Name).ToList();
            if (selected.Count == 0)
            {
                ErrorMessage = "Select at least one category to clean.";
                return;
            }

            await SafeExecuteAsync(
                async token =>
                {
                    var result = await _service.CleanAsync(selected, token).ConfigureAwait(false);
                    if (result.IsSuccess)
                    {
                        var mb = result.Value.BytesFreed / (1024.0 * 1024.0);
                        SetSuccess($"Freed {mb:F1} MB ({result.Value.FilesRemoved} files)");
                        await LoadDataAsync(token).ConfigureAwait(false);
                    }
                    else
                    {
                        SetErrorFromResult(result);
                    }
                },
                "Cleaning...",
                ct).ConfigureAwait(false);
        }

        [RelayCommand]
        private void SelectRecommended()
        {
            foreach (var c in Categories)
            {
                c.IsSelected = true;
            }

            IsAllSelected = true;
            OnPropertyChanged(nameof(SelectedCategoryCount));
            OnPropertyChanged(nameof(SelectedReclaimable));
        }

        [RelayCommand]
        private void ExportReport()
        {
            SetSuccess("Export report not implemented.");
        }

        private void SyncCategoriesFromScan()
        {
            Categories.Clear();
            if (ScanResult is null)
            {
                return;
            }

            foreach (var c in ScanResult.Categories)
            {
                var item = new CleanupCategoryItem
                {
                    Name = c.Name,
                    Description = c.Description,
                    ItemCount = c.FileCount,
                    Size = FormatBytes(c.ReclaimableBytes),
                    ReclaimableBytes = c.ReclaimableBytes,
                    IsSelected = c.IsSelectedByDefault,
                    RiskLevel = "Low",
                };
                item.PropertyChanged += (_, e) =>
                {
                    if (e.PropertyName == nameof(CleanupCategoryItem.IsSelected))
                    {
                        OnPropertyChanged(nameof(SelectedCategoryCount));
                        OnPropertyChanged(nameof(SelectedReclaimable));
                    }
                };
                Categories.Add(item);
            }

            IsAllSelected = Categories.All(c => c.IsSelected);
            OnPropertyChanged(nameof(SelectedCategoryCount));
            OnPropertyChanged(nameof(SelectedReclaimable));
        }

        private void NotifyDiskSpaceChanged()
        {
            OnPropertyChanged(nameof(TotalSpace));
            OnPropertyChanged(nameof(UsedSpace));
            OnPropertyChanged(nameof(FreeSpace));
            OnPropertyChanged(nameof(UsedPercentage));
        }

        private static string FormatBytes(long bytes)
        {
            if (bytes < 1024)
            {
                return $"{bytes} B";
            }

            if (bytes < 1024 * 1024)
            {
                return $"{bytes / 1024.0:F1} KB";
            }

            if (bytes < 1024 * 1024 * 1024)
            {
                return $"{bytes / (1024.0 * 1024.0):F1} MB";
            }

            return $"{bytes / (1024.0 * 1024.0 * 1024.0):F1} GB";
        }
    }
}
