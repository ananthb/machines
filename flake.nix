{
  description = "A SecureBoot-enabled NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lanzaboote,
      home-manager,
      nixvim,
      nix-darwin,
      nix-homebrew,
      homebrew-bundle,
      homebrew-core,
      homebrew-cask,
      homebrew-ffmpeg,
      homebrew-amiaos,
      ...
    }@inputs:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;

      darwinConfigurations = {
        discovery =
          let
            system = "aarch64-darwin";
            username = "ananth";
            hostname = "discovery";
          in
          nix-darwin.lib.darwinSystem {
            inherit system;

            specialArgs = inputs // {
              inherit system hostname username;
            };

            modules = [
              ./hosts/darwin.nix
              ./hosts/discovery

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
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${username} = {
                  imports = [
                    ./home/common.nix
                    ./home/darwin.nix
                  ];
                };
                home-manager.extraSpecialArgs = {
                  inherit username inputs system;
                };
              }
            ];
          };

        enterprise =
          let
            system = "aarch64-darwin";
            username = "ananth";
            hostname = "enterprise";
          in
          nix-darwin.lib.darwinSystem {
            inherit system;

            specialArgs = inputs // {
              inherit system hostname username;
            };

            modules = [
              ./hosts/darwin.nix
              ./hosts/enterprise

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
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${username} = {
                  imports = [
                    ./home/common.nix
                    ./home/darwin.nix
                    ./home/arr.nix
                  ];
                };
                home-manager.extraSpecialArgs = {
                  inherit username inputs system;
                };
              }
            ];
          };

      };
    };
}
