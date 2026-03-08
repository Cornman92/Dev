#pragma warning disable CS1591

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Customization;

/// <summary>
/// Aggregates live-system customization items from existing Better11 services.
/// </summary>
public sealed class CustomizationCatalogService : ICustomizationCatalogService
{
    private static readonly string[] TelemetryTaskKeywords =
    {
        "telemetry",
        "customer experience",
        "ceip",
        "feedback",
        "diagnostic",
        "compatibility",
    };

    private readonly IOptimizationService _optimizationService;
    private readonly IPrivacyService _privacyService;
    private readonly ISecurityService _securityService;
    private readonly IStartupService _startupService;
    private readonly IScheduledTaskService _scheduledTaskService;
    private readonly ILogger<CustomizationCatalogService> _logger;

    public CustomizationCatalogService(
        IOptimizationService optimizationService,
        IPrivacyService privacyService,
        ISecurityService securityService,
        IStartupService startupService,
        IScheduledTaskService scheduledTaskService,
        ILogger<CustomizationCatalogService> logger)
    {
        _optimizationService = optimizationService ?? throw new ArgumentNullException(nameof(optimizationService));
        _privacyService = privacyService ?? throw new ArgumentNullException(nameof(privacyService));
        _securityService = securityService ?? throw new ArgumentNullException(nameof(securityService));
        _startupService = startupService ?? throw new ArgumentNullException(nameof(startupService));
        _scheduledTaskService = scheduledTaskService ?? throw new ArgumentNullException(nameof(scheduledTaskService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<Result<IReadOnlyList<CatalogCategoryDto>>> GetCatalogAsync(
        CustomizationTargetKind targetKind,
        SafetyTier maximumSafetyTier,
        CancellationToken cancellationToken = default)
    {
        if (targetKind == CustomizationTargetKind.OfflineImage)
        {
            return Result<IReadOnlyList<CatalogCategoryDto>>.Success(new[]
            {
                CreateCategory(
                    "offline-image",
                    "Offline Image",
                    "Offline image servicing is scaffolded but not active in this wave.",
                    Array.Empty<CatalogItemDto>()),
            });
        }

        var allItems = new List<CatalogItemDto>();
        allItems.AddRange(await GetOptimizationItemsAsync(cancellationToken).ConfigureAwait(false));
        allItems.AddRange(await GetPrivacyItemsAsync(cancellationToken).ConfigureAwait(false));
        allItems.AddRange(await GetSecurityItemsAsync(cancellationToken).ConfigureAwait(false));
        allItems.AddRange(await GetStartupItemsAsync(cancellationToken).ConfigureAwait(false));
        allItems.AddRange(await GetScheduledTaskItemsAsync(cancellationToken).ConfigureAwait(false));

        var filteredItems = allItems
            .Where(item => item.TargetKind == targetKind && item.SafetyTier <= maximumSafetyTier)
            .OrderBy(item => item.CategoryTitle, StringComparer.OrdinalIgnoreCase)
            .ThenBy(item => item.Title, StringComparer.OrdinalIgnoreCase)
            .ToList();

        var categories = filteredItems
            .GroupBy(item => item.CategoryKey, StringComparer.OrdinalIgnoreCase)
            .Select(group => CreateCategory(
                group.Key,
                group.First().CategoryTitle,
                BuildCategoryDescription(group.First().CategoryTitle),
                group.ToList()))
            .OrderBy(category => category.Title, StringComparer.OrdinalIgnoreCase)
            .ToList();

        return Result<IReadOnlyList<CatalogCategoryDto>>.Success(categories);
    }

    public async Task<Result<IReadOnlyList<CatalogItemDto>>> SearchCatalogAsync(
        string query,
        CustomizationTargetKind targetKind,
        SafetyTier maximumSafetyTier,
        CancellationToken cancellationToken = default)
    {
        var catalogResult = await GetCatalogAsync(targetKind, maximumSafetyTier, cancellationToken)
            .ConfigureAwait(false);
        if (catalogResult.IsFailure)
        {
            return Result<IReadOnlyList<CatalogItemDto>>.Failure(catalogResult.Error!);
        }

        var items = catalogResult.Value!
            .SelectMany(category => category.Items)
            .ToList();

        if (string.IsNullOrWhiteSpace(query))
        {
            return Result<IReadOnlyList<CatalogItemDto>>.Success(items);
        }

        var normalized = query.Trim();
        var filtered = items
            .Where(item =>
                item.Title.Contains(normalized, StringComparison.OrdinalIgnoreCase)
                || item.Description.Contains(normalized, StringComparison.OrdinalIgnoreCase)
                || item.CategoryTitle.Contains(normalized, StringComparison.OrdinalIgnoreCase)
                || item.Tags.Any(tag => tag.Contains(normalized, StringComparison.OrdinalIgnoreCase)))
            .ToList();

        return Result<IReadOnlyList<CatalogItemDto>>.Success(filtered);
    }

    public async Task<Result<CustomizationSelectionResolutionDto>> ResolveSelectionAsync(
        IReadOnlyList<string> itemIds,
        CustomizationTargetKind targetKind,
        SafetyTier maximumSafetyTier,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(itemIds);

        var catalogResult = await GetCatalogAsync(targetKind, maximumSafetyTier, cancellationToken)
            .ConfigureAwait(false);
        if (catalogResult.IsFailure)
        {
            return Result<CustomizationSelectionResolutionDto>.Failure(catalogResult.Error!);
        }

        var itemsById = catalogResult.Value!
            .SelectMany(category => category.Items)
            .ToDictionary(item => item.Id, StringComparer.OrdinalIgnoreCase);

        var warnings = new List<string>();
        var blocked = new List<BlockedCustomizationItemDto>();
        var expanded = new List<string>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var itemId in itemIds.Where(id => !string.IsNullOrWhiteSpace(id)))
        {
            ResolveItem(itemId, itemsById, maximumSafetyTier, warnings, blocked, expanded, seen);
        }

        return Result<CustomizationSelectionResolutionDto>.Success(new CustomizationSelectionResolutionDto
        {
            ExpandedItemIds = expanded,
            Warnings = warnings,
            BlockedItems = blocked,
        });
    }

    private static string BuildCategoryDescription(string title) =>
        title switch
        {
            "Privacy Profiles" => "Prebuilt privacy baselines for quick application.",
            "Security Hardening" => "Security scan findings with concrete remediation actions.",
            "Startup Policy" => "Enabled startup items that can be disabled from the studio.",
            "Task Policy" => "Telemetry-oriented scheduled tasks that can be disabled.",
            _ => $"Live-system customization items for {title}.",
        };

    private static CatalogCategoryDto CreateCategory(
        string key,
        string title,
        string description,
        IReadOnlyList<CatalogItemDto> items)
    {
        return new CatalogCategoryDto
        {
            Key = key,
            Title = title,
            Description = description,
            BasicCount = items.Count(item => item.SafetyTier == SafetyTier.Basic),
            AdvancedCount = items.Count(item => item.SafetyTier == SafetyTier.Advanced),
            ExpertCount = items.Count(item => item.SafetyTier == SafetyTier.Expert),
            LabCount = items.Count(item => item.SafetyTier == SafetyTier.Lab),
            Items = items,
        };
    }

    private static void ResolveItem(
        string itemId,
        IReadOnlyDictionary<string, CatalogItemDto> itemsById,
        SafetyTier maximumSafetyTier,
        ICollection<string> warnings,
        ICollection<BlockedCustomizationItemDto> blocked,
        ICollection<string> expanded,
        ISet<string> seen)
    {
        if (!itemsById.TryGetValue(itemId, out var item))
        {
            blocked.Add(new BlockedCustomizationItemDto
            {
                ItemId = itemId,
                Title = itemId,
                Reason = "The item is not available in the current catalog.",
            });
            return;
        }

        if (seen.Contains(itemId))
        {
            return;
        }

        if (item.SafetyTier > maximumSafetyTier)
        {
            blocked.Add(new BlockedCustomizationItemDto
            {
                ItemId = item.Id,
                Title = item.Title,
                Reason = $"Requires {item.SafetyTier} safety tier.",
            });
            return;
        }

        seen.Add(itemId);

        foreach (var dependencyId in item.DependencyIds)
        {
            ResolveItem(dependencyId, itemsById, maximumSafetyTier, warnings, blocked, expanded, seen);
        }

        var conflict = item.ConflictIds.FirstOrDefault(conflictId => expanded.Contains(conflictId, StringComparer.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(conflict))
        {
            blocked.Add(new BlockedCustomizationItemDto
            {
                ItemId = item.Id,
                Title = item.Title,
                Reason = $"Conflicts with {conflict}.",
            });
            return;
        }

        if (item.SafetyTier >= SafetyTier.Expert)
        {
            warnings.Add($"{item.Title} is an {item.SafetyTier} action.");
        }

        if (item.RequiresReboot)
        {
            warnings.Add($"{item.Title} may require a reboot.");
        }

        expanded.Add(item.Id);
    }

    private async Task<IReadOnlyList<CatalogItemDto>> GetOptimizationItemsAsync(CancellationToken cancellationToken)
    {
        var result = await _optimizationService.GetCategoriesAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsFailure || result.Value is null)
        {
            _logger.LogWarning("Optimization catalog load failed: {Message}", result.Error?.Message);
            return Array.Empty<CatalogItemDto>();
        }

        return result.Value
            .SelectMany(category => category.Tweaks.Select(tweak => CreateOptimizationItem(category, tweak)))
            .ToList();
    }

    private async Task<IReadOnlyList<CatalogItemDto>> GetPrivacyItemsAsync(CancellationToken cancellationToken)
    {
        var result = await _privacyService.GetPrivacyAuditAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsFailure || result.Value is null)
        {
            _logger.LogWarning("Privacy catalog load failed: {Message}", result.Error?.Message);
            return CreatePrivacyProfileItems();
        }

        var items = new List<CatalogItemDto>();
        items.AddRange(CreatePrivacyProfileItems());
        items.AddRange(result.Value.Settings.Select(CreatePrivacySettingItem));
        return items;
    }

    private async Task<IReadOnlyList<CatalogItemDto>> GetSecurityItemsAsync(CancellationToken cancellationToken)
    {
        var result = await _securityService.RunSecurityScanAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsFailure || result.Value is null)
        {
            _logger.LogWarning("Security catalog load failed: {Message}", result.Error?.Message);
            return Array.Empty<CatalogItemDto>();
        }

        return result.Value.Issues
            .Where(issue => !string.IsNullOrWhiteSpace(issue.RemediationActionId))
            .Select(CreateSecurityItem)
            .ToList();
    }

