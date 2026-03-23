# Better11 Development with Windsurf

**Last Updated:** 2026-03-01
**IDE Support:** Windsurf (Cursor-based development environment)

---

## Working with Claude Code

**Claude Code (claude.ai/code, model: claude-sonnet-4-6) is the lead architect.** When using Windsurf alongside Claude Code:

- **Read `CLAUDE.md` first** — authoritative source for all architecture, patterns, and conventions
- **Read `STYLE-GUIDE.md`** — for all UI/theme decisions
- **Read existing code before modifying** — understand patterns before changing anything
- **Do not refactor without asking** — the architecture is intentional
- **Do not add new dependencies** — stack is locked (CommunityToolkit.Mvvm, FluentAssertions, Moq, xUnit, Pester)
- **Keep changes minimal** — only what the task requires
- **Claude Code has final say** on architecture and design decisions

For workspace-wide scripts, MCP servers, and the dev-dashboard, see **D:\Dev\README.md** and **D:\Dev\CLAUDE.md**.

---

## Overview

Better11 is fully compatible with Windsurf, providing an enhanced development experience with AI-assisted coding, intelligent refactoring, and seamless project management.

---

## Windsurf Configuration

### Recommended Settings

Create `.windsurf/settings.json` in your Better11 workspace:

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.stylecop.analyzers": true,
    "source.organizeImports": true
  },
  "csharp.format.enable": true,
  "csharp.semanticHighlighting.enabled": true,
  "powershell.codeFormatting.autoCorrectAliases": true,
  "powershell.codeFormatting.preset": "Allman",
  "files.exclude": {
    "**/bin": true,
    "**/obj": true,
    "**/TestResults": true
  }
}
```

### Workspace Setup

1. **Open Better11 in Windsurf:**
   ```bash
   windsurf d:\Dev\Better11
   ```
   For the full Dev workspace (MCP servers, dashboard, scripts), open `d:\Dev` and see **D:\Dev\README.md** and **D:\Dev\docs\USER-GUIDE.md**.

2. **Install recommended extensions:**
   - C# Dev Kit
   - PowerShell
   - StyleCop Analyzers
   - XAML Tools
   - .NET Runtime Install Tool

---

## Development Workflow

### 1. Project Navigation

Windsurf provides intelligent project navigation:

```windsurf
# Navigate to key project areas
/src/Better11.App/          # WinUI 3 Application
/src/Better11.Core/         # Core abstractions and Result<T> pattern
/src/Better11.Services/     # PowerShell bridge services
/src/Better11.ViewModels/   # MVVM ViewModels
/PowerShell/Modules/        # PowerShell backend modules
/tests/                     # xUnit and Pester tests
```

### 2. AI-Assisted Development

Better11 leverages Windsurf's AI capabilities:

#### Code Generation
```csharp
// AI can generate new services following established patterns
public sealed class NewFeatureService : INewFeatureService
{
    private readonly IPowerShellService _ps;
    private readonly ILogger<NewFeatureService> _logger;
    
    public NewFeatureService(IPowerShellService ps, ILogger<NewFeatureService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }
    
    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<NewFeatureDto>>> GetFeaturesAsync(
        CancellationToken cancellationToken = default)
    {
        // AI generates consistent implementation
    }
}
```

#### PowerShell Module Generation
```powershell
# AI can generate new PowerShell functions following Better11 patterns
function Get-B11NewFeature {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$Filter = '*',
        
        [Parameter()]
        [switch]$IncludeDisabled
    )
    
    # Consistent error handling and logging
    try {
        $results = Invoke-B11Command -Module "Better11.NewFeature" -Function "Get-Features"
        return $results | Where-Object { $_.Name -like $Filter }
    }
    catch {
        Write-Error "Failed to retrieve new features: $_"
        return $null
    }
}
```

### 3. Intelligent Refactoring

Windsurf understands Better11's architecture:

#### MVVM Pattern Refactoring
```csharp
// Before: Manual property implementation
private string _title;
public string Title 
{ 
    get => _title; 
    set => SetProperty(ref _title, value); 
}

