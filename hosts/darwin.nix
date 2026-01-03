{
  config,
  hostname,
  inputs,
  pkgs,
  system,
  username,
  ...
}:

{

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
        };
        mutableTaps = false;
        autoMigrate = true;
      };
    }

    inputs.home-manager.darwinModules.home-manager
    {
      home-manager.sharedModules = [
        inputs.sops-nix.homeModules.sops
        inputs.nix-index-database.homeModules.nix-index
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = {
        imports = [
          ../home/common.nix
          ../home/darwin.nix
          ../home/${hostname}.nix
        ];
      };
      home-manager.extraSpecialArgs = {
        inherit
          hostname
          pkgs
          system
          username
          ;

        inputs = inputs;
      };
    }

    ./common.nix
  ];

  nix.settings.trusted-users = [ username ];
  nix.gc.interval = {
    Hour = 3;
    Minute = 15;
    Weekday = 7;
  };

  # Set primary user because of the whole
  # 'run-services-as-root-for-better-multiuser-support' thing.
  system.primaryUser = username;

  services.karabiner-elements.enable = true;
  # See: https://github.com/nix-darwin/nix-darwin/issues/1041#issuecomment-2889787482
  services.karabiner-elements.package = pkgs.karabiner-elements.overrideAttrs (old: {
    version = "14.13.0";

    src = pkgs.fetchurl {
      inherit (old.src) url;
      hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
    };

    dontFixup = true;
  });

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # Manually set nixbld gid because this changed to 30000 by default.
  ids.gids.nixbld = 350;

  users.users.${username} = {
    name = username;
    home = "/Users/" + username;
    shell = pkgs.fish;
  };

  programs.ssh.extraConfig = ''
    Host *
      AddKeysToAgent yes
      IdentityFile ~/.ssh/yubikey_5c
      IdentityFile ~/.ssh/yubikey_5c_nano
  '';

  fonts.packages = [ pkgs.hack-font ];

  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap";
    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = [
      "mas"
      {
        name = "neovim";
        link = false;
      }
      "openssh" # needed for yubikey ssh keys
      {
        name = "node_exporter";
        start_service = true;
      }
    ];
    casks = [
      # hardware support
      "ddpm"
      "logi-options+"
      "yubico-authenticator"

      # tools
      "ollama-app"
      "rectangle-pro"
      "raspberry-pi-imager"
      "scroll-reverser"
      "seadrive"

      # dailies
      "ghostty"
      "google-chrome"
      "neovide-app"

      # media
      "jellyfin-media-player"
      "vlc"
    ];
    masApps = {
      "Tailscale" = 1475387142;
    };
  };
}
