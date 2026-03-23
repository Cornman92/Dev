# Better11 Code Standards & Patterns

## Naming Conventions

### C# Naming

```csharp
// PascalCase for public members
public class PackageManager { }
public void InstallPackage() { }
public string PackageName { get; set; }

// camelCase for private fields with underscore prefix
private readonly IPackageService _packageService;
private int _retryCount;

// camelCase for parameters and local variables
public void ProcessPackage(string packageId, bool forceUpdate)
{
    var installer = new PackageInstaller();
}

// PascalCase for constants
public const int MaxRetryAttempts = 3;
private const string DefaultRegistry = "HKLM";

// I-prefix for interfaces
public interface IPackageRepository { }

// Async suffix for async methods
public async Task InstallPackageAsync() { }

// Meaningful, descriptive names
// GOOD: var installedPackages = await GetInstalledPackagesAsync();
// BAD:  var p = await GetAsync();
```

### XAML Naming

```xml
<!-- x:Name in PascalCase -->
<Button x:Name="InstallButton" Content="Install"/>
<ListView x:Name="PackageListView" ItemsSource="{Binding Packages}"/>

<!-- Resource keys in PascalCase -->
<SolidColorBrush x:Key="PrimaryAccentBrush" Color="#0078D4"/>
<Style x:Key="PrimaryButtonStyle" TargetType="Button"/>
```

### PowerShell Naming

```powershell
# PascalCase for functions with Verb-Noun pattern
function Get-InstalledPackage { }
function Install-Better11Package { }
function Optimize-SystemPerformance { }

# PascalCase for parameters
param(
    [string]$PackageName,
    [switch]$ForceUpdate
)

# camelCase for local variables
$packageCount = 0
$installedApps = @()

# UPPERCASE for environment variables
$env:BETTER11_CONFIG_PATH
```

### File Naming

```
ViewModels:     PackageManagerViewModel.cs
Views:          PackageManagerView.xaml
Services:       PackageService.cs
Interfaces:     IPackageService.cs
Models:         PackageInfo.cs
Repositories:   PackageRepository.cs
Tests:          PackageServiceTests.cs
PowerShell:     Better11.PackageManagement.psm1
```

## Code Organization

### File Structure

```csharp
// File: PackageService.cs

// 1. Using statements (grouped and sorted)
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Better11.Core.Models;
using Better11.Core.Repositories;
using Microsoft.Extensions.Logging;

// 2. Namespace
namespace Better11.Core.Services;

// 3. Class documentation
/// <summary>
/// Manages package operations across multiple package managers.
/// </summary>
public class PackageService : IPackageService
{
    // 4. Private fields
    private readonly IPackageRepository _repository;
    private readonly ILogger<PackageService> _logger;
    private readonly SemaphoreSlim _semaphore;

    // 5. Constructor
    public PackageService(
        IPackageRepository repository,
        ILogger<PackageService> logger)
    {
        _repository = repository ?? throw new ArgumentNullException(nameof(repository));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _semaphore = new SemaphoreSlim(1, 1);
    }

    // 6. Public methods
    public async Task<IEnumerable<PackageInfo>> SearchAsync(string query)
    {
        // Implementation
    }

    // 7. Private methods
    private async Task<bool> ValidatePackageAsync(PackageInfo package)
    {
        // Implementation
    }

    // 8. IDisposable implementation (if applicable)
    public void Dispose()
    {
        _semaphore?.Dispose();
    }
}
```

### Project Structure

```
Better11.Core/
├── Models/              # Data models and DTOs
├── Services/            # Business logic services
├── Repositories/        # Data access layer
├── Interfaces/          # Service contracts
├── Exceptions/          # Custom exceptions
├── Extensions/          # Extension methods
├── Utilities/           # Helper classes
└── Constants/           # Application constants

Better11.UI/
├── ViewModels/          # MVVM ViewModels
├── Views/               # XAML views
├── Controls/            # Custom controls
├── Converters/          # Value converters
├── Services/            # UI-specific services
├── Models/              # UI models
├── Resources/           # Resources and styles
└── Behaviors/           # Attached behaviors

Better11.PowerShell/
├── Public/              # Exported functions
├── Private/             # Internal functions
├── Classes/             # PowerShell classes
├── Formats/             # Format definitions
└── en-US/               # Help files
```

