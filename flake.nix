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

    ht32-panel = {
      url = "github:ananthb/ht32-panel";
      inputs.nixpkgs.follows = "nixpkgs";
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

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      deploy-rs,
      lanzaboote,
      nix-darwin,
      nixos-hardware,
      nixpkgs,
      sops-nix,
      ...
    }@inputs:
    let
      username = "ananth";

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
              hostname
              inputs
              system
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
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              system
              hostname
              username
              inputs
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
          extraModules = [
            lanzaboote.nixosModules.lanzaboote
            { _module.args.ipv6Token = "::e4de:a704"; }
          ];
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

      deploy.nodes = {
        endeavour = {
          hostname = "endeavour";
          profiles.system = {
            user = "root";
            sshUser = username;
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.endeavour;
          };
        };

        enterprise = {
          hostname = "enterprise";
          profiles.system = {
            user = "root";
            sshUser = username;
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.enterprise;
          };
        };

        stargazer = {
          hostname = "stargazer";
          profiles.system = {
            user = "root";
            sshUser = username;
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.stargazer;
          };
        };

        voyager = {
          hostname = "voyager";
          profiles.system = {
            user = "root";
            sshUser = username;
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.voyager;
          };
        };
      };

      checks = builtins.mapAttrs (_system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
