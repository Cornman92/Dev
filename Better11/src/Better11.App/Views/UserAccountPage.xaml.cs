// Copyright (c) Better11. All rights reserved.

namespace Better11.App.Views;

using Better11.Core.Interfaces;
using Better11.ViewModels.UserAccount;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

/// <summary>
/// View for User Account Management.
/// </summary>
public sealed partial class UserAccountPage : Page
{
    private readonly UserAccountViewModel _vm;

    /// <summary>
    /// Initializes a new instance of the <see cref="UserAccountPage"/> class.
    /// </summary>
    public UserAccountPage()
    {
        InitializeComponent();
        _vm = App.GetService<UserAccountViewModel>();
        DataContext = _vm;

        _vm.PropertyChanged += (s, e) =>
        {
            DispatcherQueue.TryEnqueue(() =>
            {
                StatusText.Text = _vm.StatusMessage;
                LoadingRing.IsActive = _vm.IsLoading;
                SummaryText.Text = $"{_vm.AccountCount} local accounts";
                MinLenBox.Value = _vm.PolicyMinLength;
                MaxAgeBox.Value = _vm.PolicyMaxAge;
                ComplexitySwitch.IsOn = _vm.PolicyComplexity;
                LockoutText.Text = $"Lockout threshold: {_vm.LockoutThreshold}";
                AutoLoginText.Text = _vm.AutoLoginEnabled ? $"Auto-login: {_vm.AutoLoginUser}" : "Auto-login: Disabled";
            });
        };

        AccountList.ItemsSource = _vm.Accounts;
        GroupList.ItemsSource = _vm.Groups;
        MemberList.ItemsSource = _vm.GroupMembers;
        ProfileList.ItemsSource = _vm.Profiles;
        AuditList.ItemsSource = _vm.AuditEvents;
        SessionList.ItemsSource = _vm.Sessions;
    }

    private async void Page_Loaded(object sender, RoutedEventArgs e)
    {
        await _vm.InitializeAsync().ConfigureAwait(false);
    }

    private void CreateAccount_Click(object sender, RoutedEventArgs e)
    {
        _vm.NewUsername = NewUserBox.Text;
        _vm.NewPassword = NewPassBox.Password;
        _vm.NewFullName = NewFullNameBox.Text;
        _vm.CreateAccountCommand.Execute(null);
    }

    private void DeleteAccount_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string u)
        {
            _vm.DeleteAccountCommand.Execute(u);
        }
    }

    private void ToggleAccount_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string u)
        {
            _vm.ToggleAccountCommand.Execute(u);
        }
    }

    private void GroupList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (GroupList.SelectedItem is LocalGroupDto g)
        {
            _vm.SelectedGroup = g;
            _vm.LoadGroupMembersCommand.Execute(g.Name);
        }
    }

    private void AddMember_Click(object sender, RoutedEventArgs e)
    {
        _vm.MemberUsername = MemberUserBox.Text;
        _vm.AddMemberCommand.Execute(null);
    }

    private void RemoveMember_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string u)
        {
            _vm.RemoveMemberCommand.Execute(u);
        }
    }

    private void ApplyPolicy_Click(object sender, RoutedEventArgs e)
    {
        _vm.PolicyMinLength = (int)MinLenBox.Value;
        _vm.PolicyMaxAge = (int)MaxAgeBox.Value;
        _vm.PolicyComplexity = ComplexitySwitch.IsOn;
        _vm.ApplyPasswordPolicyCommand.Execute(null);
    }

    private void SetAutoLogin_Click(object sender, RoutedEventArgs e)
    {
        _vm.AutoLoginUser = AutoUserBox.Text;
        _vm.AutoLoginPass = AutoPassBox.Password;
        _vm.SetAutoLoginCommand.Execute(null);
    }

    private void DisableAutoLogin_Click(object sender, RoutedEventArgs e)
    {
        _vm.DisableAutoLoginCommand.Execute(null);
    }

    private void LoadAudit_Click(object sender, RoutedEventArgs e)
    {
        _vm.LoadAuditCommand.Execute(null);
    }

    private void LoadSessions_Click(object sender, RoutedEventArgs e)
    {
        _vm.LoadSessionsCommand.Execute(null);
    }

    private void LogoffSession_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is int id)
        {
            _vm.LogoffSessionCommand.Execute(id);
        }
    }
}