// After: AI-suggested CommunityToolkit.Mvvm
[ObservableProperty]
private string _title;
```

#### Service Pattern Refactoring
```csharp
// AI suggests consistent service patterns
public async Task<Result<IReadOnlyList<TDto>>> GetItemsAsync<TDto>(
    string module,
    string command,
    IDictionary<string, object>? parameters = null,
    CancellationToken cancellationToken = default)
{
    const string cacheKey = $"{module}_{command}";
    
    if (TryGetCached<IReadOnlyList<TDto>>(cacheKey, out var cached))
    {
        _logger.LogDebug("Returning cached {Module}.{Command}", module, command);
        return Result<IReadOnlyList<TDto>>.Success(cached);
    }
    
    _logger.LogInformation("Retrieving {Module}.{Command} via {Command}", module, command, command);
    
    try
    {
        var result = await _ps.InvokeCommandListAsync<TDto>(
            module, command, parameters, cancellationToken).ConfigureAwait(false);
            
        if (result.IsSuccess)
        {
            SetCache(cacheKey, result.Value);
        }
        
        return result;
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Failed to retrieve {Module}.{Command}", module, command);
        return Result<IReadOnlyList<TDto>>.Failure(ErrorCodes.PowerShell, ex.Message);
    }
}
```

---

## Testing with Windsurf

### 1. Test Generation

Windsurf can generate comprehensive tests:

```csharp
// AI-generated xUnit test
public class NewFeatureServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<NewFeatureService>> _mockLogger;
    private readonly NewFeatureService _service;

    public NewFeatureServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<NewFeatureService>>();
        _service = new NewFeatureService(_mockPs.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task GetFeaturesAsync_WhenSuccessful_ReturnsFeatures()
    {
        // Arrange
        var expectedFeatures = new List<NewFeatureDto>
        {
            new() { Name = "Feature1", Enabled = true },
            new() { Name = "Feature2", Enabled = false }
        };
        
        _mockPs.Setup(x => x.InvokeCommandListAsync<NewFeatureDto>(
            "Better11.NewFeature", "Get-Features", null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<List<NewFeatureDto>>.Success(expectedFeatures));

        // Act
        var result = await _service.GetFeaturesAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(2);
        result.Value.First().Name.Should().Be("Feature1");
    }
}
```

### 2. PowerShell Test Generation

```powershell
# AI-generated Pester test
Describe "Get-B11NewFeature" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\..\Better11.NewFeature.psd1"
    }
    
    Context "When retrieving features" {
        It "Should return all features when no filter specified" {
            $result = Get-B11NewFeature
            $result | Should -Not -Be $null
            $result | Should -BeOfType [PSCustomObject]
        }
        
        It "Should filter features when filter specified" {
            $result = Get-B11NewFeature -Filter "Test*"
            $result | Should -Not -Be $null
            $result.Name | Should -Match "^Test"
        }
    }
}
```

---

## Debugging with Windsurf

### 1. C# Debugging

Windsurf provides enhanced debugging for Better11:

```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Better11 App",
            "type": "coreclr",
            "request": "launch",
            "preLaunchTask": "build",
            "program": "${workspaceFolder}/Better11/src/Better11.App/bin/Debug/net8.0-windows10.0.22621.0/Better11.exe",
            "cwd": "${workspaceFolder}/Better11",
            "console": "internalConsole",
            "stopAtEntry": false
        },
        {
            "name": "Debug PowerShell Module",
            "type": "PowerShell",
            "request": "launch",
            "script": "${workspaceFolder}/PowerShell/Modules/Better11.NewFeature/Tests/Better11.NewFeature.Tests.ps1",
            "cwd": "${workspaceFolder}/PowerShell"
        }
    ]
}
```

### 2. PowerShell Debugging

```powershell
# Set breakpoints in PowerShell modules
function Get-B11NewFeature {
    [CmdletBinding()]
    param(...)
    
    # Windsurf can set breakpoints here
    Write-Debug "Entering Get-B11NewFeature function"
    
    try {
        # Debuggable code
        $results = Invoke-B11Command -Module "Better11.NewFeature" -Function "Get-Features"
        
        # Windsurf can inspect variables here
        Write-Debug "Retrieved $($results.Count) results"
        
        return $results
    }
    catch {
        # Exception debugging
        Write-Debug "Exception occurred: $($_.Exception.Message)"
        throw
    }
}
```

---

## Performance Optimization

### 1. AI-Assisted Performance Analysis

Windsurf can identify performance bottlenecks:

```csharp
// AI suggests caching improvements
public async Task<Result<IReadOnlyList<FeatureDto>>> GetFeaturesAsync()
{
    // Before: No caching
    var result = await _ps.InvokeCommandListAsync<FeatureDto>(
        "Better11.Features", "Get-Features", null, cancellationToken);
    
    // After: AI-suggested caching
    const string cacheKey = "Features";
    
    if (TryGetCached<IReadOnlyList<FeatureDto>>(cacheKey, out var cached))
    {
        return Result<IReadOnlyList<FeatureDto>>.Success(cached);
    }
    
    var result = await _ps.InvokeCommandListAsync<FeatureDto>(...);
    
    if (result.IsSuccess)
    {
        SetCache(cacheKey, result.Value, TimeSpan.FromMinutes(30));
    }
    
    return result;
}
```

### 2. Resource Management

```csharp
// AI suggests proper disposal patterns
public sealed class Better11Service : IDisposable
{
    private readonly SemaphoreSlim _semaphore = new(1, 1);
    private bool _disposed;

