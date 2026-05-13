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
    inputs.cosmonaut.homeManagerModules.default
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
      delta
      devenv
      flyctl
      fzf
      gemini-cli
      gh
      git-absorb
      git
      gnupg
      hack-font
      lazygit
      mosh
      nix-output-monitor
      ripgrep
      vault
      zed-editor
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      activitywatch
      claude-code
      ghostty
      gimp
      jellyfin-media-player
      rpi-imager
      vlc
      vscode
    ];

  programs = {
    git.settings.user = {
      name = "Ananth Bhaskararaman";
      email = "antsub@gmail.com";
      useConfigOnly = "true";
    };

    cosmonaut = {
      enable = true;
      package = inputs.cosmonaut.packages.${pkgs.system}.default.overrideAttrs (_: {
        checkPhase = ''
          runHook preCheck
          export GOFLAGS=''${GOFLAGS//-trimpath/}
          go test -v -failfast -tags=netgo ./...
          runHook postCheck
        '';
      });
      defaultTarget = "rpcpool";
      targets.rpcpool = {
        repository = "rpcpool/rpcpool";
        workspacePath = "/workspaces";
      };
    };
  };
}
