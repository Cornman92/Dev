using System.Security.Principal;

namespace Better11.Core.Helpers;

public static class AdminHelper
{
    public static bool IsRunningAsAdmin()
    {
        using var identity = WindowsIdentity.GetCurrent();
        var principal = new WindowsPrincipal(identity);
        return principal.IsInRole(WindowsBuiltInRole.Administrator);
    }

    public static string GetCurrentUser()
    {
        return WindowsIdentity.GetCurrent().Name;
    }
}
