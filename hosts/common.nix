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
in
{
  imports = lib.optionals hasTunnel [
    (cftunnelLib.mkCftunnel { inherit hostname; })
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "broadcom-bt-firmware"
      "claude-code"
      "cloudflare-warp"
      "copilot.vim"
      "discord"
      "git-credential-manager"
      "google-chrome"
      "intel-ocl"
      "open-webui"
      "slack"
      "steam"
      "steam-unwrapped"
      "vscode"
    ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Optimise space
  nix.gc.automatic = true;
  nix.optimise.automatic = true;

  environment.systemPackages = with pkgs; [
    git-credential-manager
  ];

  users.users.${username}.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINu7u4V6khhhUvepvptel86DN3XMCwZVdQe/7P6WW1KmAAAAFXNzaDphbmFudGhzLXNzaC1rZXktMQ== ananth@yubikey-5c"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFCVZPWg3DVxjuORNKJnjaRSPoZ4nYnzM070q0fIeM32AAAAG3NzaDphbmFudGhzLXNzaC1rZXktNWMtbmFubw== ananth@yubikey-5c-nano
"
  ];

  programs.fish.enable = true;

  sops.defaultSopsFile = ../secrets.yaml;
  sops.secrets = {
    "ssh/yubikey_5c" = { };
    "ssh/yubikey_5c.pub" = { };
    "ssh/yubikey_5c_nano" = { };
    "ssh/yubikey_5c_nano.pub" = { };
    "nut/users/nutmon" = { };
  };
}
