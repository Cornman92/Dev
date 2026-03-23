---
description: Develop .NET applications following Better11-style architecture patterns
---

# .NET Application Development Workflow

Complete workflow for developing .NET applications using the layered architecture pattern established in the Better11 project.

## Prerequisites
- .NET 8.0+ SDK installed
- Visual Studio 2022 or VS Code with C# extension
- Git for version control

## Steps

### 1. Create Solution Structure
// turbo
```powershell
$projectName = "[ProjectName]"
$projectPath = "e:\OneDrive\Dev\active-projects\$projectName"

# Create solution
dotnet new sln -n $projectName -o $projectPath

# Create projects following Better11 pattern
dotnet new classlib -n "$projectName.Core" -o "$projectPath\$projectName.Core"
dotnet new classlib -n "$projectName.Infrastructure" -o "$projectPath\$projectName.Infrastructure"
dotnet new classlib -n "$projectName.Models" -o "$projectPath\$projectName.Models"
dotnet new classlib -n "$projectName.ViewModels" -o "$projectPath\$projectName.ViewModels"
dotnet new wpf -n "$projectName.App" -o "$projectPath\$projectName.App"

# Add projects to solution
Set-Location $projectPath
dotnet sln add "$projectName.Core"
dotnet sln add "$projectName.Infrastructure"
dotnet sln add "$projectName.Models"
dotnet sln add "$projectName.ViewModels"
dotnet sln add "$projectName.App"
```

### 2. Configure Project References
```powershell
# Core depends on Models
dotnet add "$projectName.Core" reference "$projectName.Models"

# Infrastructure depends on Core
dotnet add "$projectName.Infrastructure" reference "$projectName.Core"

# ViewModels depends on Core and Models
dotnet add "$projectName.ViewModels" reference "$projectName.Core"
dotnet add "$projectName.ViewModels" reference "$projectName.Models"

# App depends on all
dotnet add "$projectName.App" reference "$projectName.Core"
dotnet add "$projectName.App" reference "$projectName.Infrastructure"
dotnet add "$projectName.App" reference "$projectName.ViewModels"
```

### 3. Create Standard Files
Create `.editorconfig` for consistent formatting:
```ini
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = crlf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.cs]
dotnet_sort_system_directives_first = true
csharp_new_line_before_open_brace = all
```

Create `.gitignore`:
```
bin/
obj/
.vs/
*.user
*.suo
packages/
```

### 4. Set Up Dependency Injection
In `App.xaml.cs`:
```csharp
public partial class App : Application
{
    public IServiceProvider Services { get; }
    
    public App()
    {
        Services = ConfigureServices();
    }
    
    private static IServiceProvider ConfigureServices()
    {
        var services = new ServiceCollection();
        
        // Register services
        services.AddSingleton<IConfigurationService, ConfigurationService>();
        services.AddTransient<MainViewModel>();
        
        return services.BuildServiceProvider();
    }
}
```

### 5. Build and Test
// turbo
```powershell
# Build solution
dotnet build "$projectPath\$projectName.sln"

# Run tests (if test project exists)
dotnet test "$projectPath"

# Run the application
dotnet run --project "$projectPath\$projectName.App"
```

### 6. Create Unit Test Project
```powershell
# Add test project
dotnet new xunit -n "$projectName.Tests" -o "$projectPath\$projectName.Tests"
dotnet sln "$projectPath\$projectName.sln" add "$projectPath\$projectName.Tests"
dotnet add "$projectPath\$projectName.Tests" reference "$projectPath\$projectName.Core"
```

### 7. Publish Application
```powershell
# Publish self-contained
dotnet publish "$projectPath\$projectName.App" -c Release -r win-x64 --self-contained true -o "$projectPath\publish"

# Publish framework-dependent (smaller size)
dotnet publish "$projectPath\$projectName.App" -c Release -o "$projectPath\publish-fd"
```

## Architecture Layers

| Layer | Purpose | Contains |
|-------|---------|----------|
| **Models** | Data structures | POCOs, DTOs, Enums |
| **Core** | Business logic | Services, Interfaces, Validators |
| **Infrastructure** | External concerns | File I/O, API clients, Logging |
| **ViewModels** | UI logic | MVVM ViewModels, Commands |
| **App** | Presentation | Views, Resources, Startup |

## Project Structure
```
[ProjectName]/
├── [ProjectName].sln
├── .editorconfig
├── .gitignore
├── [ProjectName].App/           # WPF application
│   ├── App.xaml
│   ├── MainWindow.xaml
│   └── Views/
├── [ProjectName].Core/          # Business logic
│   ├── Services/
│   ├── Interfaces/
│   └── Extensions/
├── [ProjectName].Infrastructure/ # External integrations
│   ├── FileSystem/
│   ├── Logging/
│   └── Configuration/
├── [ProjectName].Models/        # Data models
│   ├── Entities/
│   └── Enums/
├── [ProjectName].ViewModels/    # MVVM ViewModels
│   ├── MainViewModel.cs
│   └── Base/
└── [ProjectName].Tests/         # Unit tests
    └── Services/
```

## Best Practices

- **Dependency Injection**: Register all services in App.xaml.cs
- **MVVM Pattern**: Keep code-behind minimal, use ViewModels
- **Interface Segregation**: Define interfaces in Core, implement in Infrastructure
- **Async/Await**: Use async methods for I/O operations
- **Null Safety**: Enable nullable reference types in .csproj

## Quick Commands
```powershell
# Clean and rebuild
dotnet clean && dotnet build

# Watch mode (auto-rebuild on changes)
dotnet watch run --project "$projectName.App"

# Check for outdated packages
dotnet list package --outdated

# Update all packages
dotnet outdated --upgrade
```
