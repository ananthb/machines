{
  description = "A SecureBoot-enabled NixOS configurations";

  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  inputs.nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

  inputs.lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";
  inputs.lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-darwin.url = "github:nix-darwin/nix-darwin/master";
  inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  inputs.homebrew-bundle.url = "github:homebrew/homebrew-bundle";
  inputs.homebrew-bundle.flake = false;
  inputs.homebrew-core.url = "github:homebrew/homebrew-core";
  inputs.homebrew-core.flake = false;
  inputs.homebrew-cask.url = "github:homebrew/homebrew-cask";
  inputs.homebrew-cask.flake = false;

  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixvim.url = "github:nix-community/nixvim";
  inputs.nixvim.inputs.nixpkgs.follows = "nixpkgs";

  inputs.tsnsrv.url = "github:boinkor-net/tsnsrv";
  inputs.tsnsrv.inputs.nixpkgs.follows = "nixpkgs";

  inputs.quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

  outputs =
    {
      self,
      nixos-hardware,
      nixpkgs,
      sops-nix,
      nix-index-database,
      lanzaboote,
      home-manager,
      nixvim,
      nix-darwin,
      nix-homebrew,
      homebrew-bundle,
      homebrew-core,
      homebrew-cask,
      tsnsrv,
      quadlet-nix,
      ...
    }@inputs:
    let
      username = "ananth";
      trustedIPs = [
        "::1"
        "127.0.0.0/8"
        "fdc0:6625:5195::0/64"
        "10.15.16.0/24"
      ];

      mkNixosHost =
        {
          hostname,
          system,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              system
              hostname
              trustedIPs
              username
              inputs
              ;
          };
          modules = extraModules ++ [ ./hosts/${hostname} ];
        };

      mkDarwinHost =
        {
          hostname,
          system,
          extraModules ? [ ],
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              system
              hostname
              trustedIPs
              username
              inputs
              ;
          };
          modules = extraModules ++ [ ./hosts/${hostname}.nix ];
        };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-rfc-style;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;

      nixosConfigurations = {
        endeavour = mkNixosHost {
          hostname = "endeavour";
          system = "x86_64-linux";
          extraModules = [ lanzaboote.nixosModules.lanzaboote ];
        };

        enterprise = mkNixosHost {
          hostname = "enterprise";
          system = "x86_64-linux";
          extraModules = [ lanzaboote.nixosModules.lanzaboote ];
        };

        stargazer = mkNixosHost {
          hostname = "stargazer";
          system = "aarch64-linux";
          extraModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
        };

        voyager = mkNixosHost {
          hostname = "voyager";
          system = "aarch64-linux";
          extraModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
        };
      };

      darwinConfigurations = {
        discovery = mkDarwinHost {
          hostname = "discovery";
          system = "aarch64-darwin";
          extraModules = [ sops-nix.darwinModules.sops ];
        };
      };
    };
}
