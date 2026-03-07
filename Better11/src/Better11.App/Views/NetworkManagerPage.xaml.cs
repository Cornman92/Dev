// ============================================================================
// File: src/Better11.App/Views/NetworkManagerPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.Network;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views
{
    /// <summary>
    /// Code-behind for <see cref="NetworkManagerPage"/>.
    /// </summary>
    public sealed partial class NetworkManagerPage : Page
    {
        /// <summary>Gets the ViewModel.</summary>
        public NetworkViewModel ViewModel { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="NetworkManagerPage"/> class.
        /// </summary>
        public NetworkManagerPage()
        {
            ViewModel = App.GetService<NetworkViewModel>();
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
