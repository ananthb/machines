# Shared nix/nixpkgs settings for all platforms (NixOS, Darwin, Garnix).
{lib, ...}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "b43-firmware"
      "broadcom-bt-firmware"
      "claude-code"
      "cloudflare-warp"
      "codex"
      "copilot.vim"
      "crush"
      "discord"
      "google-chrome"
      "intel-ocl"
      "slack"
      "steam"
      "steam-unwrapped"
      "vault"
      "terraform"
      "unrar"
      "vault-bin"
      "vscode"
      "xone-dongle-firmware"
      "xow_dongle-firmware"
    ];

  nix = {
    settings = {
      experimental-features = "nix-command flakes";

      extra-substituters = [
        "https://cache.garnix.io"
      ];
      extra-trusted-public-keys = [
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };

    gc.automatic = true;
    optimise.automatic = true;
  };
}