    private async Task<IReadOnlyList<CatalogItemDto>> GetStartupItemsAsync(CancellationToken cancellationToken)
    {
        var result = await _startupService.GetStartupItemsAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsFailure || result.Value is null)
        {
            _logger.LogWarning("Startup catalog load failed: {Message}", result.Error?.Message);
            return Array.Empty<CatalogItemDto>();
        }

        return result.Value
            .Where(item => item.IsEnabled)
            .Select(CreateStartupItem)
            .ToList();
    }

    private async Task<IReadOnlyList<CatalogItemDto>> GetScheduledTaskItemsAsync(CancellationToken cancellationToken)
    {
        var result = await _scheduledTaskService.GetScheduledTasksAsync(cancellationToken).ConfigureAwait(false);
        if (result.IsFailure || result.Value is null)
        {
            _logger.LogWarning("Scheduled task catalog load failed: {Message}", result.Error?.Message);
            return Array.Empty<CatalogItemDto>();
        }

        return result.Value
            .Where(IsRecommendedTelemetryTask)
            .Select(CreateScheduledTaskItem)
            .ToList();
    }

    private static CatalogItemDto CreateOptimizationItem(OptimizationCategoryDto category, TweakDto tweak)
    {
        var tags = BuildTags(category.Name, tweak.Name, tweak.Description);
        return new CatalogItemDto
        {
            Id = $"optimization:{tweak.Id}",
            Title = tweak.Name,
            CategoryKey = $"optimization-{Slugify(category.Name)}",
            CategoryTitle = category.Name,
            Description = tweak.Description,
            PreviewText = $"Apply optimization tweak '{tweak.Name}'.",
            SourceModule = AppConstants.Modules.Optimization,
            TargetKind = CustomizationTargetKind.LiveSystem,
            SafetyTier = MapRiskToTier(tweak.RiskLevel),
            RiskLabel = tweak.RiskLevel,
            RequiresAdmin = true,
            RequiresReboot = false,
            IsReversible = false,
            Recommended = !tweak.IsApplied && MapRiskToTier(tweak.RiskLevel) <= SafetyTier.Advanced,
            EstimatedImpact = category.Name.Contains("Performance", StringComparison.OrdinalIgnoreCase)
                ? "Performance and responsiveness changes."
                : "System behavior changes.",
            Tags = tags,
            Metadata = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["ActionKind"] = "OptimizationTweak",
                ["OptimizationTweakId"] = tweak.Id,
            },
        };
    }

    private static CatalogItemDto[] CreatePrivacyProfileItems()
    {
        return new[]
        {
            CreatePrivacyProfileItem("Balanced", SafetyTier.Basic, "Recommended privacy baseline for general daily use."),
            CreatePrivacyProfileItem("Strict", SafetyTier.Advanced, "Stronger privacy posture with more aggressive defaults."),
            CreatePrivacyProfileItem("Maximum", SafetyTier.Expert, "Maximum privacy posture with broader data collection restrictions."),
        };
    }

    private static CatalogItemDto CreatePrivacyProfileItem(string profileName, SafetyTier tier, string description)
    {
        return new CatalogItemDto
        {
            Id = $"privacy:profile:{profileName}",
            Title = $"Apply Privacy Profile: {profileName}",
            CategoryKey = "privacy-profiles",
            CategoryTitle = "Privacy Profiles",
            Description = description,
            PreviewText = $"Apply the '{profileName}' privacy profile.",
            SourceModule = AppConstants.Modules.Privacy,
            TargetKind = CustomizationTargetKind.LiveSystem,
            SafetyTier = tier,
            RiskLabel = tier.ToString(),
            RequiresAdmin = true,
            RequiresReboot = false,
            IsReversible = false,
            Recommended = string.Equals(profileName, "Balanced", StringComparison.OrdinalIgnoreCase),
            EstimatedImpact = "Multiple privacy settings will be changed together.",
            Tags = new[] { "privacy", "profile", profileName.ToLowerInvariant(), "recommended" },
            Metadata = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["ActionKind"] = "PrivacyProfile",
                ["ProfileName"] = profileName,
            },
        };
    }

    private static CatalogItemDto CreatePrivacySettingItem(PrivacySettingDto setting)
    {
        var tags = BuildTags("Privacy", setting.Name, setting.Description);
        return new CatalogItemDto
        {
            Id = $"privacy:setting:{setting.Id}",
            Title = setting.Name,
            CategoryKey = $"privacy-{Slugify(setting.Category)}",
            CategoryTitle = string.IsNullOrWhiteSpace(setting.Category) ? "Privacy" : setting.Category,
            Description = setting.Description,
            PreviewText = $"Set '{setting.Name}' to {(!setting.IsEnabled ? "enabled" : "disabled")} for stronger privacy.",
            SourceModule = AppConstants.Modules.Privacy,
            TargetKind = CustomizationTargetKind.LiveSystem,
            SafetyTier = setting.Category.Contains("Advertising", StringComparison.OrdinalIgnoreCase)
                ? SafetyTier.Basic
                : SafetyTier.Advanced,
            RiskLabel = setting.RecommendedState == !setting.IsEnabled ? "Low" : "Medium",
            RequiresAdmin = true,
            RequiresReboot = false,
            IsReversible = true,
            Recommended = setting.RecommendedState == !setting.IsEnabled,
            EstimatedImpact = "Adjusts a specific privacy control.",
            Tags = tags,
            Metadata = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["ActionKind"] = "PrivacySetting",
                ["SettingId"] = setting.Id,
                ["DesiredState"] = (!setting.IsEnabled).ToString(),
                ["CurrentState"] = setting.IsEnabled.ToString(),
            },
        };
    }

    private static CatalogItemDto CreateSecurityItem(SecurityIssueDto issue)
    {
        var tags = BuildTags("Security", issue.Title, issue.Description);
        return new CatalogItemDto
        {
            Id = $"security:hardening:{issue.RemediationActionId}",
            Title = issue.Title,
            CategoryKey = "security-hardening",
            CategoryTitle = "Security Hardening",
            Description = issue.Description,
            PreviewText = $"Apply remediation '{issue.RemediationActionId}' for {issue.Title}.",
            SourceModule = AppConstants.Modules.Security,
            TargetKind = CustomizationTargetKind.LiveSystem,
            SafetyTier = MapSeverityToTier(issue.Severity),
            RiskLabel = issue.Severity,
            RequiresAdmin = true,
            RequiresReboot = false,
            IsReversible = false,
            Recommended = !string.Equals(issue.Severity, "Low", StringComparison.OrdinalIgnoreCase),
            EstimatedImpact = "Changes a security baseline or hardening policy.",
            Tags = tags,
            Metadata = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["ActionKind"] = "SecurityHardening",
                ["ActionId"] = issue.RemediationActionId,
            },
        };
    }

    private static CatalogItemDto CreateStartupItem(StartupItemDto item)
    {
        var tags = BuildTags("Startup", item.Name, item.Command);
        return new CatalogItemDto
        {
            Id = $"startup:disable:{item.Id}",
            Title = $"Disable startup item: {item.Name}",
            CategoryKey = "startup-policy",
            CategoryTitle = "Startup Policy",
            Description = $"Disable '{item.Name}' from {item.Location}.",
            PreviewText = $"Disable startup item '{item.Name}' ({item.Command}).",
            SourceModule = AppConstants.Modules.Startup,
            TargetKind = CustomizationTargetKind.LiveSystem,
            SafetyTier = MapStartupImpactToTier(item.Impact),
            RiskLabel = item.Impact,
            RequiresAdmin = true,
            RequiresReboot = false,
            IsReversible = true,
            Recommended = item.Impact.Equals("High", StringComparison.OrdinalIgnoreCase)
                || item.Impact.Equals("Medium", StringComparison.OrdinalIgnoreCase),
            EstimatedImpact = "Reduces background work during sign-in.",
            Tags = tags,
            Metadata = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["ActionKind"] = "StartupToggle",
                ["Action"] = "Disable",
                ["ItemId"] = item.Id,
            },
        };
    }

    private static CatalogItemDto CreateScheduledTaskItem(ScheduledTaskDto task)
    {
        var tags = BuildTags("Tasks", task.TaskName, task.Description);
        return new CatalogItemDto
        {
            Id = $"task:disable:{task.TaskPath}",
            Title = $"Disable scheduled task: {task.TaskName}",
            CategoryKey = "task-policy",
            CategoryTitle = "Task Policy",
            Description = string.IsNullOrWhiteSpace(task.Description)
                ? $"Disable scheduled task '{task.TaskName}'."
                : task.Description,
            PreviewText = $"Disable scheduled task '{task.TaskPath}'.",
            SourceModule = AppConstants.Modules.Tasks,
            TargetKind = CustomizationTargetKind.LiveSystem,
            SafetyTier = SafetyTier.Advanced,
            RiskLabel = "Medium",
            RequiresAdmin = true,
            RequiresReboot = false,
            IsReversible = true,
            Recommended = true,
            EstimatedImpact = "Reduces background telemetry and scheduled maintenance noise.",
            Tags = tags,
            Metadata = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["ActionKind"] = "ScheduledTaskToggle",
                ["Action"] = "Disable",
                ["TaskPath"] = task.TaskPath,
            },
        };
    }

    private static bool IsRecommendedTelemetryTask(ScheduledTaskDto task)
    {
        if (!string.Equals(task.State, "Ready", StringComparison.OrdinalIgnoreCase)
            && !string.Equals(task.State, "Running", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return TelemetryTaskKeywords.Any(keyword =>
            task.TaskName.Contains(keyword, StringComparison.OrdinalIgnoreCase)
            || task.TaskPath.Contains(keyword, StringComparison.OrdinalIgnoreCase)
            || task.Description.Contains(keyword, StringComparison.OrdinalIgnoreCase));
    }

    private static string[] BuildTags(params string[] values)
    {
        var tags = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var value in values.Where(v => !string.IsNullOrWhiteSpace(v)))
        {
            var normalized = value.ToLowerInvariant();
            if (normalized.Contains("game") || normalized.Contains("gpu") || normalized.Contains("latency"))
            {
                tags.Add("gaming");
            }

            if (normalized.Contains("privacy") || normalized.Contains("telemetry") || normalized.Contains("tracking"))
            {
                tags.Add("privacy");
            }

            if (normalized.Contains("security") || normalized.Contains("firewall") || normalized.Contains("uac"))
            {
                tags.Add("security");
            }

            if (normalized.Contains("startup") || normalized.Contains("task"))
            {
                tags.Add("maintenance");
            }

            if (normalized.Contains("performance") || normalized.Contains("cpu") || normalized.Contains("memory"))
            {
                tags.Add("performance");
            }

            if (normalized.Contains("dev") || normalized.Contains("powershell") || normalized.Contains("wsl"))
            {
                tags.Add("developer");
            }
        }

        return tags.Count == 0
            ? Array.Empty<string>()
            : tags.OrderBy(tag => tag, StringComparer.OrdinalIgnoreCase).ToArray();
    }

    private static SafetyTier MapRiskToTier(string? riskLevel)
    {
        if (string.IsNullOrWhiteSpace(riskLevel))
        {
            return SafetyTier.Basic;
        }

        return riskLevel.Trim().ToLowerInvariant() switch
        {
            "critical" => SafetyTier.Lab,
            "high" => SafetyTier.Expert,
            "medium" => SafetyTier.Advanced,
            _ => SafetyTier.Basic,
        };
    }

    private static SafetyTier MapSeverityToTier(string? severity)
    {
        if (string.IsNullOrWhiteSpace(severity))
        {
            return SafetyTier.Advanced;
        }

        return severity.Trim().ToLowerInvariant() switch
        {
            "critical" => SafetyTier.Lab,
            "high" => SafetyTier.Expert,
            "medium" => SafetyTier.Advanced,
            _ => SafetyTier.Basic,
        };
    }

    private static SafetyTier MapStartupImpactToTier(string? impact)
    {
        if (string.IsNullOrWhiteSpace(impact))
        {
            return SafetyTier.Basic;
        }

        return impact.Trim().ToLowerInvariant() switch
        {
            "high" => SafetyTier.Advanced,
            _ => SafetyTier.Basic,
        };
    }

    private static string Slugify(string value)
    {
        var chars = value
            .Trim()
            .ToLowerInvariant()
            .Select(ch => char.IsLetterOrDigit(ch) ? ch : '-')
            .ToArray();
        return new string(chars).Replace("--", "-", StringComparison.Ordinal);
    }
}

#pragma warning restore CS1591
