{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  cfg = config.machines;
in {
  imports = [
    ../../modules/options.nix

    inputs.nix-homebrew.darwinModules.nix-homebrew
    {
      nix-homebrew = {
        user = cfg.username;
        enable = true;
        taps = {
          "homebrew/homebrew-core" = inputs.homebrew-core;
          "homebrew/homebrew-cask" = inputs.homebrew-cask;
          "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
          "theseal/homebrew-ssh-askpass" = inputs.askpass-homebrew-tap;
        };
        mutableTaps = false;
        autoMigrate = true;
      };
    }

    inputs.home-manager.darwinModules.home-manager
    {
      home-manager = {
        backupFileExtension = "hm-backup";
        sharedModules = [
          inputs.sops-nix.homeManagerModules.sops
          inputs.nix-index-database.homeModules.nix-index
        ];
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${cfg.username} = {
          imports = let
            hostModule = (import ../../lib/home-host-module.nix {inherit lib;}) hostname;
          in [
            ../../home/common.nix
            hostModule
          ];
        };
        extraSpecialArgs = {
          inherit hostname pkgs system inputs;
          inherit (cfg) username;
        };
      };
    }

    ./nix-settings.nix
  ];

  nix.settings.trusted-users = ["root" cfg.username];

  nix.gc.interval = {
    Hour = 3;
    Minute = 15;
    Weekday = 7;
  };

  # Set primary user because of the whole
  # 'run-services-as-root-for-better-multiuser-support' thing.
  system.primaryUser = cfg.username;

  services.karabiner-elements.enable = false;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  # Manually set nixbld gid because this changed to 30000 by default.
  ids.gids.nixbld = 350;

  users.users.${cfg.username} = {
    name = cfg.username;
    home = "/Users/" + cfg.username;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = cfg.sshKeys;
  };

  programs.fish.enable = true;

  # Exclude codespace hosts (cs.* and cs-*) so cosmonaut's check
  # against bare `Host *` rules in ~/.ssh/config stays green.
  programs.ssh.extraConfig = ''
    Host * !cs-* !cs.*
      AddKeysToAgent yes
  '';

  environment.systemPackages = with pkgs; [
    mas
  ];

  services.prometheus.exporters.node.enable = true;

  fonts.packages = [pkgs.hack-font];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = [
      "openssh" # needed for yubikey ssh keys
    ];
    casks = [
      "ddpm"
      "ghostty"
      "gimp"
      "logi-options+"
      "raspberry-pi-imager"
      "rectangle-pro"
      "scroll-reverser"
      "vlc"
      "yubico-authenticator"
    ];
    masApps = {
      "Tailscale" = 1475387142;
    };
  };
}
