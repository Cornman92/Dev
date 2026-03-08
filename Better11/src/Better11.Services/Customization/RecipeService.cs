#pragma warning disable CS1591

using System.Text.Json;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Customization;

/// <summary>
/// Persists user recipes and generates built-in presets from the current catalog.
/// </summary>
public sealed class RecipeService : IRecipeService
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        WriteIndented = true,
    };

    private readonly ICustomizationCatalogService _catalogService;
    private readonly ILogger<RecipeService> _logger;
    private readonly string _recipesPath;

    public RecipeService(ICustomizationCatalogService catalogService, ILogger<RecipeService> logger)
    {
        _catalogService = catalogService ?? throw new ArgumentNullException(nameof(catalogService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));

        var dataDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Better11",
            "Customization");
        Directory.CreateDirectory(dataDirectory);
        _recipesPath = Path.Combine(dataDirectory, "saved-recipes.json");
    }

    public async Task<Result<IReadOnlyList<RecipeDto>>> GetBuiltInRecipesAsync(
        CancellationToken cancellationToken = default)
    {
        var catalogResult = await _catalogService.GetCatalogAsync(
            CustomizationTargetKind.LiveSystem,
            SafetyTier.Expert,
            cancellationToken).ConfigureAwait(false);
        if (catalogResult.IsFailure)
        {
            return Result<IReadOnlyList<RecipeDto>>.Failure(catalogResult.Error!);
        }

        var items = catalogResult.Value!
            .SelectMany(category => category.Items)
            .ToList();

        var recipes = new[]
        {
            CreateRecipe(
                "Gaming",
                "Performance-first baseline for desktop gaming and low-latency use.",
                SafetyTier.Advanced,
                items.Where(item =>
                    item.Tags.Contains("gaming", StringComparer.OrdinalIgnoreCase)
                    || item.Tags.Contains("performance", StringComparer.OrdinalIgnoreCase)
                    || string.Equals(item.CategoryTitle, "Startup Policy", StringComparison.OrdinalIgnoreCase))),
            CreateRecipe(
                "Developer",
                "Balanced productivity baseline for power users and developer workstations.",
                SafetyTier.Advanced,
                items.Where(item =>
                    item.Tags.Contains("developer", StringComparer.OrdinalIgnoreCase)
                    || item.SourceModule == "B11.Privacy"
                    || string.Equals(item.CategoryTitle, "Startup Policy", StringComparison.OrdinalIgnoreCase)
                    || string.Equals(item.CategoryTitle, "Task Policy", StringComparison.OrdinalIgnoreCase))),
            CreateRecipe(
                "Privacy",
                "Aggressive privacy and security baseline with stronger telemetry reduction.",
                SafetyTier.Expert,
                items.Where(item =>
                    item.Tags.Contains("privacy", StringComparer.OrdinalIgnoreCase)
                    || item.Tags.Contains("security", StringComparer.OrdinalIgnoreCase)
                    || item.SourceModule == "B11.Security")),
            CreateRecipe(
                "Balanced",
                "Recommended live-system baseline with broad improvements and moderate safety limits.",
                SafetyTier.Advanced,
                items.Where(item => item.Recommended && item.SafetyTier <= SafetyTier.Advanced)),
            CreateRecipe(
                "Minimal",
                "Small, safe baseline that limits changes to low-risk recommendations.",
                SafetyTier.Basic,
                items.Where(item => item.Recommended && item.SafetyTier == SafetyTier.Basic)),
        };

        return Result<IReadOnlyList<RecipeDto>>.Success(recipes);
    }

    public async Task<Result<IReadOnlyList<RecipeDto>>> GetSavedRecipesAsync(
        CancellationToken cancellationToken = default)
    {
        var recipes = await ReadRecipesAsync(cancellationToken).ConfigureAwait(false);
        return Result<IReadOnlyList<RecipeDto>>.Success(recipes);
    }

    public async Task<Result> SaveRecipeAsync(
        RecipeDto recipe,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(recipe);

        var recipes = (await ReadRecipesAsync(cancellationToken).ConfigureAwait(false)).ToList();
        var existingIndex = recipes.FindIndex(item => string.Equals(item.RecipeId, recipe.RecipeId, StringComparison.OrdinalIgnoreCase));
        if (existingIndex >= 0)
        {
            recipes[existingIndex] = recipe;
        }
        else
        {
            recipes.Add(recipe);
        }

        await PersistRecipesAsync(recipes, cancellationToken).ConfigureAwait(false);
        return Result.Success();
    }

    public async Task<Result<string>> ExportRecipeAsync(
        RecipeDto recipe,
        string outputPath,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(recipe);
        ArgumentException.ThrowIfNullOrWhiteSpace(outputPath);

        var directory = Path.GetDirectoryName(outputPath);
        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        await using var stream = File.Create(outputPath);
        await JsonSerializer.SerializeAsync(stream, recipe, SerializerOptions, cancellationToken).ConfigureAwait(false);

        return Result<string>.Success(outputPath);
    }

    public async Task<Result<RecipeDto>> ImportRecipeAsync(
        string inputPath,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(inputPath);

        if (!File.Exists(inputPath))
        {
            return Result<RecipeDto>.Failure($"Recipe file not found: {inputPath}");
        }

        await using var stream = File.OpenRead(inputPath);
        var recipe = await JsonSerializer.DeserializeAsync<RecipeDto>(
            stream,
            SerializerOptions,
            cancellationToken).ConfigureAwait(false);

        if (recipe is null || string.IsNullOrWhiteSpace(recipe.Name))
        {
            return Result<RecipeDto>.Failure("Recipe file is invalid.");
        }

        _logger.LogInformation("Imported customization recipe {RecipeName} from {Path}", recipe.Name, inputPath);
        return Result<RecipeDto>.Success(recipe);
    }

    private async Task<IReadOnlyList<RecipeDto>> ReadRecipesAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_recipesPath))
        {
            return Array.Empty<RecipeDto>();
        }

        await using var stream = File.OpenRead(_recipesPath);
        var recipes = await JsonSerializer.DeserializeAsync<List<RecipeDto>>(
            stream,
            SerializerOptions,
            cancellationToken).ConfigureAwait(false);

        return recipes is not null
            ? recipes
            : Array.Empty<RecipeDto>();
    }

    private async Task PersistRecipesAsync(IEnumerable<RecipeDto> recipes, CancellationToken cancellationToken)
    {
        await using var stream = File.Create(_recipesPath);
        await JsonSerializer.SerializeAsync(stream, recipes, SerializerOptions, cancellationToken).ConfigureAwait(false);
    }

    private static RecipeDto CreateRecipe(
        string name,
        string description,
        SafetyTier tier,
        IEnumerable<CatalogItemDto> selectedItems)
    {
        return new RecipeDto
        {
            Name = name,
            Description = description,
            Source = "BuiltIn",
            SafetyTier = tier,
            TargetKind = CustomizationTargetKind.LiveSystem,
            Tags = new[] { "builtin", name.ToLowerInvariant() },
            Items = selectedItems
                .DistinctBy(item => item.Id, StringComparer.OrdinalIgnoreCase)
                .OrderBy(item => item.Title, StringComparer.OrdinalIgnoreCase)
                .Select(item => new RecipeItemDto { ItemId = item.Id, Enabled = true })
                .ToList(),
        };
    }
}

#pragma warning restore CS1591
