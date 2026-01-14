{
  description = "NixOS and Nix-Darwin configurations for Ananth's machines";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:sst/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    NixVirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tsnsrv = {
      url = "github:boinkor-net/tsnsrv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      lanzaboote,
      nix-darwin,
      nixos-hardware,
      nixpkgs,
      sops-nix,
      ...
    }@inputs:
    let
      localPrefix = "10.15.16";
      trustedIPs = "::1 127.0.0.0/8 ${ulaPrefix}::0/64 ${localPrefix}.0/24";
      ulaPrefix = "fdc0:6625:5195";
      username = "ananth";

      mkNixosHost =
        {
          hostname,
          system,
          extraModules ? [ ],
          meta ? { },
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              hostname
              inputs
              localPrefix
              meta
              system
              trustedIPs
              ulaPrefix
              username
              ;
            outputs = self;
          };
          modules = extraModules ++ [ ./hosts/${hostname} ];
        };

      mkDarwinHost =
        {
          hostname,
          system,
          extraModules ? [ ],
          meta ? { },
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              system
              hostname
              trustedIPs
              ulaPrefix
              username
              inputs
              meta
              ;
          };
          modules = extraModules ++ [ ./hosts/${hostname}.nix ];
        };
    in
    {
      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt;
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
      };

      nixosConfigurations = {
        endeavour = mkNixosHost {
          hostname = "endeavour";
          system = "x86_64-linux";
          extraModules = [ lanzaboote.nixosModules.lanzaboote ];
          meta = {
            staticIPSuffix = "50";
            primaryInterface = "bond0";
          };
        };

        enterprise = mkNixosHost {
          hostname = "enterprise";
          system = "x86_64-linux";
          extraModules = [ lanzaboote.nixosModules.lanzaboote ];
          meta = {
            staticIPSuffix = "55";
            primaryInterface = "enp86s0";
          };
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
