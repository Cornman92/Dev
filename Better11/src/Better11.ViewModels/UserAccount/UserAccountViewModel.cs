// Copyright (c) Better11. All rights reserved.

namespace Better11.ViewModels.UserAccount;

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using Better11.ViewModels.Base;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

/// <summary>
/// ViewModel for managing local user accounts, group memberships, and active user sessions.
/// </summary>
public sealed partial class UserAccountViewModel : BaseViewModel
{
    private readonly IUserAccountService _service;

    [ObservableProperty]
    private string _statusMessage = string.Empty;

    [ObservableProperty]
    private int _accountCount;

    [ObservableProperty]
    private int _policyMinLength;

    [ObservableProperty]
    private int _policyMaxAge;

    [ObservableProperty]
    private bool _policyComplexity;

    [ObservableProperty]
    private int _lockoutThreshold;

    [ObservableProperty]
    private bool _autoLoginEnabled;

    [ObservableProperty]
    private string _autoLoginUser = string.Empty;

    [ObservableProperty]
    private string _autoLoginPass = string.Empty;

    [ObservableProperty]
    private string _newUsername = string.Empty;

    [ObservableProperty]
    private string _newPassword = string.Empty;

    [ObservableProperty]
    private string _newFullName = string.Empty;

    [ObservableProperty]
    private string _memberUsername = string.Empty;

    [ObservableProperty]
    private LocalGroupDto? _selectedGroup;

    /// <summary>
    /// Initializes a new instance of the <see cref="UserAccountViewModel"/> class.
    /// </summary>
    public UserAccountViewModel(IUserAccountService service, ILogger<UserAccountViewModel> logger)
        : base(logger)
    {
        ArgumentNullException.ThrowIfNull(service);
        _service = service;
        PageTitle = "User Account Management";
    }

    /// <summary>Gets the list of currently active user sessions.</summary>
    public ObservableCollection<UserSessionDto> Sessions { get; } = new();

    /// <summary>Gets the list of available local user accounts.</summary>
    public ObservableCollection<LocalAccountDto> Accounts { get; } = new();

    /// <summary>Gets the list of available local security groups.</summary>
    public ObservableCollection<LocalGroupDto> Groups { get; } = new();

    /// <summary>Gets the list of group members.</summary>
    public ObservableCollection<GroupMemberDto> GroupMembers { get; } = new();

    /// <summary>Gets the list of user profiles.</summary>
    public ObservableCollection<UserProfileDto> Profiles { get; } = new();

    /// <summary>Gets the list of security audit events.</summary>
    public ObservableCollection<SecurityAuditDto> AuditEvents { get; } = new();

