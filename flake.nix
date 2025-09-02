{
  description = "A SecureBoot-enabled NixOS configurations";

  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  inputs.nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

  inputs.lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
  inputs.lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
  inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  inputs.homebrew-bundle.url = "github:homebrew/homebrew-bundle";
  inputs.homebrew-bundle.flake = false;
  inputs.homebrew-core.url = "github:homebrew/homebrew-core";
  inputs.homebrew-core.flake = false;
  inputs.homebrew-cask.url = "github:homebrew/homebrew-cask";
  inputs.homebrew-cask.flake = false;

  inputs.home-manager.url = "github:nix-community/home-manager/release-25.05";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixvim.url = "github:nix-community/nixvim/nixos-25.05";
  inputs.nixvim.inputs.nixpkgs.follows = "nixpkgs";

  inputs.tsnsrv.url = "github:boinkor-net/tsnsrv";
  inputs.tsnsrv.inputs.nixpkgs.follows = "nixpkgs";

  inputs.quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

  outputs =
    {
      self,
      nixos-hardware,
      nixpkgs,
      nixpkgs-unstable,
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
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-rfc-style;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;

      nixosConfigurations = {
        endeavour =
          let
            system = "x86_64-linux";
            username = "ananth";
            hostname = "endeavour";
          in
          nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = inputs // {
              inherit system hostname username;
            };

            modules = [
              lanzaboote.nixosModules.lanzaboote
              sops-nix.nixosModules.sops
              quadlet-nix.nixosModules.quadlet
              ./hosts/endeavour
            ];
          };

        voyager =
          let
            system = "aarch64-linux";
            username = "ananth";
            hostname = "voyager";
          in
          nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = inputs // {
              inherit system hostname username;
            };

            modules = [
              nixos-hardware.nixosModules.raspberry-pi-4
              sops-nix.nixosModules.sops
              ./hosts/linux.nix
              ./hosts/voyager
            ];
          };
      };

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
              ./hosts/discovery.nix
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
              ./hosts/enterprise.nix
            ];
          };

      };
    };
}
