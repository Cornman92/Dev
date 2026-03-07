// ============================================================================
// File: src/Better11.App/Views/AboutPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.About;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views
{
    /// <summary>
    /// Code-behind for <see cref="AboutPage"/>.
    /// </summary>
    public sealed partial class AboutPage : Page
    {
        /// <summary>Gets the ViewModel.</summary>
        public AboutViewModel ViewModel { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="AboutPage"/> class.
        /// </summary>
        public AboutPage()
        {
            ViewModel = App.GetService<AboutViewModel>();
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
