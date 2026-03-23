// ============================================================================
// File: src/Better11.App/Views/SystemInfoPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.SystemInfo;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views
{
    /// <summary>
    /// Code-behind for <see cref="SystemInfoPage"/>.
    /// </summary>
    public sealed partial class SystemInfoPage : Page
    {
        /// <summary>Gets the ViewModel.</summary>
        public SystemInfoViewModel ViewModel { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="SystemInfoPage"/> class.
        /// </summary>
        public SystemInfoPage()
        {
            ViewModel = App.GetService<SystemInfoViewModel>();
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
