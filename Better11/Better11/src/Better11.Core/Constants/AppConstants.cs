// ============================================================================
// File: src/Better11.Core/Constants/AppConstants.cs
// Better11 System Enhancement Suite - Application Constants
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

namespace Better11.Core.Constants
{
    /// <summary>
    /// Application-wide constants.
    /// </summary>
    public static class AppConstants
    {
        /// <summary>The application name.</summary>
        public const string AppName = "Better11";

        /// <summary>The application display name.</summary>
        public const string AppDisplayName = "Better11 System Enhancement Suite";

        /// <summary>The application version.</summary>
        public const string AppVersion = "1.0.0";

        /// <summary>The copyright notice.</summary>
        public const string Copyright = "Copyright (c) 2026 Better11";

        /// <summary>URL to the application version manifest (JSON) for update checks.</summary>
        public const string UpdateManifestUrl = "https://docs.better11.app/version-manifest.json";

        /// <summary>
        /// PowerShell module name mappings.
        /// </summary>
        public static class Modules
        {
            /// <summary>Package management module.</summary>
            public const string Packages = "B11.Packages";

            /// <summary>Driver management module.</summary>
            public const string Drivers = "B11.Drivers";

            /// <summary>Startup management module.</summary>
            public const string Startup = "B11.Startup";

            /// <summary>Scheduled tasks module.</summary>
            public const string Tasks = "B11.Tasks";

            /// <summary>Network management module.</summary>
            public const string Network = "B11.Network";

            /// <summary>Disk cleanup module.</summary>
            public const string DiskCleanup = "B11.DiskCleanup";

            /// <summary>System information module.</summary>
            public const string SystemInfo = "B11.SystemInfo";

            /// <summary>Optimization module.</summary>
            public const string Optimization = "B11.Optimization";

            /// <summary>Privacy module.</summary>
            public const string Privacy = "B11.Privacy";

            /// <summary>Security module.</summary>
            public const string Security = "B11.Security";

            /// <summary>Windows Update module.</summary>
            public const string Update = "B11.Update";

            /// <summary>BetterPE imaging module.</summary>
            public const string BetterPE = "B11.BetterPE";
        }

        /// <summary>
        /// Navigation page keys.
        /// </summary>
        public static class Pages
        {
            /// <summary>Dashboard page key.</summary>
            public const string Dashboard = "Dashboard";

            /// <summary>Package manager page key.</summary>
            public const string Packages = "Packages";

            /// <summary>Driver manager page key.</summary>
            public const string Drivers = "Drivers";

            /// <summary>Startup manager page key.</summary>
            public const string Startup = "Startup";

            /// <summary>Scheduled tasks page key.</summary>
            public const string Tasks = "Tasks";

            /// <summary>Network manager page key.</summary>
            public const string Network = "Network";

            /// <summary>Disk cleanup page key.</summary>
            public const string DiskCleanup = "DiskCleanup";

            /// <summary>System info page key.</summary>
            public const string SystemInfo = "SystemInfo";

            /// <summary>Optimization page key.</summary>
            public const string Optimization = "Optimization";

            /// <summary>Privacy page key.</summary>
            public const string Privacy = "Privacy";

            /// <summary>Security page key.</summary>
            public const string Security = "Security";

            /// <summary>Updates page key.</summary>
            public const string Updates = "Updates";

            /// <summary>Settings page key.</summary>
            public const string Settings = "Settings";

            /// <summary>About page key.</summary>
            public const string About = "About";

            /// <summary>First Run Wizard page key.</summary>
            public const string FirstRunWizard = "FirstRunWizard";
        }
    }
}
