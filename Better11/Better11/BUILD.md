# Building Better11

The solution is **x64-only** (WinUI 3). Use **MSBuild** with `Platform=x64` for a reliable build. `dotnet build` can fail on the App project due to the WinUI XAML compiler.

## Quick build (recommended)

From the solution directory (`Better11\`):

```powershell
.\scripts\Build-Better11.ps1 -Configuration Release
```

The script uses MSBuild when available (Visual Studio or `MSBUILD_PATH`) and falls back to `dotnet build` otherwise.

## Manual build with MSBuild

1. **Restore**
   ```powershell
   dotnet restore Better11.sln
   ```

2. **Build** (requires MSBuild, e.g. from Visual Studio)
   ```powershell
   & "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" Better11.sln -p:Configuration=Release -p:Platform=x64 -t:Build -v:minimal -nologo
   ```
   Adjust the path to your Visual Studio install (Professional/Enterprise, or use `vswhere` to find it).

3. **Test**
   ```powershell
   dotnet test Better11.sln -c Release -p:Platform=x64 --no-build
   ```

4. **Package (MSIX)**
   ```powershell
   .\scripts\Build-Better11.ps1 -Configuration Release -Package
   ```

## Environment

- **MSBUILD_PATH** (optional): Set to `MSBuild.exe` if the script cannot find Visual Studio's MSBuild.
- **Platform**: Must be `x64`. The solution does not support `AnyCPU` or `x86` for the App project.