## MVVM Patterns

### ViewModel Patterns

```csharp
// Use partial classes with [ObservableProperty] attribute
public partial class PackageManagerViewModel : ViewModelBase
{
    private readonly IPackageService _packageService;

    // Auto-generated property with INPC
    [ObservableProperty]
    private string _searchQuery;

    // ObservableCollection for lists
    [ObservableProperty]
    private ObservableCollection<PackageInfo> _packages;

    // Selected item binding
    [ObservableProperty]
    private PackageInfo _selectedPackage;

    // Loading state
    [ObservableProperty]
    private bool _isLoading;

    // Constructor injection
    public PackageManagerViewModel(IPackageService packageService)
    {
        _packageService = packageService;
        _packages = new ObservableCollection<PackageInfo>();
    }

    // Commands with RelayCommand attribute
    [RelayCommand]
    private async Task SearchPackagesAsync()
    {
        IsLoading = true;
        try
        {
            var results = await _packageService.SearchAsync(SearchQuery);
            Packages.Clear();
            foreach (var package in results)
            {
                Packages.Add(package);
            }
        }
        finally
        {
            IsLoading = false;
        }
    }

    // Command with CanExecute
    [RelayCommand(CanExecute = nameof(CanInstall))]
    private async Task InstallAsync()
    {
        await _packageService.InstallAsync(SelectedPackage.Id);
    }

    private bool CanInstall() => SelectedPackage != null && !IsLoading;

    // Property change handler
    partial void OnSearchQueryChanged(string value)
    {
        SearchPackagesCommand.Execute(null);
    }
}
```

### View Binding Patterns

```xml
<!-- Two-way binding for input -->
<TextBox Text="{Binding SearchQuery, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"/>

<!-- One-way binding for display -->
<TextBlock Text="{Binding StatusMessage}"/>

<!-- Command binding -->
<Button Content="Search" Command="{Binding SearchPackagesCommand}"/>

<!-- Collection binding -->
<ListView ItemsSource="{Binding Packages}" 
          SelectedItem="{Binding SelectedPackage, Mode=TwoWay}"/>

<!-- Converter binding -->
<TextBlock Text="{Binding FileSize, Converter={StaticResource BytesToStringConverter}}"/>

<!-- Visibility binding -->
<ProgressRing IsActive="{Binding IsLoading}" 
              Visibility="{Binding IsLoading, Converter={StaticResource BoolToVisibilityConverter}}"/>
```

## Async/Await Patterns

### Correct Usage

```csharp
// GOOD: Async all the way
public async Task<IEnumerable<PackageInfo>> GetPackagesAsync()
{
    var packages = await _repository.GetAllAsync();
    return packages.Where(p => p.IsInstalled);
}

// GOOD: ConfigureAwait(false) in library code
public async Task ProcessPackageAsync(string packageId)
{
    var package = await _repository.GetByIdAsync(packageId).ConfigureAwait(false);
    await InstallAsync(package).ConfigureAwait(false);
}

// GOOD: Error handling
public async Task<Result<Package>> InstallPackageAsync(string packageId)
{
    try
    {
        var package = await _service.InstallAsync(packageId);
        return Result<Package>.Success(package);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Failed to install package {PackageId}", packageId);
        return Result<Package>.Failure(ex.Message);
    }
}

// GOOD: Cancellation token support
public async Task<IEnumerable<Package>> SearchAsync(string query, CancellationToken cancellationToken = default)
{
    return await _repository.SearchAsync(query, cancellationToken);
}

// GOOD: Progress reporting
public async Task<InstallResult> InstallAsync(string packageId, IProgress<int> progress = null)
{
    progress?.Report(0);
    var package = await DownloadAsync(packageId);
    progress?.Report(50);
    var result = await ExtractAsync(package);
    progress?.Report(100);
    return result;
}
```

