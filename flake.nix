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

    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";

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
      url = "github:Overclock-Validator/mithril";
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
    openwrt-imagebuilder,
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

    openwrtRouters = {
      intrepid = "intrepid.tail42937.ts.net";
      ds9 = "ds9.tail42937.ts.net";
      atlantis = "atlantis.tail42937.ts.net";
    };

    pkgsCalibreFor = system: import nixpkgs-calibre {inherit system;};

    calibreOverlay = final: _: {
      inherit ((pkgsCalibreFor final.stdenv.hostPlatform.system)) calibre;
    };

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
            {
              nixpkgs.overlays = [
                calibreOverlay
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

    packages = let
      openwrtPackages = let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        openwrt = import ./openwrt {inherit openwrt-imagebuilder pkgs;};
      in
        nixpkgs.lib.mapAttrs' (name: _:
          nixpkgs.lib.nameValuePair "openwrt-${name}" openwrt.images.${name})
        openwrtRouters;
    in
      forAllSystems (system:
        if system == "x86_64-linux"
        then openwrtPackages
        else {});

    apps.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      vaultAddr = "http://endeavour:8200";

      # Config files to back up from each router
      configFiles = [
        "dhcp"
        "dropbear"
        "firewall"
        "network"
        "system"
        "wireless"
        "tailscale"
        "sqm"
        "dawn"
        "nginx"
        "uhttpd"
        "adblock-fast"
        "adguardhome"
        "https-dns-proxy"
        "prometheus-node-exporter-lua"
        "luci"
        "rpcd"
        "umdns"
        "mdns_repeater"
        "mwan3"
      ];

      # Extra non-UCI files to back up
      extraFiles = {
        atlantis = [
          "/etc/adguardhome/adguardhome.yaml"
          "/etc/nginx/nginx.conf"
          "/etc/nginx/conf.d/adguardhome.locations"
        ];
        intrepid = [];
        ds9 = [];
      };

      mkBackupApp = name: host:
        nixpkgs.lib.nameValuePair "openwrt-backup-${name}" {
          type = "app";
          program = nixpkgs.lib.getExe (pkgs.writeShellApplication {
            name = "openwrt-backup-${name}";
            runtimeInputs = [pkgs.openssh pkgs.vault pkgs.jq];
            text = ''
              : "''${VAULT_ADDR:=${vaultAddr}}"
              export VAULT_ADDR
              echo "Backing up ${name} configs to Vault..."

              declare -A configs
              for f in ${builtins.concatStringsSep " " configFiles}; do
                content=$(ssh "root@${host}" "cat /etc/config/$f 2>/dev/null" || true)
                if [ -n "$content" ]; then
                  configs["config_$f"]="$content"
                fi
              done

              ${builtins.concatStringsSep "\n" (map (f: ''
                content=$(ssh "root@${host}" "cat ${f} 2>/dev/null" || true)
                if [ -n "$content" ]; then
                  key=$(echo "${f}" | tr '/' '_' | sed 's/^_//')
                  configs["$key"]="$content"
                fi
              '') (extraFiles.${name} or []))}

              # Build vault kv put command
              args=()
              for key in "''${!configs[@]}"; do
                args+=("$key=''${configs[$key]}")
              done

              vault kv put "kv/services/openwrt-${name}" "''${args[@]}"
              echo "Backed up ''${#configs[@]} config files to kv/services/openwrt-${name}"
            '';
          });
        };

      mkDeployApp = name: host:
        nixpkgs.lib.nameValuePair "deploy-openwrt-${name}" {
          type = "app";
          program = nixpkgs.lib.getExe (pkgs.writeShellApplication {
            name = "deploy-openwrt-${name}";
            runtimeInputs = [pkgs.openssh pkgs.vault pkgs.jq pkgs.findutils pkgs.nix];
            text = ''
              : "''${VAULT_ADDR:=${vaultAddr}}"
              export VAULT_ADDR

              WORK=$(mktemp -d)
              trap 'rm -rf "$WORK"' EXIT

              echo "Fetching ${name} configs from Vault..."
              vault kv get -format=json "kv/services/openwrt-${name}" \
                | jq -r '.data.data | to_entries[] | "\(.key)\t\(.value)"' \
                | while IFS=$'\t' read -r key value; do
                    # config_foo → etc/config/foo
                    # etc_nginx_nginx.conf → etc/nginx/nginx.conf
                    if [[ "$key" == config_* ]]; then
                      path="etc/config/''${key#config_}"
                    else
                      path=$(echo "$key" | tr '_' '/')
                    fi
                    mkdir -p "$WORK/$(dirname "$path")"
                    printf '%s' "$value" > "$WORK/$path"
                  done

              echo "Building OpenWrt image for ${name} with configs..."
              RESULT=$(nix build --impure --no-link --print-out-paths \
                --expr "(let openwrt = import ./openwrt {
                  openwrt-imagebuilder = builtins.getFlake \"github:astro/nix-openwrt-imagebuilder\";
                  pkgs = import (builtins.getFlake \"${nixpkgs.sourceInfo.url or "github:NixOS/nixpkgs/nixos-unstable"}\") { system = \"x86_64-linux\"; };
                }; in openwrt.buildWithFiles.${name} (builtins.path { path = \"$WORK\"; }))")

              IMAGE=$(find "$RESULT" -name '*-sysupgrade*' -not -name '*.manifest' | head -1)
              if [ -z "$IMAGE" ]; then
                echo "No sysupgrade image found in $RESULT"
                exit 1
              fi

              echo "Image: $IMAGE"
              echo "Copying to root@${host}..."
              scp "$IMAGE" "root@${host}:/tmp/sysupgrade.bin"
              echo ""
              echo "Flash with: ssh root@${host} sysupgrade -v /tmp/sysupgrade.bin"
            '';
          });
        };

      mkSetupVaultApp = name: _host:
        nixpkgs.lib.nameValuePair "openwrt-vault-setup-${name}" {
          type = "app";
          program = nixpkgs.lib.getExe (pkgs.writeShellApplication {
            name = "openwrt-vault-setup-${name}";
            runtimeInputs = [pkgs.vault];
            text = ''
              : "''${VAULT_ADDR:=${vaultAddr}}"
              export VAULT_ADDR

              echo "Creating Vault policy openwrt-${name}..."
              vault policy write "openwrt-${name}" - <<'POLICY'
              path "kv/metadata/services/openwrt-${name}" {
                capabilities = ["list"]
              }
              path "kv/metadata/services/openwrt-${name}/*" {
                capabilities = ["list"]
              }
              path "kv/data/services/openwrt-${name}" {
                capabilities = ["read"]
              }
              path "kv/data/services/openwrt-${name}/*" {
                capabilities = ["read"]
              }
              POLICY

              echo "Creating AppRole vault-secrets-endeavour-openwrt-${name}..."
              vault write "auth/approle/role/vault-secrets-endeavour-openwrt-${name}" \
                token_policies="vault-secrets-endeavour-openwrt-${name}" \
                token_ttl=1h \
                token_max_ttl=4h

              echo "Creating AppRole policy vault-secrets-endeavour-openwrt-${name}..."
              vault policy write "vault-secrets-endeavour-openwrt-${name}" - <<POLICY
              path "kv/metadata/services/openwrt-${name}" {
                capabilities = ["list"]
              }
              path "kv/metadata/services/openwrt-${name}/*" {
                capabilities = ["list"]
              }
              path "kv/data/services/openwrt-${name}" {
                capabilities = ["read"]
              }
              path "kv/data/services/openwrt-${name}/*" {
                capabilities = ["read"]
              }
              POLICY

              ROLE_ID=$(vault read -field=role_id "auth/approle/role/vault-secrets-endeavour-openwrt-${name}/role-id")
              SECRET_ID=$(vault write -field=secret_id -f "auth/approle/role/vault-secrets-endeavour-openwrt-${name}/secret-id")

              echo ""
              echo "AppRole created. Add to secrets/endeavour.yaml under approles:"
              echo "    openwrt-${name}: VAULT_ADDR=${vaultAddr} VAULT_ROLE_ID=$ROLE_ID VAULT_SECRET_ID=$SECRET_ID"
              echo ""
              echo "Then run: sops secrets/endeavour.yaml  (to encrypt)"
            '';
          });
        };
    in
      nixpkgs.lib.listToAttrs (
        (nixpkgs.lib.mapAttrsToList mkBackupApp openwrtRouters)
        ++ (nixpkgs.lib.mapAttrsToList mkDeployApp openwrtRouters)
        ++ (nixpkgs.lib.mapAttrsToList mkSetupVaultApp openwrtRouters)
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
