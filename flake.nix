{
  description = "A SecureBoot-enabled NixOS configurations";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  inputs.nix-darwin = {
    url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-homebrew = {
    url = "github:zhaofengli-wip/nix-homebrew";
  };
  inputs.homebrew-bundle = {
    url = "github:homebrew/homebrew-bundle";
    flake = false;
  };
  inputs.homebrew-core = {
    url = "github:homebrew/homebrew-core";
    flake = false;
  };
  inputs.homebrew-cask = {
    url = "github:homebrew/homebrew-cask";
    flake = false;
  };

  inputs.home-manager.url = "github:nix-community/home-manager/release-25.05";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixvim = {
    url = "github:nix-community/nixvim/nixos-25.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.ghostty = {
    url = "github:ghostty-org/ghostty";
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      home-manager,
      nixvim,
      nix-darwin,
      nix-homebrew,
      homebrew-bundle,
      homebrew-core,
      homebrew-cask,
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
              sops-nix.darwinModules.sops
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
              sops-nix.darwinModules.sops
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
