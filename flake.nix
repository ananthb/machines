{
  description = "NixOS and Nix-Darwin configurations for Ananth's machines";

  inputs = {
    askpass-homebrew-tap = {
      url = "github:theseal/homebrew-ssh-askpass";
      flake = false;
    };

    cosmonaut = {
      url = "github:linuskendall/cosmonaut";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "ht32-panel/flake-utils";
      };
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

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
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

    mithril = {
      url = "github:ananthb/mithril/fix/vote-nil-root-and-slot-log";
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

    NixVirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
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

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    sops-nix = {
      url = "github:Mic92/sops-nix";
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

    switchyard = {
      url = "github:alyraffauf/switchyard";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks-nix.follows = "git-hooks";
        flake-parts.follows = "nixvim/flake-parts";
      };
    };

    tsnsrv = {
      url = "github:boinkor-net/tsnsrv";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "nixvim/flake-parts";
    };

    vault-secrets = {
      url = "github:serokell/vault-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "deploy-rs/flake-compat";
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

    # Pre-instantiate nixpkgs per system so same-arch hosts share one
    # evaluation instead of each creating their own (~1-2 GB heap each).
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "1password"
              "b43-firmware"
              "broadcom-bt-firmware"
              "claude-code"
              "codex"
              "copilot.vim"
              "crush"
              "discord"
              "google-chrome"
              "intel-ocl"
              "slack"
              "steam"
              "steam-unwrapped"
              "vault"
              "terraform"
              "unrar"
              "vault-bin"
              "vscode"
              "xone-dongle-firmware"
              "xow_dongle-firmware"
            ];
          packageOverrides = pkgs: {
            vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
          };
        };
        overlays = [
          # Modify jellyfin-web index.html for the intro-skipper plugin.
          (_final: prev: {
            jellyfin-web = prev.jellyfin-web.overrideAttrs (
              _finalAttrs: _previousAttrs: {
                installPhase = ''
                  runHook preInstall
                  sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html
                  mkdir -p $out/share
                  cp -a dist $out/share/jellyfin-web
                  runHook postInstall
                '';
              }
            );
          })
          # Bypass the vimPlugins.nvim-treesitter-legacy deprecation warning
          # that fires on every neovim build via vim-utils.nix's assert
          # (which forces the warnOnInstantiate-wrapped drv). We don't use
          # any plugin that needs the legacy package.
          (_: prev: {
            vimPlugins = prev.vimPlugins.extend (
              _: vprev: {
                nvim-treesitter-legacy = vprev.nvim-treesitter.overrideAttrs (_: {
                  pname = "nvim-treesitter-legacy-shim";
                });
              }
            );
          })
          # logiops patch: https://github.com/NixOS/nixpkgs/issues/226575#issuecomment-2813539847
          (_: prev: {
            logiops = prev.logiops.overrideAttrs (old: {
              patches =
                (old.patches or [])
                ++ [
                  (prev.fetchpatch {
                    url = "https://github.com/PixlOne/logiops/commit/91aa0c12175f33a4184ccaf41181b0a799f7cc55.patch";
                    hash = "sha256-A+StDD+Dp7lPWVpuYR9JR5RuvwPU/5h50B0lY8Qu7nY=";
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
      passOutputs ? false,
    }:
      nixpkgs.lib.nixosSystem {
        specialArgs =
          {
            inherit
              hostname
              containerImages
              inputs
              system
              username
              ;
          }
          // nixpkgs.lib.optionalAttrs passOutputs {
            outputs = self;
          };
        modules =
          extraModules
          ++ [
            {nixpkgs.pkgs = pkgsFor system;}
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
            {nixpkgs.pkgs = pkgsFor system;}
            ./hosts/${hostname}.nix
          ];
      };
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    nixosConfigurations = {
      endeavour = mkNixosHost {
        hostname = "endeavour";
        system = "x86_64-linux";
        passOutputs = true; # services/immich.nix uses outputs.lib.immichMlHosts
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
        passOutputs = true; # services/monitoring/victoriametrics.nix uses outputs.nixosConfigurations
      };
    };

    lib = {
      immichMlHosts = import ./lib/immich-ml-hosts.nix {
        inherit (self) nixosConfigurations;
        inherit (nixpkgs) lib;
        immichMlImage = containerImages.immichMl;
      };
      mkCaddyReverseProxies = import ./lib/caddy-helpers.nix;
    };

    nixosModules = {
      default = ./modules/nixos;
      options = ./modules/options.nix;
      scripts = ./modules/nixos/scripts.nix;
      cftunnel = ./modules/nixos/cftunnel.nix;
      tailscale-serve = ./modules/nixos/tailscale-serve.nix;
      service-target = ./modules/nixos/service-target.nix;
      rclone-sync = ./modules/nixos/rclone-sync.nix;
      nix-settings = ./modules/nixos/nix-settings.nix;
    };

    homeManagerModules = {
      default = ./modules/home;
      options = ./modules/home-options.nix;
      shell = ./modules/home/shell.nix;
      dev = ./modules/home/dev.nix;
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

    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        docs = pkgs.stdenv.mkDerivation {
          name = "machines-docs";
          src = ./docs;
          nativeBuildInputs = [pkgs.mdbook];
          buildPhase = "mdbook build";
          installPhase = "cp -r book $out";
        };
      }
    );

    apps = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        docs-serve = {
          type = "app";
          meta.description = "Serve the machines documentation locally with live reload";
          program = let
            serve = pkgs.writeShellApplication {
              name = "docs-serve";
              runtimeInputs = [pkgs.mdbook];
              text = ''
                cd ${./docs}
                mdbook serve --open
              '';
            };
          in "${serve}/bin/docs-serve";
        };
      }
    );

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
              pkgs.mdbook
              deploy-rs.packages.${system}.default
            ];
        };
      }
    );
  };
}
