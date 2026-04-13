{
  description = "NixOS and Nix-Darwin configurations for Ananth's machines";

  inputs = {
    askpass-homebrew-tap = {
      url = "github:theseal/homebrew-ssh-askpass";
      flake = false;
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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks.follows = "git-hooks";
        rust-overlay.follows = "lanzaboote/rust-overlay";
      };
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "nixvim/flake-parts";
        pre-commit-hooks-nix.follows = "git-hooks";
      };
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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "ht32-panel/flake-utils/systems";
      };
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    starla = {
      url = "github:ananthb/starla";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks.follows = "git-hooks";
        flake-utils.follows = "ht32-panel/flake-utils";
        rust-overlay.follows = "lanzaboote/rust-overlay";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    switchyard = {
      url = "github:alyraffauf/switchyard";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks-nix.follows = "git-hooks";
        flake-parts.follows = "nixvim/flake-parts";
      };
    };

    zed-spaces-launcher = {
      url = "github:ananthb/zed-spaces-launcher";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "ht32-panel/flake-utils";
      };
    };

    vault-secrets = {
      url = "github:serokell/vault-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "deploy-rs/flake-compat";
    };

    mithril = {
      url = "github:ananthb/mithril/fix/vote-nil-root-and-slot-log";
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
      inputs.flake-parts.follows = "nixvim/flake-parts";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "ht32-panel/flake-utils";
    };

    garnix-lib = {
      url = "github:garnix-io/garnix-lib";
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
    git-hooks,
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

    mkNixosHost = {
      hostname,
      system,
      extraModules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit
            hostname
            containerImages
            inputs
            system
            username
            ;
          outputs = self;
        };
        modules =
          extraModules
          ++ [
            {nixpkgs.hostPlatform = nixpkgs.lib.mkDefault system;}
            ./hosts/${hostname}
          ];
      };

    mkDarwinHost = {
      hostname,
      system,
      extraModules ? [],
    }:
      nix-darwin.lib.darwinSystem {
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
            ./hosts/${hostname}.nix
          ];
      };
  in {
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

      kedi-cloud-garnix1 = mkNixosHost {
        hostname = "kedi-cloud-garnix1";
        system = "x86_64-linux";
      };
    };

    lib = {
      immichMlHosts = import ./lib/immich-ml-hosts.nix {
        inherit (self) nixosConfigurations;
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
        hostname = "endeavour.tail42937.ts.net";
        profiles.system = {
          sshUser = "root";
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.endeavour;
        };
      };

      enterprise = {
        system = "x86_64-linux";
        hostname = "enterprise";
        profiles.system = {
          sshUser = "root";
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.enterprise;
        };
      };

      stargazer = {
        system = "aarch64-linux";
        hostname = "stargazer";
        profiles.system = {
          sshUser = "root";
          user = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.stargazer;
        };
      };
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

        # Hosts deployed by Garnix must not appear in deploy-rs nodes,
        # otherwise both systems race to activate the same machine.
        garnixDeployedHosts = ["kedi-cloud-garnix1"];
        deployRsHosts = builtins.attrNames self.deploy.nodes;
        conflicts = builtins.filter (h: builtins.elem h deployRsHosts) garnixDeployedHosts;
      in
        assert conflicts
        == []
        || throw "These hosts are deployed by both Garnix and deploy-rs: ${builtins.concatStringsSep ", " conflicts}. Remove them from deploy.nodes in flake.nix.";
          deployChecks
          // {
            pre-commit = self.devShells.${system}.default.passthru.preCommitCheck;
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
        preCommitCheck = git-hooks.lib.${system}.run {
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
          passthru = {inherit preCommitCheck;};
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
