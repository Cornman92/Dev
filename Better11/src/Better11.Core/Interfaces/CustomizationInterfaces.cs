using Better11.Core.Common;

namespace Better11.Core.Interfaces;

/// <summary>
/// Defines the supported customization safety levels.
/// </summary>
public enum SafetyTier
{
    Basic = 0,
    Advanced = 1,
    Expert = 2,
    Lab = 3,
}

/// <summary>
/// Defines the supported customization targets.
/// </summary>
public enum CustomizationTargetKind
{
    LiveSystem = 0,
    OfflineImage = 1,
}

/// <summary>
/// Describes a single catalog item exposed in the customization studio.
/// </summary>
public sealed class CatalogItemDto
{
    public string Id { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string CategoryKey { get; set; } = string.Empty;

    public string CategoryTitle { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string PreviewText { get; set; } = string.Empty;

    public string SourceModule { get; set; } = string.Empty;

    public CustomizationTargetKind TargetKind { get; set; } = CustomizationTargetKind.LiveSystem;

    public SafetyTier SafetyTier { get; set; } = SafetyTier.Basic;

    public string RiskLabel { get; set; } = "Low";

    public IReadOnlyList<string> DependencyIds { get; set; } = Array.Empty<string>();

    public IReadOnlyList<string> ConflictIds { get; set; } = Array.Empty<string>();

    public bool RequiresAdmin { get; set; }

    public bool RequiresReboot { get; set; }

    public bool IsReversible { get; set; }

    public bool Recommended { get; set; }

    public string EstimatedImpact { get; set; } = string.Empty;

    public IReadOnlyList<string> Tags { get; set; } = Array.Empty<string>();

    public IReadOnlyDictionary<string, string> Metadata { get; set; } =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
}

/// <summary>
/// Groups catalog items by category.
/// </summary>
public sealed class CatalogCategoryDto
{
    public string Key { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public int BasicCount { get; set; }

    public int AdvancedCount { get; set; }

    public int ExpertCount { get; set; }

    public int LabCount { get; set; }

    public IReadOnlyList<CatalogItemDto> Items { get; set; } = Array.Empty<CatalogItemDto>();
}

/// <summary>
/// Represents a blocked item in a resolved selection or plan.
/// </summary>
public sealed class BlockedCustomizationItemDto
{
    public string ItemId { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string Reason { get; set; } = string.Empty;
}

/// <summary>
/// Represents a resolved item selection after dependency and conflict checks.
/// </summary>
public sealed class CustomizationSelectionResolutionDto
{
    public IReadOnlyList<string> ExpandedItemIds { get; set; } = Array.Empty<string>();

    public IReadOnlyList<string> Warnings { get; set; } = Array.Empty<string>();

    public IReadOnlyList<BlockedCustomizationItemDto> BlockedItems { get; set; } =
        Array.Empty<BlockedCustomizationItemDto>();
}

/// <summary>
/// Represents an executable customization plan.
/// </summary>
public sealed class ExecutionPlanDto
{
    public string PlanId { get; set; } = Guid.NewGuid().ToString("N");

    public CustomizationTargetKind TargetKind { get; set; } = CustomizationTargetKind.LiveSystem;

    public SafetyTier SafetyTier { get; set; } = SafetyTier.Basic;

    public IReadOnlyList<string> SelectedItemIds { get; set; } = Array.Empty<string>();

    public IReadOnlyList<CatalogItemDto> ResolvedItems { get; set; } = Array.Empty<CatalogItemDto>();

    public IReadOnlyList<BlockedCustomizationItemDto> BlockedItems { get; set; } =
        Array.Empty<BlockedCustomizationItemDto>();

    public IReadOnlyList<string> Warnings { get; set; } = Array.Empty<string>();

    public bool RequiresAdmin { get; set; }

    public bool RequiresReboot { get; set; }

    public bool CanExecute { get; set; }
}

/// <summary>
/// Represents a single failure during execution.
/// </summary>
public sealed class ExecutionFailureDto
{
    public string ItemId { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string Reason { get; set; } = string.Empty;
}

/// <summary>
/// Represents a persisted rollback journal entry.
/// </summary>
public sealed class RollbackEntryDto
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");

    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public DateTimeOffset CreatedAtUtc { get; set; } = DateTimeOffset.UtcNow;

    public IReadOnlyList<string> ItemIds { get; set; } = Array.Empty<string>();

    public bool CanRollback { get; set; }

    public string RestorePointDescription { get; set; } = string.Empty;

    public IReadOnlyDictionary<string, string> Metadata { get; set; } =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
}

/// <summary>
/// Represents the result of a customization execution.
/// </summary>
public sealed class ExecutionResultDto
{
    public string PlanId { get; set; } = string.Empty;

    public IReadOnlyList<string> AppliedItemIds { get; set; } = Array.Empty<string>();

    public IReadOnlyList<string> SkippedItemIds { get; set; } = Array.Empty<string>();

    public IReadOnlyList<ExecutionFailureDto> Failures { get; set; } = Array.Empty<ExecutionFailureDto>();

    public bool RebootRequired { get; set; }

    public IReadOnlyList<RollbackEntryDto> RollbackEntries { get; set; } = Array.Empty<RollbackEntryDto>();

    public string LogSummary { get; set; } = string.Empty;
}

/// <summary>
/// Represents a single recipe item selection.
/// </summary>
public sealed class RecipeItemDto
{
    public string ItemId { get; set; } = string.Empty;

    public bool Enabled { get; set; } = true;

    public IReadOnlyDictionary<string, string> ParameterOverrides { get; set; } =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
}

/// <summary>
/// Represents a reusable customization recipe.
/// </summary>
public sealed class RecipeDto
{
    public string RecipeId { get; set; } = Guid.NewGuid().ToString("N");

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string Version { get; set; } = "1.0";

    public string Source { get; set; } = "User";

    public CustomizationTargetKind TargetKind { get; set; } = CustomizationTargetKind.LiveSystem;

    public SafetyTier SafetyTier { get; set; } = SafetyTier.Basic;

    public IReadOnlyList<RecipeItemDto> Items { get; set; } = Array.Empty<RecipeItemDto>();

    public IReadOnlyList<string> Tags { get; set; } = Array.Empty<string>();
}

/// <summary>
/// Represents a mounted offline image.
/// </summary>
public sealed class MountedImageDto
{
    public string ImagePath { get; set; } = string.Empty;

    public string MountPath { get; set; } = string.Empty;

    public int ImageIndex { get; set; }

    public string DisplayName { get; set; } = string.Empty;

    public bool IsMounted { get; set; }
}

/// <summary>
/// Defines customization catalog access.
/// </summary>
public interface ICustomizationCatalogService
{
    Task<Result<IReadOnlyList<CatalogCategoryDto>>> GetCatalogAsync(
        CustomizationTargetKind targetKind,
        SafetyTier maximumSafetyTier,
        CancellationToken cancellationToken = default);

    Task<Result<IReadOnlyList<CatalogItemDto>>> SearchCatalogAsync(
        string query,
        CustomizationTargetKind targetKind,
        SafetyTier maximumSafetyTier,
        CancellationToken cancellationToken = default);

    Task<Result<CustomizationSelectionResolutionDto>> ResolveSelectionAsync(
        IReadOnlyList<string> itemIds,
        CustomizationTargetKind targetKind,
        SafetyTier maximumSafetyTier,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Defines customization execution and rollback operations.
/// </summary>
public interface ICustomizationExecutionService
{
    Task<Result<ExecutionPlanDto>> BuildExecutionPlanAsync(
        IReadOnlyList<string> itemIds,
        CustomizationTargetKind targetKind,
        SafetyTier maximumSafetyTier,
        CancellationToken cancellationToken = default);

    Task<Result<ExecutionResultDto>> ExecutePlanAsync(
        ExecutionPlanDto plan,
        CancellationToken cancellationToken = default);

    Task<Result<IReadOnlyList<RollbackEntryDto>>> GetRollbackEntriesAsync(
        CancellationToken cancellationToken = default);

    Task<Result> RollbackAsync(
        string rollbackEntryId,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Defines recipe persistence and import/export operations.
/// </summary>
public interface IRecipeService
{
    Task<Result<IReadOnlyList<RecipeDto>>> GetBuiltInRecipesAsync(
        CancellationToken cancellationToken = default);

    Task<Result<IReadOnlyList<RecipeDto>>> GetSavedRecipesAsync(
        CancellationToken cancellationToken = default);

    Task<Result> SaveRecipeAsync(
        RecipeDto recipe,
        CancellationToken cancellationToken = default);

    Task<Result<string>> ExportRecipeAsync(
        RecipeDto recipe,
        string outputPath,
        CancellationToken cancellationToken = default);

    Task<Result<RecipeDto>> ImportRecipeAsync(
        string inputPath,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Defines offline image servicing operations for future phases.
/// </summary>
public interface IImageServicingService
{
    Task<Result<MountedImageDto>> MountImageAsync(
        string imagePath,
        string mountPath,
        int imageIndex,
        CancellationToken cancellationToken = default);

    Task<Result> UnmountImageAsync(
        string mountPath,
        bool saveChanges,
        CancellationToken cancellationToken = default);

    Task<Result<IReadOnlyList<MountedImageDto>>> GetMountedImagesAsync(
        CancellationToken cancellationToken = default);
}
