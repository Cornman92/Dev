# Better11 System Enhancement Suite - Technology Stack

## Document Control

**Version**: 1.0  
**Last Updated**: January 2026  
**Owner**: Architecture Team

---

## Core Technologies

### Frontend Framework

#### WinUI 3 (Windows App SDK 1.5+)
**Version**: 1.5.0  
**Purpose**: Native Windows UI framework

**Justification**:
- Modern, fluent design system
- Native Windows 11 integration
- High performance rendering
- Excellent accessibility support
- Active Microsoft support

**Key Features Used**:
- NavigationView for app navigation
- CommandBar for toolbars
- DataGrid for tabular data
- TreeView for hierarchical data (Registry)
- ContentDialog for modal dialogs
- TeachingTip for user guidance
- Acrylic and Mica materials

**Packages**:
```xml
<PackageReference Include="Microsoft.WindowsAppSDK" Version="1.5.0" />
<PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="10.0.22621.0" />
<PackageReference Include="WinUIEx" Version="2.3.0" />
```

---

### Programming Language

#### C# 12
**Version**: C# 12 (.NET 8)  
**Purpose**: Primary development language

**Language Features Used**:
- Async/await for asynchronous operations
- LINQ for data querying
- Pattern matching
- Records for immutable data
- Primary constructors
- Collection expressions
- Nullable reference types

**Example**:
```csharp
public record Package(
    string Id,
    string Name,
    string Version,
    PackageSource Source
)
{
    public bool IsInstalled { get; init; }
}
```

---

### Runtime

#### .NET 8
**Version**: 8.0 LTS  
**Target**: net8.0-windows10.0.19041.0

**Justification**:
- Long-term support (LTS) release
- Performance improvements over .NET 6
- Enhanced ARM64 support
- Improved JIT compilation
- Self-contained deployment option

**Runtime Features**:
- Just-In-Time (JIT) compilation
- Garbage collection
- Cross-platform base class libraries
- Native interop (P/Invoke)

---

## MVVM Framework

### CommunityToolkit.MVVM
**Version**: 8.2.2  
**Purpose**: MVVM infrastructure

**Features Used**:
- `[ObservableProperty]` source generators
- `[RelayCommand]` for command binding
- `ObservableValidator` for validation
- Messenger for loosely-coupled communication
- `ObservableObject` base class

**Example**:
```csharp
[ObservableProperty]
private string _searchQuery;

[ObservableProperty]
private ObservableCollection<Package> _packages;

[RelayCommand]
private async Task SearchPackagesAsync()
{
    var results = await _packageService.SearchAsync(SearchQuery);
    Packages = new ObservableCollection<Package>(results);
}
```

**Packages**:
```xml
<PackageReference Include="CommunityToolkit.Mvvm" Version="8.2.2" />
```

---

## Dependency Injection

### Microsoft.Extensions.DependencyInjection
**Version**: 8.0.0  
**Purpose**: IoC container

**Configuration**:
```csharp
services.AddSingleton<INavigationService, NavigationService>();
services.AddTransient<IPackageService, PackageService>();
services.AddScoped<IDialogService, DialogService>();
```

**Lifetime Scopes**:
- **Singleton**: Single instance (services, configuration)
- **Transient**: New instance per request (ViewModels)
- **Scoped**: Not used (no web request scope)

**Packages**:
```xml
<PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.Configuration" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="8.0.0" />
```

---

## Backend Integration

### PowerShell
**Version**: PowerShell 7.4+ (preferred), 5.1 (minimum)  
**Purpose**: System-level operations requiring elevation

**PowerShell Modules Used**:
- **PackageManagement**: WinGet operations
- **PSWindowsUpdate**: Windows Update management
- **PnpDevice**: Hardware enumeration
- **Registry**: Registry operations
- **Service**: Service management

**Integration via System.Management.Automation**:
```xml
<PackageReference Include="Microsoft.PowerShell.SDK" Version="7.4.0" />
<PackageReference Include="System.Management.Automation" Version="7.4.0" />
```

