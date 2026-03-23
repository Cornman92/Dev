// ============================================================================
// File: src/Better11.App/Views/PackageManagerPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.Package;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views
{
    /// <summary>
    /// Code-behind for <see cref="PackageManagerPage"/>.
    /// </summary>
    public sealed partial class PackageManagerPage : Page
    {
        /// <summary>Gets the ViewModel.</summary>
        public PackageViewModel ViewModel { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="PackageManagerPage"/> class.
        /// </summary>
        public PackageManagerPage()
        {
            ViewModel = App.GetService<PackageViewModel>();
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
