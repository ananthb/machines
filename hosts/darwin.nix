{
  pkgs,
  system,
  username,
  config,
  nixvim,
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  home-manager,
  sops-nix,
  ...
}:

{

  imports = [
    nix-homebrew.darwinModules.nix-homebrew
    {
      nix-homebrew = {
        user = username;
        enable = true;
        taps = {
          "homebrew/homebrew-core" = homebrew-core;
          "homebrew/homebrew-cask" = homebrew-cask;
          "homebrew/homebrew-bundle" = homebrew-bundle;
        };
        mutableTaps = false;
        autoMigrate = true;
      };
    }

    home-manager.darwinModules.home-manager
    {
      home-manager.sharedModules = [
        sops-nix.homeManagerModules.sops
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = {
        imports = [
          ../home/common.nix
          ../home/darwin.nix
        ];
      };
      home-manager.extraSpecialArgs = {
        inherit
          username
          system
          pkgs
          nixvim
          ;
      };
    }
  ];

  nix.settings.trusted-users = [ username ];

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
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINu7u4V6khhhUvepvptel86DN3XMCwZVdQe/7P6WW1KmAAAAFXNzaDphbmFudGhzLXNzaC1rZXktMQ== ananth@yubikey-5c"
    ];
  };

  environment.shells = [ pkgs.fish ];

  programs.fish.enable = true;

  programs.ssh.extraConfig = ''
    Host *
      AddKeysToAgent yes
      IdentityFile ~/.ssh/id_ed25519_sk
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
      "google-chrome"
      "visual-studio-code"
      "ghostty"
      "rectangle-pro"
      "scroll-reverser"
      "ddpm"
      "vlc"
      "logi-options+"
    ];
    masApps = {
      "GarageBand" = 682658836;
      "iMovie" = 408981434;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Tailscale" = 1475387142;
      "Velja" = 1607635845;
    };
  };
}