**Example Integration**:
```csharp
using (var powerShell = PowerShell.Create())
{
    powerShell.AddScript(@"
        Get-WinGetPackage | 
        Where-Object { $_.Name -like '*$searchTerm*' } |
        Select-Object Id, Name, Version, Source
    ");
    
    var results = await powerShell.InvokeAsync();
    return results.Select(r => MapToPackage(r));
}
```

---

## Data Persistence

### SQLite
**Version**: 3.45.0  
**Purpose**: Local database storage

**ORM**: Entity Framework Core 8.0

**Justification**:
- Serverless, zero-configuration
- Cross-platform compatibility
- Excellent performance for local data
- ACID compliance
- Small footprint

**Packages**:
```xml
<PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="8.0.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.0" />
```

**DbContext Example**:
```csharp
public class Better11DbContext : DbContext
{
    public DbSet<Package> Packages { get; set; }
    public DbSet<Driver> Drivers { get; set; }
    public DbSet<RegistryBackup> RegistryBackups { get; set; }
    public DbSet<AuditLogEntry> AuditLog { get; set; }
    
    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        options.UseSqlite($"Data Source={DatabasePath}");
    }
}
```

---

### JSON Configuration
**Purpose**: Settings and configuration storage

**Library**: System.Text.Json (built-in)

**Features**:
- High performance
- Low allocation
- Source generation support
- Native .NET integration

**Example**:
```csharp
var options = new JsonSerializerOptions
{
    WriteIndented = true,
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
};

var json = JsonSerializer.Serialize(settings, options);
```

---

## Logging

### Serilog
**Version**: 3.1.1  
**Purpose**: Structured logging

**Sinks Used**:
- File (rolling logs)
- Console (development)
- Debug (development)
- Application Insights (optional telemetry)

**Packages**:
```xml
<PackageReference Include="Serilog" Version="3.1.1" />
<PackageReference Include="Serilog.Sinks.File" Version="5.0.0" />
<PackageReference Include="Serilog.Sinks.Console" Version="5.0.1" />
<PackageReference Include="Serilog.Enrichers.Environment" Version="2.3.0" />
<PackageReference Include="Serilog.Enrichers.Process" Version="2.0.2" />
```

**Configuration**:
```csharp
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithEnvironmentName()
    .Enrich.WithMachineName()
    .Enrich.WithProcessId()
    .WriteTo.File(
        path: "logs/better11-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}"
    )
    .CreateLogger();
```

---

## Testing

### Unit Testing

#### xUnit
**Version**: 2.6.0  
**Purpose**: Unit test framework

**Justification**:
- Modern, extensible framework
- Excellent async support
- Parallel test execution
- Strong community support

**Packages**:
```xml
<PackageReference Include="xunit" Version="2.6.0" />
<PackageReference Include="xunit.runner.visualstudio" Version="2.5.0" />
<PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.8.0" />
```

#### Moq
**Version**: 4.20.0  
**Purpose**: Mocking framework

**Example**:
```csharp
[Fact]
public async Task SearchPackages_ReturnsResults()
{
    // Arrange
    var mockService = new Mock<IPackageService>();
    mockService.Setup(s => s.SearchAsync(It.IsAny<string>()))
               .ReturnsAsync(new[] { new Package(...) });
    
    var viewModel = new PackageManagerViewModel(mockService.Object);
    
    // Act
    await viewModel.SearchPackagesCommand.ExecuteAsync("test");
    
    // Assert
    Assert.NotEmpty(viewModel.Packages);
}
```

**Packages**:
```xml
<PackageReference Include="Moq" Version="4.20.0" />
```

#### FluentAssertions
**Version**: 6.12.0  
**Purpose**: Assertion library

**Example**:
```csharp
result.Should().NotBeNull();
result.Should().HaveCount(5);
result.Should().Contain(p => p.Name == "TestPackage");
```

**Packages**:
```xml
<PackageReference Include="FluentAssertions" Version="6.12.0" />
```

---

### Code Coverage

#### Coverlet
**Version**: 6.0.0  
**Purpose**: Code coverage collection

**Packages**:
```xml
<PackageReference Include="coverlet.collector" Version="6.0.0" />
<PackageReference Include="coverlet.msbuild" Version="6.0.0" />
```

**Usage**:
```bash
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover
```

---

### UI Testing

