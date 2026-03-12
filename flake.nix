{
  description = "NixOS and Nix-Darwin configurations for Ananth's machines";

  inputs = {
    askpass-homebrew-tap = {
      url = "github:theseal/homebrew-ssh-askpass";
      flake = false;
    };

    bcachefs-tools = {
      url = "github:koverstreet/bcachefs-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    nixpkgs-calibre.url = "github:NixOS/nixpkgs/0182a361324364ae3f436a63005877674cf45efb";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    switchyard = {
      url = "github:alyraffauf/switchyard";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vault-secrets = {
      url = "github:serokell/vault-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mithril = {
      url = "github:Overclock-Validator/mithril/fix-cu-simd-0339";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    NixVirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    tsnsrv = {
      url = "github:boinkor-net/tsnsrv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    deploy-rs,
    lanzaboote,
    nix-darwin,
    nixos-hardware,
    nixpkgs,
    nixpkgs-calibre,
    pre-commit-hooks-nix,
    ...
  } @ inputs: let
    username = "ananth";
    containerImages = import ./lib/container-images.nix;

    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    pkgsCalibreFor = system: import nixpkgs-calibre {inherit system;};

    calibreOverlay = final: _: {
      inherit ((pkgsCalibreFor final.stdenv.hostPlatform.system)) calibre;
    };

    pyhumpsOverlay =
      # Until: https://github.com/NixOS/nixpkgs/issues/494075
      _final: prev: {
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions
          ++ [
            (_pfinal: pprev: {
              pyhumps = pprev.pyhumps.overrideAttrs (old: {
                doCheck = false;
                patches =
                  (old.patches or [])
                  ++ [
                    (prev.fetchpatch {
                      url = "https://github.com/nficano/humps/commit/f61bb34de152e0cc6904400c573bcf83cfdb67f9.patch";
                      hash = "sha256-nLmRRxedpB/O4yVBMY0cqNraDUJ6j7kSBG4J8JKZrrE=";
                    })
                  ];
              });
            })
          ];
      };

    mkNixosHost = {
      hostname,
      system,
      extraModules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit
            hostname
            containerImages
            inputs
            system
            username
            ;
          # Avoid _module.args recursion for mithril module argument resolution.
          mithrilIsUser = false;
          outputs = self;
        };
        modules =
          extraModules
          ++ [
            {
              nixpkgs.overlays = [
                calibreOverlay
                pyhumpsOverlay
              ];
            }
            ./hosts/${hostname}
          ];
      };

    mkDarwinHost = {
      hostname,
      system,
      extraModules ? [],
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
        modules =
          extraModules
          ++ [
            {nixpkgs.overlays = [calibreOverlay];}
            ./hosts/${hostname}.nix
          ];
      };
  in rec {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    nixosConfigurations = {
      endeavour = mkNixosHost {
        hostname = "endeavour";
        system = "x86_64-linux";
        extraModules = [
          lanzaboote.nixosModules.lanzaboote
          {_module.args.ipv6Token = "::e4de:a704";}
        ];
      };

      enterprise = mkNixosHost {
        hostname = "enterprise";
        system = "x86_64-linux";
        extraModules = [
          lanzaboote.nixosModules.lanzaboote
          {_module.args.ipv6Token = "::c0de:1";}
        ];
      };

      stargazer = mkNixosHost {
        hostname = "stargazer";
        system = "aarch64-linux";
        extraModules = [nixos-hardware.nixosModules.raspberry-pi-4];
      };

      voyager = mkNixosHost {
        hostname = "voyager";
        system = "aarch64-linux";
        extraModules = [nixos-hardware.nixosModules.raspberry-pi-4];
      };
    };

    lib = {
      immichMlHosts = import ./lib/immich-ml-hosts.nix {
        inherit nixosConfigurations;
        inherit (nixpkgs) lib;
        immichMlImage = containerImages.immichMl;
      };
    };

    darwinConfigurations = {
      discovery = mkDarwinHost {
        hostname = "discovery";
        system = "aarch64-darwin";
        extraModules = [];
      };
    };

    deploy.nodes = {
      endeavour = {
        system = "x86_64-linux";
        hostname = "endeavour";
        profiles.system = {
          sshUser = username;
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.endeavour;
        };
      };

      enterprise = {
        system = "x86_64-linux";
        hostname = "enterprise";
        profiles.system = {
          sshUser = username;
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.enterprise;
        };
      };

      stargazer = {
        system = "aarch64-linux";
        hostname = "stargazer";
        profiles.system = {
          sshUser = username;
          user = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.stargazer;
        };
      };

      #voyager = {
      #  hostname = "voyager";
      #  profiles.system = {
      #    sshUser = username;
      #    user = "root";
      #    path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.voyager;
      #  };
      #};
    };

    checks = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        formatterPkg = self.formatter.${system};
        deployChecks = deploy-rs.lib.${system}.deployChecks (
          self.deploy
          // {
            nodes = nixpkgs.lib.filterAttrs (_: node: node.system == system) self.deploy.nodes;
          }
        );
        preCommitCheck = pre-commit-hooks-nix.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };
      in
        deployChecks
        // {
          pre-commit = preCommitCheck;
          formatting = pkgs.runCommand "check-formatting" {buildInputs = [formatterPkg];} ''
            ${pkgs.lib.getExe formatterPkg} --check ${self}
            touch $out
          '';
          statix = pkgs.runCommand "check-statix" {buildInputs = [pkgs.statix];} ''
            statix check ${self}
            touch $out
          '';
          deadnix = pkgs.runCommand "check-deadnix" {buildInputs = [pkgs.deadnix];} ''
            deadnix --fail ${self}
            touch $out
          '';
        }
    );

    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        formatterPkg = self.formatter.${system};
        preCommitCheck = pre-commit-hooks-nix.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };
      in {
        default = pkgs.mkShell {
          inherit (preCommitCheck) shellHook;
          packages =
            preCommitCheck.enabledPackages
            ++ [
              formatterPkg
              pkgs.statix
              pkgs.deadnix
              pkgs.gh
              deploy-rs.packages.${system}.default
            ];
        };
      }
    );
  };
}
