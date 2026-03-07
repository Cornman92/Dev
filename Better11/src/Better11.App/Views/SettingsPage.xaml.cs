// ============================================================================
// File: src/Better11.App/Views/SettingsPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.Settings;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Documents;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views
{
    /// <summary>
    /// Code-behind for <see cref="SettingsPage"/>.
    /// </summary>
    public sealed partial class SettingsPage : Page
    {
        /// <summary>Gets the ViewModel.</summary>
        public SettingsViewModel ViewModel { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="SettingsPage"/> class.
        /// </summary>
        public SettingsPage()
        {
            ViewModel = App.GetService<SettingsViewModel>();
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

        private void PrivacyPolicyLink_Click(Hyperlink sender, HyperlinkClickEventArgs args)
        {
            ViewModel.OpenPrivacyPolicyCommand.Execute(null);
        }
    }
}