#### WinAppDriver
**Version**: 1.2.1  
**Purpose**: UI automation testing

**Integration**: Appium + WinAppDriver for end-to-end tests

**Example**:
```csharp
var appiumOptions = new AppiumOptions();
appiumOptions.AddAdditionalCapability("app", "Better11.exe");
appiumOptions.AddAdditionalCapability("platformName", "Windows");

var driver = new WindowsDriver<WindowsElement>(
    new Uri("http://127.0.0.1:4723"),
    appiumOptions
);

var searchBox = driver.FindElementByAccessibilityId("SearchBox");
searchBox.SendKeys("test package");
```

---

## Code Quality

### Static Analysis

#### SonarAnalyzer
**Purpose**: Code quality and security analysis

**Packages**:
```xml
<PackageReference Include="SonarAnalyzer.CSharp" Version="9.12.0.78982" />
```

#### StyleCop.Analyzers
**Version**: 1.2.0-beta.556  
**Purpose**: Code style enforcement

**Packages**:
```xml
<PackageReference Include="StyleCop.Analyzers" Version="1.2.0-beta.556" />
```

**Configuration** (stylecop.json):
```json
{
  "$schema": "https://raw.githubusercontent.com/DotNetAnalyzers/StyleCopAnalyzers/master/StyleCop.Analyzers/StyleCop.Analyzers/Settings/stylecop.schema.json",
  "settings": {
    "documentationRules": {
      "companyName": "Better11 Team",
      "copyrightText": "Copyright (c) {companyName}. All rights reserved."
    }
  }
}
```

---

## Build & Deployment

### MSBuild
**Version**: 17.8.0  
**Purpose**: Build automation

**Key Targets**:
- Build
- Clean
- Rebuild
- Publish
- Pack (NuGet/MSIX)

### WiX Toolset
**Version**: 4.0  
**Purpose**: MSI installer creation

**Packages**:
```xml
<PackageReference Include="WixToolset.Sdk" Version="4.0.0" />
```

### MSIX Packaging
**Purpose**: Modern Windows app packaging

**Configuration**:
```xml
<PropertyGroup>
  <GenerateAppxPackageOnBuild>true</GenerateAppxPackageOnBuild>
  <AppxPackageSigningEnabled>true</AppxPackageSigningEnabled>
  <PackageCertificateKeyFile>Better11_TemporaryKey.pfx</PackageCertificateKeyFile>
</PropertyGroup>
```

---

## CI/CD

### GitHub Actions
**Purpose**: Continuous integration and deployment

**Workflows**:
- Build and test on every push
- Code quality analysis
- Security scanning
- Release builds
- Automated deployments

**Example Workflow**:
```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '8.0.x'
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --no-restore --configuration Release
    
    - name: Test
      run: dotnet test --no-build --configuration Release --collect:"XPlat Code Coverage"
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
```

---

## Performance Monitoring

### BenchmarkDotNet
**Version**: 0.13.10  
**Purpose**: Performance benchmarking

**Example**:
```csharp
[MemoryDiagnoser]
public class PackageSearchBenchmark
{
    private IPackageService _service;
    
    [Benchmark]
    public async Task SearchPackages()
    {
        await _service.SearchAsync("test");
    }
}
```

**Packages**:
```xml
<PackageReference Include="BenchmarkDotNet" Version="0.13.10" />
```

---

## Utilities

### Polly
**Version**: 8.2.0  
**Purpose**: Resilience and transient fault handling

**Policies Used**:
- Retry with exponential backoff
- Circuit breaker
- Timeout
- Fallback

**Example**:
```csharp
var retryPolicy = Policy
    .Handle<HttpRequestException>()
    .WaitAndRetryAsync(
        retryCount: 3,
        sleepDurationProvider: attempt => TimeSpan.FromSeconds(Math.Pow(2, attempt)),
        onRetry: (exception, timespan, retryCount, context) =>
        {
            _logger.LogWarning($"Retry {retryCount} after {timespan.TotalSeconds}s");
        }
    );

await retryPolicy.ExecuteAsync(() => _httpClient.GetAsync(url));
```

**Packages**:
```xml
<PackageReference Include="Polly" Version="8.2.0" />
```

---

