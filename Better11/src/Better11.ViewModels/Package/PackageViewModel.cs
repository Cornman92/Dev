// ============================================================================
// File: src/Better11.ViewModels/Package/PackageViewModel.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Package
{
    /// <summary>
    /// ViewModel for the Package Manager page.
    /// </summary>
    public sealed partial class PackageViewModel : BaseViewModel
    {
        private readonly IPackageService _service;

        /// <summary>
        /// Initializes a new instance of the <see cref="PackageViewModel"/> class.
        /// </summary>
        public PackageViewModel(IPackageService service, ILogger<PackageViewModel> logger)
            : base(logger)
        {
            _service = service ?? throw new ArgumentNullException(nameof(service));
            PageTitle = "Package Manager";
        }

        /// <summary>Gets the installed packages.</summary>
        public ObservableCollection<PackageDto> InstalledPackages { get; } = new();

        /// <summary>Gets the available updates.</summary>
        public ObservableCollection<PackageDto> AvailableUpdates { get; } = new();

        /// <summary>Gets or sets the selected package.</summary>
        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(SelectedCount))]
        private PackageDto? _selectedPackage;

        /// <summary>Gets or sets the search query.</summary>
        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(FilteredPackages))]
        private string _searchQuery = string.Empty;

        /// <summary>Filtered list for list view (alias: InstalledPackages).</summary>
        public ObservableCollection<PackageDto> FilteredPackages => InstalledPackages;

        /// <summary>Select all (for XAML).</summary>
        [ObservableProperty]
        private bool _isAllSelected;

        /// <summary>Selected item count (0 or 1).</summary>
        public int SelectedCount => SelectedPackage is null ? 0 : 1;

        /// <summary>Total package count.</summary>
        public int TotalCount => InstalledPackages.Count;

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
        private async Task InstallNewAsync(CancellationToken cancellationToken = default)
        {
            await Task.CompletedTask.ConfigureAwait(false);
            SetSuccess("Use Search to find and install packages.");
        }

        [RelayCommand]
        private async Task InstallSelectedAsync(CancellationToken cancellationToken = default)
        {
            if (SelectedPackage is null) { SetSuccess("Select a package first."); return; }
            await InstallPackageAsync(SelectedPackage, cancellationToken).ConfigureAwait(false);
        }

        [RelayCommand]
        private async Task UninstallSelectedAsync(CancellationToken cancellationToken = default)
        {
            if (SelectedPackage is null) { SetSuccess("Select a package first."); return; }
            await UninstallPackageAsync(SelectedPackage, cancellationToken).ConfigureAwait(false);
        }

        [RelayCommand]
        private void ExportList()
        {
            SetSuccess("Export not implemented.");
        }

        [RelayCommand]
        private async Task LoadDataAsync(CancellationToken cancellationToken = default)
        {
            await SafeExecuteAsync(
                async ct =>
                {
                    var result = await _service.GetInstalledPackagesAsync(ct).ConfigureAwait(false);
                    if (result.IsSuccess)
                    {
                        RunOnUIThread(() =>
                        {
                            InstalledPackages.Clear();
                            foreach (var pkg in result.Value) { InstalledPackages.Add(pkg); }
                        });
                    }
                    else { SetErrorFromResult(result); }

                    var updates = await _service.GetAvailableUpdatesAsync(ct).ConfigureAwait(false);
                    if (updates.IsSuccess)
                    {
                        RunOnUIThread(() =>
                        {
                            AvailableUpdates.Clear();
                            foreach (var u in updates.Value) { AvailableUpdates.Add(u); }
                        });
                    }
                },
                "Loading Package Manager...",
                cancellationToken).ConfigureAwait(false);
        }

        [RelayCommand]
        private async Task InstallPackageAsync(PackageDto package, CancellationToken ct = default)
        {
            if (package is null) { return; }
            await SafeExecuteAsync(
                async token =>
                {
                    var result = await _service.InstallPackageAsync(
                        package.Id, package.Source, token).ConfigureAwait(false);
                    if (result.IsSuccess) { SetSuccess($"Installed {package.Name}"); await LoadDataAsync(token).ConfigureAwait(false); }
                    else { SetErrorFromResult(result); }
                },
                $"Installing {package.Name}...", ct).ConfigureAwait(false);
        }

        [RelayCommand]
        private async Task UninstallPackageAsync(PackageDto package, CancellationToken ct = default)
        {
            if (package is null) { return; }
            await SafeExecuteAsync(
                async token =>
                {
                    var result = await _service.UninstallPackageAsync(package.Id, token).ConfigureAwait(false);
                    if (result.IsSuccess) { SetSuccess($"Uninstalled {package.Name}"); await LoadDataAsync(token).ConfigureAwait(false); }
                    else { SetErrorFromResult(result); }
                },
                $"Uninstalling {package.Name}...", ct).ConfigureAwait(false);
        }

        [RelayCommand]
        private async Task SearchPackagesAsync(CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(SearchQuery)) { return; }
            await SafeExecuteAsync(
                async token =>
                {
                    var result = await _service.SearchPackagesAsync(SearchQuery, token).ConfigureAwait(false);
                    if (result.IsSuccess)
                    {
                        RunOnUIThread(() =>
                        {
                            InstalledPackages.Clear();
                            foreach (var p in result.Value) { InstalledPackages.Add(p); }
                        });
                    }
                    else { SetErrorFromResult(result); }
                },
                "Searching...", ct).ConfigureAwait(false);
        }
    }
}