### Anti-Patterns to Avoid

```csharp
// BAD: Blocking on async code
var result = SomeAsyncMethod().Result; // Deadlock risk!

// BAD: Async void (except event handlers)
public async void ProcessData() { } // Use async Task instead

// BAD: Unnecessary async/await
public async Task<string> GetNameAsync()
{
    return await _repository.GetNameAsync(); // Just return the task!
}

// GOOD: Return task directly
public Task<string> GetNameAsync() => _repository.GetNameAsync();

// BAD: Not awaiting in a loop
foreach (var item in items)
{
    ProcessAsync(item); // Fire and forget - don't do this!
}

// GOOD: Await in loop or use Task.WhenAll
foreach (var item in items)
{
    await ProcessAsync(item);
}

// OR for parallel execution:
var tasks = items.Select(item => ProcessAsync(item));
await Task.WhenAll(tasks);
```

## Error Handling

### Exception Hierarchy

```csharp
// Base application exception
public class Better11Exception : Exception
{
    public Better11Exception(string message) : base(message) { }
    public Better11Exception(string message, Exception innerException) 
        : base(message, innerException) { }
}

// Module-specific exceptions
public class PackageNotFoundException : Better11Exception
{
    public string PackageId { get; }
    
    public PackageNotFoundException(string packageId) 
        : base($"Package not found: {packageId}")
    {
        PackageId = packageId;
    }
}

public class InsufficientPermissionsException : Better11Exception
{
    public InsufficientPermissionsException(string operation)
        : base($"Insufficient permissions for operation: {operation}") { }
}
```

### Error Handling Pattern

```csharp
public async Task<Result<T>> ExecuteAsync<T>(Func<Task<T>> operation)
{
    try
    {
        var result = await operation();
        return Result<T>.Success(result);
    }
    catch (PackageNotFoundException ex)
    {
        _logger.LogWarning(ex, "Package not found");
        return Result<T>.Failure("The requested package could not be found.");
    }
    catch (InsufficientPermissionsException ex)
    {
        _logger.LogWarning(ex, "Insufficient permissions");
        return Result<T>.Failure("Administrator privileges required for this operation.");
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Unexpected error during operation");
        return Result<T>.Failure("An unexpected error occurred. Check logs for details.");
    }
}

// Result pattern
public class Result<T>
{
    public bool IsSuccess { get; }
    public T Value { get; }
    public string Error { get; }

    private Result(bool isSuccess, T value, string error)
    {
        IsSuccess = isSuccess;
        Value = value;
        Error = error;
    }

    public static Result<T> Success(T value) => new(true, value, null);
    public static Result<T> Failure(string error) => new(false, default, error);
}
```

## Logging Standards

```csharp
public class PackageService : IPackageService
{
    private readonly ILogger<PackageService> _logger;

    // Log levels:
    // Trace:    Very detailed, development only
    // Debug:    Diagnostic information, development/staging
    // Information: General flow, production
    // Warning:  Unexpected but recoverable
    // Error:    Operation failed
    // Critical: Application crash

    public async Task InstallAsync(string packageId)
    {
        _logger.LogInformation("Installing package {PackageId}", packageId);
        
        try
        {
            _logger.LogDebug("Downloading package {PackageId}", packageId);
            var package = await DownloadAsync(packageId);
            
            _logger.LogDebug("Extracting package {PackageId}", packageId);
            await ExtractAsync(package);
            
            _logger.LogInformation("Successfully installed package {PackageId}", packageId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to install package {PackageId}", packageId);
            throw;
        }
    }

    // Structured logging with properties
    public async Task ProcessBatchAsync(IEnumerable<string> packageIds)
    {
        using (_logger.BeginScope(new Dictionary<string, object>
        {
            ["BatchSize"] = packageIds.Count(),
            ["BatchId"] = Guid.NewGuid()
        }))
        {
            _logger.LogInformation("Processing batch of {Count} packages", packageIds.Count());
            // Processing...
        }
    }
}
```