### Humanizer
**Version**: 2.14.1  
**Purpose**: String and number humanization

**Example**:
```csharp
DateTime.UtcNow.AddHours(-2).Humanize() // "2 hours ago"
1024.Bytes().Humanize()                  // "1 KB"
TimeSpan.FromMinutes(5).Humanize()      // "5 minutes"
```

**Packages**:
```xml
<PackageReference Include="Humanizer.Core" Version="2.14.1" />
```

---

## Windows APIs

### Windows Runtime APIs (WinRT)
**Purpose**: Native Windows integration

**Key APIs Used**:
- Windows.Management.Deployment (Package management)
- Windows.Devices.Enumeration (Hardware detection)
- Windows.System (Process and app launching)
- Windows.Storage (File system operations)
- Windows.Security (Credential management)

**Example**:
```csharp
using Windows.Management.Deployment;

var packageManager = new PackageManager();
var packages = packageManager.FindPackages();
```

---

### Win32 APIs (via P/Invoke)
**Purpose**: Low-level Windows functionality

**Common APIs**:
- SetupAPI (Device installation)
- Advapi32 (Registry operations)
- Kernel32 (Process and memory management)
- User32 (Window management)

**Example**:
```csharp
[DllImport("kernel32.dll", SetLastError = true)]
static extern bool QueryFullProcessImageName(
    IntPtr hProcess,
    uint dwFlags,
    StringBuilder lpExeName,
    ref uint lpdwSize
);
```

---

## Package Managers Integration

### WinGet
**Integration**: PowerShell + WinGet CLI

**Commands Used**:
- `winget search`
- `winget install`
- `winget uninstall`
- `winget upgrade`
- `winget list`

### Chocolatey
**Integration**: PowerShell + Chocolatey CLI

**Commands Used**:
- `choco search`
- `choco install`
- `choco uninstall`
- `choco upgrade`
- `choco list`

### Scoop
**Integration**: PowerShell + Scoop CLI

**Commands Used**:
- `scoop search`
- `scoop install`
- `scoop uninstall`
- `scoop update`
- `scoop list`

---

## Development Tools

### IDEs
- **Visual Studio 2022** (17.8+): Primary IDE
- **Visual Studio Code**: Lightweight editing, PowerShell development
- **JetBrains Rider**: Alternative IDE option

### Extensions
- ReSharper (optional)
- CodeMaid
- Productivity Power Tools
- XAML Styler
- EditorConfig

### Package Management
- NuGet for .NET packages
- npm for build tooling (if needed)

---

## Documentation

### DocFX
**Version**: 2.75.0  
**Purpose**: API documentation generation

**Features**:
- Markdown support
- Code snippet extraction
- API reference generation
- Custom templates

**Packages**:
```xml
<PackageReference Include="docfx.console" Version="2.75.0" />
```

---

## Security

### Code Signing
**Tool**: SignTool (Windows SDK)  
**Certificate**: Code signing certificate from trusted CA

**Usage**:
```bash
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com Better11.exe
```

### Dependency Scanning
**Tools**:
- Dependabot (GitHub)
- Snyk
- OWASP Dependency-Check

---

## Summary Matrix

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **UI Framework** | WinUI 3 | 1.5.0 | User interface |
| **Language** | C# | 12 | Development |
| **Runtime** | .NET | 8.0 | Execution environment |
| **MVVM** | CommunityToolkit.MVVM | 8.2.2 | UI architecture |
| **DI** | Microsoft.Extensions.DI | 8.0.0 | Dependency injection |
| **Backend** | PowerShell | 7.4/5.1 | System operations |
| **Database** | SQLite | 3.45.0 | Data storage |
| **ORM** | Entity Framework Core | 8.0.0 | Data access |
| **Logging** | Serilog | 3.1.1 | Diagnostics |
| **Testing** | xUnit | 2.6.0 | Unit testing |
| **Mocking** | Moq | 4.20.0 | Test doubles |
| **Build** | MSBuild | 17.8.0 | Build automation |
| **Packaging** | MSIX/WiX | 4.0 | Deployment |
| **CI/CD** | GitHub Actions | - | Automation |

---

**Document Version**: 1.0  
**Last Updated**: January 2026  
**Next Review**: April 2026
