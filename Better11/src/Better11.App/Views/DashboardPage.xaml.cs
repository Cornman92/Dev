// ============================================================================
// File: src/Better11.App/Views/DashboardPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.Dashboard;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views
{
    /// <summary>
    /// Code-behind for <see cref="DashboardPage"/>.
    /// </summary>
    public sealed partial class DashboardPage : Page
    {
        /// <summary>Gets the ViewModel.</summary>
        public DashboardViewModel ViewModel { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="DashboardPage"/> class.
        /// </summary>
        public DashboardPage()
        {
            ViewModel = App.GetService<DashboardViewModel>();
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