## Testing Patterns

### Unit Test Structure

```csharp
public class PackageServiceTests
{
    private readonly Mock<IPackageRepository> _mockRepository;
    private readonly Mock<ILogger<PackageService>> _mockLogger;
    private readonly PackageService _service;

    public PackageServiceTests()
    {
        _mockRepository = new Mock<IPackageRepository>();
        _mockLogger = new Mock<ILogger<PackageService>>();
        _service = new PackageService(_mockRepository.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task SearchAsync_WithValidQuery_ReturnsPackages()
    {
        // Arrange
        var expectedPackages = new List<PackageInfo>
        {
            new PackageInfo { Id = "pkg1", Name = "Package 1" },
            new PackageInfo { Id = "pkg2", Name = "Package 2" }
        };
        
        _mockRepository
            .Setup(r => r.SearchAsync(It.IsAny<string>()))
            .ReturnsAsync(expectedPackages);

        // Act
        var result = await _service.SearchAsync("test");

        // Assert
        Assert.NotNull(result);
        Assert.Equal(2, result.Count());
        _mockRepository.Verify(r => r.SearchAsync("test"), Times.Once);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public async Task SearchAsync_WithInvalidQuery_ThrowsArgumentException(string query)
    {
        // Act & Assert
        await Assert.ThrowsAsync<ArgumentException>(() => _service.SearchAsync(query));
    }
}
```

### Integration Test Pattern

```csharp
public class PackageServiceIntegrationTests : IClassFixture<DatabaseFixture>
{
    private readonly DatabaseFixture _fixture;

    public PackageServiceIntegrationTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task FullWorkflow_InstallAndUninstall_Succeeds()
    {
        // Arrange
        using var context = _fixture.CreateContext();
        var repository = new PackageRepository(context);
        var service = new PackageService(repository, NullLogger<PackageService>.Instance);

        // Act
        var installResult = await service.InstallAsync("test-package");
        var installed = await repository.GetInstalledAsync();
        var uninstallResult = await service.UninstallAsync("test-package");

        // Assert
        Assert.True(installResult.IsSuccess);
        Assert.Contains(installed, p => p.Id == "test-package");
        Assert.True(uninstallResult.IsSuccess);
    }
}
```

## PowerShell Coding Standards

```powershell
# Function structure
function Get-Better11Package {
    <#
    .SYNOPSIS
        Retrieves package information from Better11 catalog.
    
    .DESCRIPTION
        Searches the Better11 package catalog and returns matching packages.
        Supports filtering by name, category, and installation status.
    
    .PARAMETER Name
        The name or partial name of the package to search for.
    
    .PARAMETER Category
        Filter results by category.
    
    .PARAMETER InstalledOnly
        Return only installed packages.
    
    .EXAMPLE
        Get-Better11Package -Name "Chrome"
        Searches for packages matching "Chrome".
    
    .EXAMPLE
        Get-Better11Package -Category "Browsers" -InstalledOnly
        Gets all installed browser packages.
    #>
    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Browsers', 'Development', 'Media', 'Utilities')]
        [string]$Category,
        
        [Parameter(Mandatory=$false)]
        [switch]$InstalledOnly
    )
    
    begin {
        Write-Verbose "Starting package search with parameters: Name=$Name, Category=$Category"
        $packages = @()
    }
    
    process {
        try {
            # Implementation
            $query = @{
                Name = $Name
                Category = $Category
                InstalledOnly = $InstalledOnly.IsPresent
            }
            
            $results = Invoke-PackageSearch @query
            $packages += $results
        }
        catch {
            Write-Error "Failed to search packages: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Found $($packages.Count) packages"
        return $packages
    }
}

# Error handling
try {
    $result = Get-SomeData
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found: $($_.Exception.Message)"
}
catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
    throw
}

# Use approved verbs
Get-*, Set-*, New-*, Remove-*, Install-*, Uninstall-*, Optimize-*, Test-*

# Parameter validation
param(
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    
    [ValidateRange(1, 100)]
    [int]$RetryCount,
    
    [ValidateSet('Low', 'Medium', 'High')]
    [string]$Priority
)
```

