// ============================================================================
// File: src/Better11.App/Views/DriverManagerPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.Driver;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views
{
    /// <summary>
    /// Code-behind for <see cref="DriverManagerPage"/>.
    /// </summary>
    public sealed partial class DriverManagerPage : Page
    {
        /// <summary>Gets the ViewModel.</summary>
        public DriverViewModel ViewModel { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="DriverManagerPage"/> class.
        /// </summary>
        public DriverManagerPage()
        {
            ViewModel = App.GetService<DriverViewModel>();
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
