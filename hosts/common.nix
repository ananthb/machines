{
  hostname,
  lib,
  pkgs,
  username,
  ...
}:
let
  cftunnelLib = import ../lib/cftunnel.nix;
  hasTunnel = cftunnelLib.tunnels ? ${hostname};
  nixCache = import ../lib/nix-cache.nix;
in
{
  imports = lib.optionals hasTunnel [
    (cftunnelLib.mkCftunnel { inherit hostname; })
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "b43-firmware"
      "broadcom-bt-firmware"
      "claude-code"
      "cloudflare-warp"
      "copilot.vim"
      "crush"
      "discord"
      "google-chrome"
      "intel-ocl"
      "slack"
      "steam"
      "steam-unwrapped"
      "terraform"
      "unrar"
      "vscode"
      "xow_dongle-firmware"
    ];

  # Necessary for using flakes on this system.
  nix = {
    settings = {
      experimental-features = "nix-command flakes";

      trusted-users = [
        "root"
        username
      ];

      # Use endeavour as a binary cache (with public cache as fallback)
      extra-substituters = [ "http://${nixCache.cacheHost}:${toString nixCache.cachePort}" ];
      extra-trusted-public-keys = [ nixCache.publicKey ];
    };

    # Optimise space
    gc.automatic = true;
    optimise.automatic = true;
  };

  users.users.${username} = {
    name = username;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINu7u4V6khhhUvepvptel86DN3XMCwZVdQe/7P6WW1KmAAAAFXNzaDphbmFudGhzLXNzaC1rZXktMQ== ananth@yubikey-5c"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFCVZPWg3DVxjuORNKJnjaRSPoZ4nYnzM070q0fIeM32AAAAG3NzaDphbmFudGhzLXNzaC1rZXktNWMtbmFubw== ananth@yubikey-5c-nano"
    ];
  };

  programs.fish.enable = true;

  sops.defaultSopsFile = ../secrets.yaml;
  sops.secrets = {
    "ssh/yubikey_5c" = { };
    "ssh/yubikey_5c.pub" = { };
    "ssh/yubikey_5c_nano" = { };
    "ssh/yubikey_5c_nano.pub" = { };
  };
}
