{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  system,
  username,
  ...
}: {
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    {
      nix-homebrew = {
        user = username;
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
        users.${username} = {
          imports = let
            hostModule = (import ../../lib/home-host-module.nix {inherit lib;}) hostname;
          in [
            ../../home/common.nix
            hostModule
          ];
        };
        extraSpecialArgs = {
          inherit
            hostname
            pkgs
            system
            username
            ;

          inherit inputs;
        };
      };
    }

    ./nix-settings.nix
  ];

  nix.settings.trusted-users = ["root" username];

  nix.gc.interval = {
    Hour = 3;
    Minute = 15;
    Weekday = 7;
  };

  # Set primary user because of the whole
  # 'run-services-as-root-for-better-multiuser-support' thing.
  system.primaryUser = username;

  services.karabiner-elements.enable = false;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  # Manually set nixbld gid because this changed to 30000 by default.
  ids.gids.nixbld = 350;

  users.users.${username} = {
    name = username;
    home = "/Users/" + username;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = import ../../lib/ssh-keys.nix;
  };

  programs.fish.enable = true;

  programs.ssh.extraConfig = ''
    Host *
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
