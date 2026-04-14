# Personal development config: git identity, sops secrets, personal packages.
# Reusable dev tooling (nixvim, git settings, direnv) lives in modules/home/dev.nix.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  imports = [
    ../modules/home/dev.nix
    inputs.zed-spaces-launcher.homeManagerModules.default
  ];

  sops = {
    age.sshKeyPaths = [(homeDir + "/.ssh/id_ed25519")];
    defaultSopsFile = ../secrets/dev.yaml;

    secrets = {
      "ssh/yubikey_5c" = {
        path = homeDir + "/.ssh/yubikey_5c";
      };
      "ssh/yubikey_5c.pub" = {
        path = homeDir + "/.ssh/yubikey_5c.pub";
      };
      "ssh/yubikey_5c_nano" = {
        path = homeDir + "/.ssh/yubikey_5c_nano";
      };
      "ssh/yubikey_5c_nano.pub" = {
        path = homeDir + "/.ssh/yubikey_5c_nano.pub";
      };
    };
  };

  # Fix for sops-nix LaunchAgent on macOS.
  launchd.agents.sops-nix = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      EnvironmentVariables = {
        PATH = pkgs.lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };

  home.packages = with pkgs;
    [
      claude-code
      devenv
      flyctl
      fzf
      gemini-cli
      gh
      git-absorb
      git
      gnupg
      hack-font
      jellyfin-media-player
      lazygit
      mosh
      nix-output-monitor
      ripgrep
      vault
      vscode
      zed-editor
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      activitywatch
      ghostty
      gimp
      rpi-imager
      vlc
    ];

  programs = {
    git.settings.user = {
      name = "Ananth Bhaskararaman";
      email = "antsub@gmail.com";
      useConfigOnly = "true";
    };

    codespace-zed = {
      enable = true;
      defaultTarget = "rpcpool";
      targets.rpcpool = {
        repository = "rpcpool/rpcpool";
      };
    };
  };
}
