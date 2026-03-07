{
  "profiles": {
    "base_security": {
      "tweaks": ["EnableFirewallHardening","EnableBitLocker","DisableSMBv1"]
    },
    "base_dev": {
      "install": ["Microsoft.VisualStudioCode","Git.Git","Docker.DockerDesktop"],
      "tweaks": ["ShowFileExtensions","EnableStorageSense"]
    },
    "base_gaming": {
      "install": ["Valve.Steam","CapFrameX.CapFrameX","NVIDIA.GeForceExperience"],
      "tweaks": ["EnableGameMode","DisableGameBar"]
    },
    "composite_workstation": {
      "inherits": ["base_security","base_dev","base_gaming"],
      "overrides": {
        "tweaks_add": ["EnableGPUScheduling"],
        "install_add": ["Python.Python.3.12"]
      }
    }
  }
}