## Comments and Documentation

```csharp
// XML documentation for public APIs (required)
/// <summary>
/// Searches for packages matching the specified query.
/// </summary>
/// <param name="query">The search query string.</param>
/// <param name="source">The package source to search (default: All).</param>
/// <returns>A collection of matching packages.</returns>
/// <exception cref="ArgumentException">Thrown when query is null or empty.</exception>
public async Task<IEnumerable<PackageInfo>> SearchAsync(string query, PackageSource source = PackageSource.All)
{
    // Implementation comments for complex logic only
    // Don't comment obvious code:
    
    // BAD: Increment counter
    // counter++;
    
    // GOOD: Handle edge case where WinGet returns duplicate entries
    var uniquePackages = packages.DistinctBy(p => p.Id);
    
    // GOOD: Workaround for Chocolatey API rate limiting
    if (source == PackageSource.Chocolatey)
    {
        await Task.Delay(TimeSpan.FromSeconds(1));
    }
}

// TODO comments with issue tracking
// TODO(#123): Implement caching for search results
// FIXME: Race condition when multiple installs run simultaneously
// HACK: Temporary workaround until WinGet API is fixed
```

## Performance Guidelines

```csharp
// Use StringBuilder for string concatenation in loops
var builder = new StringBuilder();
foreach (var item in items)
{
    builder.AppendLine(item.ToString());
}
var result = builder.ToString();

// Use LINQ efficiently
// GOOD: Single enumeration
var filtered = items.Where(x => x.IsActive).ToList();

// BAD: Multiple enumerations
var count = items.Where(x => x.IsActive).Count();
var first = items.Where(x => x.IsActive).First();

// Dispose resources properly
using var connection = new SqlConnection(connectionString);
await connection.OpenAsync();
// Use connection

// Use object pooling for frequently allocated objects
private static readonly ObjectPool<StringBuilder> _stringBuilderPool = 
    ObjectPool.Create<StringBuilder>();

public string ProcessData(IEnumerable<string> data)
{
    var builder = _stringBuilderPool.Get();
    try
    {
        foreach (var item in data)
        {
            builder.AppendLine(item);
        }
        return builder.ToString();
    }
    finally
    {
        builder.Clear();
        _stringBuilderPool.Return(builder);
    }
}
```

## Security Guidelines

```csharp
// Never log sensitive information
// BAD
_logger.LogInformation("User password: {Password}", password);

// GOOD
_logger.LogInformation("User authenticated successfully");

// Validate all user input
public async Task<Result> InstallPackageAsync(string packageId)
{
    if (string.IsNullOrWhiteSpace(packageId))
        return Result.Failure("Package ID cannot be empty");
    
    if (!IsValidPackageId(packageId))
        return Result.Failure("Invalid package ID format");
    
    // Proceed with installation
}

// Use parameterized queries
// BAD
var query = $"SELECT * FROM Packages WHERE Name = '{packageName}'";

// GOOD
var query = "SELECT * FROM Packages WHERE Name = @PackageName";
command.Parameters.AddWithValue("@PackageName", packageName);

// Secure sensitive data
public class SecureConfigService
{
    public void StoreApiKey(string key)
    {
        var protectedData = ProtectedData.Protect(
            Encoding.UTF8.GetBytes(key),
            null,
            DataProtectionScope.CurrentUser);
        // Store protectedData
    }
}
```

---

**Last Updated**: December 2025
**Document Owner**: Development Standards Team
**Enforcement**: Automated via EditorConfig, analyzers, and code review
