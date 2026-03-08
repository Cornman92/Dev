#pragma warning disable CS1591

using System.Text.Json;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Customization;

/// <summary>
/// Builds and executes customization plans against existing Better11 services.
/// </summary>
public sealed class CustomizationExecutionService : ICustomizationExecutionService
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        WriteIndented = true,
    };

    private readonly ICustomizationCatalogService _catalogService;
    private readonly IOptimizationService _optimizationService;
    private readonly IPrivacyService _privacyService;
    private readonly ISecurityService _securityService;
    private readonly IStartupService _startupService;
    private readonly IScheduledTaskService _scheduledTaskService;
    private readonly ILogger<CustomizationExecutionService> _logger;
    private readonly SemaphoreSlim _executionLock = new(1, 1);
    private readonly string _rollbackJournalPath;

    public CustomizationExecutionService(
        ICustomizationCatalogService catalogService,
        IOptimizationService optimizationService,
        IPrivacyService privacyService,
        ISecurityService securityService,
        IStartupService startupService,
        IScheduledTaskService scheduledTaskService,
        ILogger<CustomizationExecutionService> logger)
    {
        _catalogService = catalogService ?? throw new ArgumentNullException(nameof(catalogService));
        _optimizationService = optimizationService ?? throw new ArgumentNullException(nameof(optimizationService));
        _privacyService = privacyService ?? throw new ArgumentNullException(nameof(privacyService));
        _securityService = securityService ?? throw new ArgumentNullException(nameof(securityService));
        _startupService = startupService ?? throw new ArgumentNullException(nameof(startupService));
        _scheduledTaskService = scheduledTaskService ?? throw new ArgumentNullException(nameof(scheduledTaskService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));

        var dataDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Better11",
            "Customization");
        Directory.CreateDirectory(dataDirectory);
        _rollbackJournalPath = Path.Combine(dataDirectory, "rollback-journal.json");
    }

    public async Task<Result<ExecutionPlanDto>> BuildExecutionPlanAsync(
        IReadOnlyList<string> itemIds,
        CustomizationTargetKind targetKind,
        SafetyTier maximumSafetyTier,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(itemIds);

        var catalogResult = await _catalogService.GetCatalogAsync(targetKind, maximumSafetyTier, cancellationToken)
            .ConfigureAwait(false);
        if (catalogResult.IsFailure)
        {
            return Result<ExecutionPlanDto>.Failure(catalogResult.Error!);
        }

        var resolutionResult = await _catalogService.ResolveSelectionAsync(itemIds, targetKind, maximumSafetyTier, cancellationToken)
            .ConfigureAwait(false);
        if (resolutionResult.IsFailure)
        {
            return Result<ExecutionPlanDto>.Failure(resolutionResult.Error!);
        }

        var itemsById = catalogResult.Value!
            .SelectMany(category => category.Items)
            .ToDictionary(item => item.Id, StringComparer.OrdinalIgnoreCase);

        var resolvedItems = resolutionResult.Value!.ExpandedItemIds
            .Where(itemsById.ContainsKey)
            .Select(itemId => itemsById[itemId])
            .ToList();

        return Result<ExecutionPlanDto>.Success(new ExecutionPlanDto
        {
            TargetKind = targetKind,
            SafetyTier = maximumSafetyTier,
            SelectedItemIds = itemIds.ToList(),
            ResolvedItems = resolvedItems,
            BlockedItems = resolutionResult.Value.BlockedItems,
            Warnings = resolutionResult.Value.Warnings,
            RequiresAdmin = resolvedItems.Any(item => item.RequiresAdmin),
            RequiresReboot = resolvedItems.Any(item => item.RequiresReboot),
            CanExecute = resolvedItems.Count > 0 && resolutionResult.Value.BlockedItems.Count == 0,
        });
    }

    public async Task<Result<ExecutionResultDto>> ExecutePlanAsync(
        ExecutionPlanDto plan,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(plan);

        if (!plan.CanExecute)
        {
            return Result<ExecutionResultDto>.Failure("The plan contains blocked items and cannot be executed.");
        }

        await _executionLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            string restorePointDescription = string.Empty;
            if (plan.TargetKind == CustomizationTargetKind.LiveSystem && plan.ResolvedItems.Count > 0)
            {
                restorePointDescription = $"Better11 Customization {DateTimeOffset.Now:yyyy-MM-dd HH:mm:ss}";
                var restorePointResult = await _optimizationService.CreateRestorePointAsync(
                    restorePointDescription,
                    cancellationToken).ConfigureAwait(false);
                if (restorePointResult.IsFailure)
                {
                    return Result<ExecutionResultDto>.Failure(restorePointResult.Error!);
                }
            }

            var optimizationTweakIds = new List<string>();
            var applied = new List<string>();
            var failures = new List<ExecutionFailureDto>();

            foreach (var item in plan.ResolvedItems)
            {
                if (string.Equals(item.SourceModule, "B11.Optimization", StringComparison.OrdinalIgnoreCase))
                {
                    if (item.Metadata.TryGetValue("OptimizationTweakId", out var tweakId))
                    {
                        optimizationTweakIds.Add(tweakId);
                    }

                    continue;
                }

                var itemResult = await ExecuteItemAsync(item, cancellationToken).ConfigureAwait(false);
                if (itemResult.IsSuccess)
                {
                    applied.Add(item.Id);
                }
                else
                {
                    failures.Add(new ExecutionFailureDto
                    {
                        ItemId = item.Id,
                        Title = item.Title,
                        Reason = itemResult.Error?.Message ?? "Execution failed.",
                    });
                }
            }

            if (optimizationTweakIds.Count > 0)
            {
                var optimizationResult = await _optimizationService.ApplyOptimizationsAsync(
                    optimizationTweakIds,
                    cancellationToken).ConfigureAwait(false);

                if (optimizationResult.IsSuccess)
                {
                    applied.AddRange(plan.ResolvedItems
                        .Where(item => string.Equals(item.SourceModule, "B11.Optimization", StringComparison.OrdinalIgnoreCase))
                        .Select(item => item.Id));
                }
                else
                {
                    failures.Add(new ExecutionFailureDto
                    {
                        ItemId = "optimization-batch",
                        Title = "Optimization batch",
                        Reason = optimizationResult.Error?.Message ?? "Optimization batch failed.",
                    });
                }
            }

            var skipped = plan.ResolvedItems
                .Select(item => item.Id)
                .Except(applied, StringComparer.OrdinalIgnoreCase)
                .ToList();

            var rollbackEntry = new RollbackEntryDto
            {
                Title = $"Customization plan {plan.PlanId}",
                Description = $"Applied {applied.Count} customization items.",
                ItemIds = applied,
                CanRollback = false,
                RestorePointDescription = restorePointDescription,
                Metadata = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["PlanId"] = plan.PlanId,
                    ["TargetKind"] = plan.TargetKind.ToString(),
                    ["SafetyTier"] = plan.SafetyTier.ToString(),
                },
            };

            await AppendRollbackEntryAsync(rollbackEntry, cancellationToken).ConfigureAwait(false);

            return Result<ExecutionResultDto>.Success(new ExecutionResultDto
            {
                PlanId = plan.PlanId,
                AppliedItemIds = applied,
                SkippedItemIds = skipped,
                Failures = failures,
                RebootRequired = plan.RequiresReboot,
                RollbackEntries = new[] { rollbackEntry },
                LogSummary = BuildSummary(applied.Count, failures.Count, restorePointDescription),
            });
        }
        catch (OperationCanceledException)
        {
            return Result<ExecutionResultDto>.Failure("Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Customization plan execution failed.");
            return Result<ExecutionResultDto>.Failure(ex);
        }
        finally
        {
            _executionLock.Release();
        }
    }

    public async Task<Result<IReadOnlyList<RollbackEntryDto>>> GetRollbackEntriesAsync(
        CancellationToken cancellationToken = default)
    {
        var entries = await ReadRollbackEntriesAsync(cancellationToken).ConfigureAwait(false);
        return Result<IReadOnlyList<RollbackEntryDto>>.Success(entries);
    }

    public async Task<Result> RollbackAsync(
        string rollbackEntryId,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(rollbackEntryId);

        var entries = await ReadRollbackEntriesAsync(cancellationToken).ConfigureAwait(false);
        var entry = entries.FirstOrDefault(item => string.Equals(item.Id, rollbackEntryId, StringComparison.OrdinalIgnoreCase));
        if (entry is null)
        {
            return Result.Failure("Rollback entry not found.");
        }

        if (!entry.CanRollback)
        {
            return Result.Failure(
                $"Rollback is not automated for this entry. Use the recorded restore point '{entry.RestorePointDescription}' if one exists.");
        }

        return Result.Failure("Direct rollback is not implemented for this entry.");
    }

    private async Task<Result> ExecuteItemAsync(CatalogItemDto item, CancellationToken cancellationToken)
    {
        if (!item.Metadata.TryGetValue("ActionKind", out var actionKind))
        {
            return Result.Failure($"Catalog item '{item.Title}' is missing execution metadata.");
        }

        return actionKind switch
        {
            "PrivacyProfile" => await _privacyService.ApplyPrivacyProfileAsync(
                item.Metadata["ProfileName"],
                cancellationToken).ConfigureAwait(false),
            "PrivacySetting" => await _privacyService.SetPrivacySettingAsync(
                item.Metadata["SettingId"],
                bool.Parse(item.Metadata["DesiredState"]),
                cancellationToken).ConfigureAwait(false),
            "SecurityHardening" => await _securityService.ApplyHardeningAsync(
                item.Metadata["ActionId"],
                cancellationToken).ConfigureAwait(false),
            "StartupToggle" => await ExecuteStartupToggleAsync(item, cancellationToken).ConfigureAwait(false),
            "ScheduledTaskToggle" => await ExecuteTaskToggleAsync(item, cancellationToken).ConfigureAwait(false),
            _ => Result.Failure($"Unsupported action kind '{actionKind}'."),
        };
    }

    private async Task<Result> ExecuteStartupToggleAsync(CatalogItemDto item, CancellationToken cancellationToken)
    {
        var action = item.Metadata["Action"];
        var itemId = item.Metadata["ItemId"];

        return string.Equals(action, "Enable", StringComparison.OrdinalIgnoreCase)
            ? await _startupService.EnableStartupItemAsync(itemId, cancellationToken).ConfigureAwait(false)
            : await _startupService.DisableStartupItemAsync(itemId, cancellationToken).ConfigureAwait(false);
    }

    private async Task<Result> ExecuteTaskToggleAsync(CatalogItemDto item, CancellationToken cancellationToken)
    {
        var action = item.Metadata["Action"];
        var taskPath = item.Metadata["TaskPath"];

        return string.Equals(action, "Enable", StringComparison.OrdinalIgnoreCase)
            ? await _scheduledTaskService.EnableTaskAsync(taskPath, cancellationToken).ConfigureAwait(false)
            : await _scheduledTaskService.DisableTaskAsync(taskPath, cancellationToken).ConfigureAwait(false);
    }

    private async Task AppendRollbackEntryAsync(RollbackEntryDto entry, CancellationToken cancellationToken)
    {
        var entries = (await ReadRollbackEntriesAsync(cancellationToken).ConfigureAwait(false)).ToList();
        entries.Add(entry);
        entries.Sort((left, right) => right.CreatedAtUtc.CompareTo(left.CreatedAtUtc));

        await using var stream = File.Create(_rollbackJournalPath);
        await JsonSerializer.SerializeAsync(stream, entries, SerializerOptions, cancellationToken).ConfigureAwait(false);
    }

    private async Task<IReadOnlyList<RollbackEntryDto>> ReadRollbackEntriesAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_rollbackJournalPath))
        {
            return Array.Empty<RollbackEntryDto>();
        }

        await using var stream = File.OpenRead(_rollbackJournalPath);
        var entries = await JsonSerializer.DeserializeAsync<List<RollbackEntryDto>>(
            stream,
            SerializerOptions,
            cancellationToken).ConfigureAwait(false);

        return entries is not null
            ? entries
            : Array.Empty<RollbackEntryDto>();
    }

    private static string BuildSummary(int appliedCount, int failedCount, string restorePointDescription)
    {
        var summary = $"Applied {appliedCount} items";
        if (failedCount > 0)
        {
            summary += $", {failedCount} failed";
        }

        if (!string.IsNullOrWhiteSpace(restorePointDescription))
        {
            summary += $". Restore point: {restorePointDescription}.";
        }

        return summary;
    }
}

#pragma warning restore CS1591
