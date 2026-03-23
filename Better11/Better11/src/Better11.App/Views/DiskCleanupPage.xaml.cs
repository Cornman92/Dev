// ============================================================================
// File: src/Better11.App/Views/DiskCleanupPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.DiskCleanup;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views
{
    /// <summary>
    /// Code-behind for <see cref="DiskCleanupPage"/>.
    /// </summary>
    public sealed partial class DiskCleanupPage : Page
    {
        /// <summary>Gets the ViewModel.</summary>
        public DiskCleanupViewModel ViewModel { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="DiskCleanupPage"/> class.
        /// </summary>
        public DiskCleanupPage()
        {
            ViewModel = App.GetService<DiskCleanupViewModel>();
            InitializeComponent();
            DataContext = ViewModel;
        }

        /// <inheritdoc/>
        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);
            if (!ViewModel.IsInitialized)
            {
                await ViewModel.InitializeAsync();
            }
        }
    }
}