    /// <summary>Gets a value indicating whether the service is currently loading data.</summary>
    public bool IsLoading => IsBusy;

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        await LoadAllCoreAsync(cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Reloads accounts, groups, and sessions sequentially.</summary>
    [RelayCommand]
    private async Task LoadAllAsync()
    {
        await SafeExecuteAsync(
            async ct =>
            {
                await LoadAllCoreAsync(ct).ConfigureAwait(false);
            },
            "Loading user account data...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadAccountsAsync()
    {
        await SafeExecuteAsync(
            LoadAccountsCoreAsync,
            "Loading local accounts...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadGroupsAsync()
    {
        await SafeExecuteAsync(
            LoadGroupsCoreAsync,
            "Loading local groups...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadSessionsAsync()
    {
        await SafeExecuteAsync(
            LoadSessionsCoreAsync,
            "Loading active sessions...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadProfilesAsync()
    {
        await SafeExecuteAsync(
            LoadProfilesCoreAsync,
            "Loading user profiles...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadPolicyAsync()
    {
        await SafeExecuteAsync(
            LoadPolicyCoreAsync,
            "Loading password policy...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadAutoLoginAsync()
    {
        await SafeExecuteAsync(
            LoadAutoLoginCoreAsync,
            "Loading auto-login config...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task CreateAccountAsync()
    {
        if (string.IsNullOrWhiteSpace(NewUsername))
        {
            SetError("Username is required.");
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.CreateAccountAsync(NewUsername, NewPassword, NewFullName, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess($"Account '{NewUsername}' created successfully.");
                    await LoadAccountsCoreAsync(ct).ConfigureAwait(false);
                    NewUsername = string.Empty;
                    NewPassword = string.Empty;
                    NewFullName = string.Empty;
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            $"Creating account {NewUsername}...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task DeleteAccountAsync(string username)
    {
        if (string.IsNullOrWhiteSpace(username))
        {
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.DeleteAccountAsync(username, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess($"Account '{username}' deleted.");
                    await LoadAccountsCoreAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            $"Deleting account {username}...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task ToggleAccountAsync(string username)
    {
        if (string.IsNullOrWhiteSpace(username))
        {
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var account = Accounts.FirstOrDefault(a => a.Username == username);
                if (account == null)
                {
                    return;
                }

                var newState = !account.Enabled;
                var result = await _service.SetAccountEnabledAsync(username, newState, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess($"Account '{username}' {(newState ? "enabled" : "disabled")}.");
                    await LoadAccountsCoreAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            $"Toggling account {username}...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadGroupMembersAsync(string groupName)
    {
        if (string.IsNullOrWhiteSpace(groupName))
        {
            return;
        }

        await SafeExecuteAsync(
            ct => LoadGroupMembersCoreAsync(groupName, ct),
            $"Loading members for {groupName}...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task AddMemberAsync()
    {
        if (string.IsNullOrWhiteSpace(MemberUsername) || SelectedGroup == null)
        {
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.AddGroupMemberAsync(SelectedGroup.Name, MemberUsername, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess($"User '{MemberUsername}' added to group '{SelectedGroup.Name}'.");
                    await LoadGroupMembersCoreAsync(SelectedGroup.Name, ct).ConfigureAwait(false);
                    MemberUsername = string.Empty;
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            $"Adding {MemberUsername} to {SelectedGroup.Name}...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task RemoveMemberAsync(string username)
    {
        if (string.IsNullOrWhiteSpace(username) || SelectedGroup == null)
        {
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.RemoveGroupMemberAsync(SelectedGroup.Name, username, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess($"User '{username}' removed from group '{SelectedGroup.Name}'.");
                    await LoadGroupMembersCoreAsync(SelectedGroup.Name, ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            $"Removing {username} from {SelectedGroup.Name}...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task ApplyPasswordPolicyAsync()
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.SetPasswordPolicyAsync(PolicyMinLength, PolicyComplexity, PolicyMaxAge, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess("Password policy updated.");
                    await LoadPolicyCoreAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Updating password policy...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task SetAutoLoginAsync()
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.SetAutoLoginAsync(AutoLoginUser, AutoLoginPass, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess("Auto-login enabled.");
                    await LoadAutoLoginCoreAsync(ct).ConfigureAwait(false);
                    AutoLoginPass = string.Empty;
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Enabling auto-login...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task DisableAutoLoginAsync()
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.DisableAutoLoginAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess("Auto-login disabled.");
                    await LoadAutoLoginCoreAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Disabling auto-login...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadAuditAsync()
    {
        await SafeExecuteAsync(
            LoadAuditCoreAsync,
            "Loading security audit...").ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LogoffSessionAsync(int sessionId)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.LogoffSessionAsync(sessionId, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess($"Session {sessionId} logged off.");
                    await LoadSessionsCoreAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            $"Logging off session {sessionId}...").ConfigureAwait(false);
    }

    private async Task LoadAllCoreAsync(CancellationToken cancellationToken)
    {
        await LoadAccountsCoreAsync(cancellationToken).ConfigureAwait(false);
        await LoadGroupsCoreAsync(cancellationToken).ConfigureAwait(false);
        await LoadSessionsCoreAsync(cancellationToken).ConfigureAwait(false);
        await LoadProfilesCoreAsync(cancellationToken).ConfigureAwait(false);
        await LoadPolicyCoreAsync(cancellationToken).ConfigureAwait(false);
        await LoadAutoLoginCoreAsync(cancellationToken).ConfigureAwait(false);
    }

    private async Task LoadAccountsCoreAsync(CancellationToken cancellationToken)
    {
        var result = await _service.GetLocalAccountsAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsSuccess)
        {
            RunOnUIThread(() =>
            {
                Accounts.Clear();
                foreach (var account in result.Value)
                {
                    Accounts.Add(account);
                }

                AccountCount = Accounts.Count;
            });
            StatusMessage = $"Loaded {Accounts.Count} account(s).";
        }
        else
        {
            SetErrorFromResult(result);
        }
    }

    private async Task LoadGroupsCoreAsync(CancellationToken cancellationToken)
    {
        var result = await _service.GetLocalGroupsAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsSuccess)
        {
            RunOnUIThread(() =>
            {
                Groups.Clear();
                foreach (var group in result.Value)
                {
                    Groups.Add(group);
                }
            });
        }
        else
        {
            SetErrorFromResult(result);
        }
    }

    private async Task LoadSessionsCoreAsync(CancellationToken cancellationToken)
    {
        var result = await _service.GetUserSessionsAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsSuccess)
        {
            RunOnUIThread(() =>
            {
                Sessions.Clear();
                foreach (var session in result.Value)
                {
                    Sessions.Add(session);
                }
            });
        }
        else
        {
            SetErrorFromResult(result);
        }
    }

    private async Task LoadProfilesCoreAsync(CancellationToken cancellationToken)
    {
        var result = await _service.GetUserProfilesAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsSuccess)
        {
            RunOnUIThread(() =>
            {
                Profiles.Clear();
                foreach (var profile in result.Value)
                {
                    Profiles.Add(profile);
                }
            });
        }
        else
        {
            SetErrorFromResult(result);
        }
    }

    private async Task LoadPolicyCoreAsync(CancellationToken cancellationToken)
    {
        var result = await _service.GetPasswordPolicyAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsSuccess)
        {
            PolicyMinLength = result.Value.MinLength;
            PolicyMaxAge = result.Value.MaxAgeDays;
            PolicyComplexity = result.Value.ComplexityEnabled;
            LockoutThreshold = result.Value.LockoutThreshold;
        }
        else
        {
            SetErrorFromResult(result);
        }
    }

    private async Task LoadAutoLoginCoreAsync(CancellationToken cancellationToken)
    {
        var result = await _service.GetAutoLoginAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsSuccess)
        {
            AutoLoginEnabled = result.Value.Enabled;
            AutoLoginUser = result.Value.Username ?? string.Empty;
        }
        else
        {
            SetErrorFromResult(result);
        }
    }

    private async Task LoadGroupMembersCoreAsync(string groupName, CancellationToken cancellationToken)
    {
        var result = await _service.GetGroupMembersAsync(groupName, cancellationToken).ConfigureAwait(false);
        if (result.IsSuccess)
        {
            RunOnUIThread(() =>
            {
                GroupMembers.Clear();
                foreach (var member in result.Value)
                {
                    GroupMembers.Add(member);
                }
            });
        }
        else
        {
            SetErrorFromResult(result);
        }
    }

    private async Task LoadAuditCoreAsync(CancellationToken cancellationToken)
    {
        var result = await _service.GetSecurityAuditAsync(100, cancellationToken).ConfigureAwait(false);
        if (result.IsSuccess)
        {
            RunOnUIThread(() =>
            {
                AuditEvents.Clear();
                foreach (var auditEvent in result.Value)
                {
                    AuditEvents.Add(auditEvent);
                }
            });
        }
        else
        {
            SetErrorFromResult(result);
        }
    }
}