    public async Task<Result> ExecuteAsync()
    {
        if (_disposed) throw new ObjectDisposedException(nameof(Better11Service));
        
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            // Execute operation
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public void Dispose()
    {
        if (_disposed) return;
        
        _semaphore?.Dispose();
        _disposed = true;
    }
}
```

---

## Windsurf-Specific Features

### 1. Code Completion

Windsurf provides intelligent code completion for Better11:

```csharp
// AI understands Better11 patterns
public class NewService : INewService
{
    // AI suggests constructor pattern
    public NewService(IPowerShellService ps, ILogger<NewService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }
    
    // AI suggests Result<T> pattern
    public async Task<Result<IReadOnlyList<ItemDto>>> GetItemsAsync()
    {
        // AI suggests consistent error handling
        try
        {
            var result = await _ps.InvokeCommandListAsync<ItemDto>(...);
            return result.IsSuccess 
                ? Result<IReadOnlyList<ItemDto>>.Success(result.Value)
                : Result<IReadOnlyList<ItemDto>>.Failure(result.Error);
        }
        catch (Exception ex)
        {
            return Result<IReadOnlyList<ItemDto>>.Failure(ErrorCodes.Exception, ex.Message);
        }
    }
}
```

### 2. Documentation Generation

Windsurf can generate comprehensive documentation:

```xml
<!-- AI-generated XML documentation -->
<member name="M:Better11.Services.NewService.GetItemsAsync">
    <summary>
    Retrieves a collection of items from the Better11.NewFeature PowerShell module.
    Implements caching with a 30-minute TTL to improve performance.
    </summary>
    <param name="cancellationToken">Cancellation token for the operation.</param>
    <returns>
    A <see cref="Result{IReadOnlyList{ItemDto}}"/> containing the items if successful,
    or error information if the operation fails.
    </returns>
    <remarks>
    This method uses the <c>Get-B11Items</c> PowerShell command and caches results
    to reduce PowerShell invocation overhead. Cache is automatically invalidated
    after 30 minutes.
    </remarks>
    <example>
    <code>
    var service = serviceProvider.GetRequiredService<INewService>();
    var result = await service.GetItemsAsync();
    
    if (result.IsSuccess)
    {
        foreach (var item in result.Value)
        {
            Console.WriteLine($"Item: {item.Name}");
        }
    }
    </code>
    </example>
</member>
```

---

## Best Practices

### 1. Code Organization

```csharp
// AI suggests consistent file organization
namespace Better11.Services.NewFeature;

// File: NewFeatureService.cs
public sealed class NewFeatureService : INewFeatureService { }

// File: NewFeatureDto.cs  
public sealed record NewFeatureDto(string Name, bool Enabled);

// File: INewFeatureService.cs
public interface INewFeatureService
{
    Task<Result<IReadOnlyList<NewFeatureDto>>> GetFeaturesAsync();
}
```

### 2. Error Handling

```csharp
// AI enforces Result<T> pattern usage
public async Task<Result<T>> ExecuteOperationAsync<T>(string operation)
{
    try
    {
        var result = await _ps.InvokeCommandAsync<T>(...);
        
        return result.IsSuccess 
            ? Result<T>.Success(result.Value)
            : Result<T>.Failure(result.Error);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Operation {Operation} failed", operation);
        return Result<T>.Failure(ErrorCodes.Exception, ex.Message);
    }
}
```

---

## Conclusion

Windsurf provides an exceptional development experience for Better11 with:

- ✅ **AI-assisted coding** following established patterns
- ✅ **Intelligent refactoring** maintaining architectural consistency
- ✅ **Comprehensive testing** generation and execution
- ✅ **Advanced debugging** capabilities for both C# and PowerShell
- ✅ **Performance optimization** suggestions and analysis
- ✅ **Documentation generation** ensuring comprehensive coverage

**Better11 + Windsurf = Ultimate Windows System Enhancement Development Experience** 🚀
