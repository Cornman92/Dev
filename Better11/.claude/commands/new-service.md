Scaffold a new Better11 C# service. The user will provide the service name as $ARGUMENTS.

Create the following files:

1. `src/Better11.Core/Services/Interfaces/I{Name}Service.cs`
   - File-scoped namespace `Better11.Core.Services.Interfaces;`
   - Interface with async methods returning `Result<T>` or `Task<Result<T>>`
   - CancellationToken on all async methods
   - XML documentation on interface and all members

2. `src/Better11.Services/Implementations/{Name}Service.cs`
   - File-scoped namespace `Better11.Services.Implementations;`
   - Implements the interface
   - Constructor injection for dependencies (IPowerShellService, ILogger, etc.)
   - Uses Result<T> pattern (never throws for expected failures)
   - Async/await with CancellationToken support

3. `src/Better11.Tests/{Name}/{Name}ServiceTests.cs`
   - xUnit test class
   - Moq for mocking dependencies
   - FluentAssertions for assertions
   - Tests for success paths, failure paths, edge cases, cancellation
   - Naming: {Method}_Should_{Expected}_When_{Condition}

4. Update `src/Better11.Services/Implementations/ServiceCollectionExtensions.cs`
   - Add `services.AddSingleton<I{Name}Service, {Name}Service>();`

Follow all conventions from CLAUDE.md. 0 StyleCop warnings required.
