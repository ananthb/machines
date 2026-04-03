# kedi-cloud-garnix1: Garnix-hosted NixOS server running cloud-friendly services.
{
  config,
  lib,
  pkgs,
  containerImages,
  ...
}: let
  vs = config.vault-secrets.secrets;
in {
  imports = [
    ./shared/garnix.nix
    ../services/monitoring/blackbox.nix
    ../services/monitoring/grafana.nix
    ../services/monitoring/probes.nix
    ../services/monitoring/victoriametrics.nix
  ];

  networking = {
    hostName = "kedi-cloud-garnix1";
    interfaces.eth0.ipv6.addresses = [
      {
        address = "2a01:4f9:c014:4cf0::1";
        prefixLength = 64;
      }
    ];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    firewall = {
      allowedTCPPorts = [80];
      interfaces.podman0.allowedTCPPorts = [5432];
    };
  };

  garnix.server.persistence = {
    enable = true;
    name = "kedi-cloud-garnix1";
  };

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
  ];

  sops.defaultSopsFile = ../secrets/kedi-cloud.yaml;

  vault-secrets.secrets = {
    actual.services = ["actual"];

    miniflux = {
      services = ["miniflux"];
      secretsKey = null;
      group = "news";
      extraScript = ''
        umask 0027
        printf '%s' "$MINIFLUX_ADMIN_CREDS" > "$secretsPath/admin_creds"
        printf '%s' "$GCLOUD_OAUTH_CLIENT_ID" > "$secretsPath/oauth_client_id"
        printf '%s' "$GCLOUD_OAUTH_CLIENT_SECRET" > "$secretsPath/oauth_client_secret"
      '';
    };

    wallabag = {
      services = ["wallabag"];
      group = "news";
    };

    mealie = {
      services = ["mealie" "mealie-backup"];
      group = "mealie";
    };

    homepage = {
      services = ["homepage-dashboard"];
      group = "homepage-secrets";
    };

    vaultwarden = {
      services = ["vaultwarden"];
      group = config.users.groups.vaultwarden.name;
    };
  };

  systemd = {
    services = lib.mkMerge [
      {
        actual = {
          serviceConfig.EnvironmentFile = "${vs.actual}/environment";
          environment = {
            ACTUAL_OPENID_DISCOVERY_URL = "https://accounts.google.com/.well-known/openid-configuration";
            ACTUAL_OPENID_SERVER_HOSTNAME = "https://actual.kedi.dev";
          };
        };

        miniflux.serviceConfig.SupplementaryGroups = ["news"];

        wallabag.serviceConfig.SupplementaryGroups = ["news"];

        mealie.serviceConfig = {
          DynamicUser = lib.mkForce false;
          SupplementaryGroups = ["mealie"];
        };

        homepage-dashboard.serviceConfig.SupplementaryGroups = ["homepage-secrets"];

        # --- Backup services ---

        "actual-backup" = {
          startAt = "daily";
          environment.KOPIA_CHECK_FOR_UPDATES = "false";
          preStart = "systemctl -q is-active actual.service && systemctl stop actual.service";
          script = ''
            backup_target="/var/lib/actual"
            snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

            trap '{
              rm -rf "$snapshot_target"
            }' EXIT

            ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target"
            ${config.my-scripts.kopia-backup} "$snapshot_target" "$backup_target"
          '';
          postStop = "systemctl start actual.service";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          path = [
            pkgs.coreutils
            pkgs.curl
            pkgs.kopia
            pkgs.systemd
          ];
        };

        "mealie-backup" = {
          startAt = "weekly";
          environment.KOPIA_CHECK_FOR_UPDATES = "false";
          script = ''
            set -uo pipefail

            backup_api_url="http://localhost:9000/api/admin/backups"

            http() {
              ${pkgs.httpie}/bin/http -A bearer -a "$MEALIE_BACKUP_API_KEY" \
                --check-status \
                --ignore-stdin \
                --timeout=10 \
                "$@"
            }

            # Delete all backups
            http GET "$backup_api_url" \
              | ${pkgs.jq}/bin/jq -r '.imports[].name' \
              | ${pkgs.findutils}/bin/xargs -I{} \
                ${pkgs.httpie}/bin/http -A bearer -a "$MEALIE_BACKUP_API_KEY" \
                  --check-status \
                  --ignore-stdin \
                  --timeout=10 \
                  DELETE "$backup_api_url/"{}

            # Create new backup
            http POST "$backup_api_url"

            # Upload new backup
            ${config.my-scripts.kopia-backup} /var/lib/mealie/backups
          '';
          serviceConfig = {
            User = "root";
            Type = "oneshot";
            EnvironmentFile = "${vs.mealie}/environment";
          };
          path = [
            pkgs.coreutils
            pkgs.curl
            pkgs.kopia
          ];
        };

        "miniflux-backup" = {
          startAt = "daily";
          environment.KOPIA_CHECK_FOR_UPDATES = "false";
          script = ''
            snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"
            dump_file="$snapshot_target/miniflux.dump"

            trap '{
              rm -rf "$snapshot_target"
            }' EXIT

            ${pkgs.sudo}/bin/sudo -u postgres \
              ${config.services.postgresql.package}/bin/pg_dump \
                -Fc miniflux > "$dump_file"

            ${config.my-scripts.kopia-backup} "$snapshot_target" "/var/lib/miniflux"
          '';
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          path = [
            pkgs.coreutils
            pkgs.curl
            pkgs.kopia
          ];
        };

        "wallabag-backup" = {
          startAt = "daily";
          environment.KOPIA_CHECK_FOR_UPDATES = "false";
          script = ''
            snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

            trap '{
              rm -rf "$snapshot_target"
            }' EXIT

            # Dump wallabag database
            ${pkgs.sudo}/bin/sudo -u postgres \
              ${config.services.postgresql.package}/bin/pg_dump \
                -Fc wallabag > "$snapshot_target/wallabag.dump"

            # Export podman volumes
            ${pkgs.podman}/bin/podman volume export wallabag-data \
              > "$snapshot_target/wallabag-data.tar"
            ${pkgs.podman}/bin/podman volume export wallabag-images \
              > "$snapshot_target/wallabag-images.tar"

            ${config.my-scripts.kopia-backup} "$snapshot_target" "/var/lib/wallabag"
          '';
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          path = [
            pkgs.coreutils
            pkgs.curl
            pkgs.kopia
          ];
        };

        "vaultwarden-backup" = {
          startAt = "daily";
          environment.KOPIA_CHECK_FOR_UPDATES = "false";
          preStart = "systemctl -q is-active vaultwarden.service && systemctl stop vaultwarden.service";
          script = ''
            backup_target="/var/lib/${config.systemd.services.vaultwarden.serviceConfig.StateDirectory}"
            snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"
            dump_file="$snapshot_target/db.dump"

            trap '{
              rm -rf "$snapshot_target"
            }' EXIT

            ${pkgs.sudo}/bin/sudo -u vaultwarden \
              ${config.services.postgresql.package}/bin/pg_dump \
                -Fc -U vaultwarden vaultwarden > "$dump_file"

            ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target"

            ${config.my-scripts.kopia-backup} "$snapshot_target" "$backup_target"
          '';
          postStop = "systemctl start vaultwarden.service";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          path = [
            pkgs.coreutils
            pkgs.curl
            pkgs.kopia
            pkgs.systemd
          ];
        };

        "postgresql-backup" = {
          startAt = "daily";
          environment.KOPIA_CHECK_FOR_UPDATES = "false";
          script = ''
            snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

            trap '{
              rm -rf "$snapshot_target"
            }' EXIT

            ${pkgs.sudo}/bin/sudo -u postgres \
              ${config.services.postgresql.package}/bin/pg_dumpall \
                > "$snapshot_target/all-databases.sql"

            ${config.my-scripts.kopia-backup} "$snapshot_target" "/var/lib/postgresql"
          '';
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          path = [
            pkgs.coreutils
            pkgs.curl
            pkgs.kopia
          ];
        };
      }
    ];

    tmpfiles.rules = [
      "Z /var/lib/mealie - mealie mealie - -"
    ];
  };

  services = {
    prometheus.exporters.node = {
      enable = true;
      openFirewall = true;
    };

    # Caddy reverse proxy — each subdomain gets its own virtual host on port 80
    caddy = {
      enable = true;
      virtualHosts = {
        "actual.kedi.dev:80" = {
          extraConfig = "reverse_proxy localhost:3002";
        };
        "miniflux.kedi.dev:80" = {
          extraConfig = "reverse_proxy localhost:8088";
        };
        "wallabag.kedi.dev:80" = {
          extraConfig = "reverse_proxy localhost:8085";
        };
        "mealie.kedi.dev:80" = {
          extraConfig = "reverse_proxy localhost:9000";
        };
        "kedi.dev:80" = {
          extraConfig = "reverse_proxy localhost:8802";
        };
        "metrics.kedi.dev:80" = {
          extraConfig = "reverse_proxy localhost:3000";
        };
        "vaultwarden.kedi.dev:80" = {
          extraConfig = "reverse_proxy localhost:8222";
        };
      };
    };

    actual = {
      enable = true;
      settings.port = 3002;
    };

    miniflux = {
      enable = true;
      adminCredentialsFile = "${vs.miniflux}/admin_creds";
      config = {
        LISTEN_ADDR = "[::]:8088";
        BASE_URL = "https://miniflux.kedi.dev";
        FETCH_YOUTUBE_WATCH_TIME = "1";
        METRICS_COLLECTOR = "1";
        DISABLE_LOCAL_AUTH = "1";
        OAUTH2_USER_CREATION = "1";
        OAUTH2_CLIENT_ID_FILE = "${vs.miniflux}/oauth_client_id";
        OAUTH2_CLIENT_SECRET_FILE = "${vs.miniflux}/oauth_client_secret";
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://accounts.google.com";
        OAUTH2_PROVIDER = "google";
        OAUTH2_REDIRECT_URL = "https://miniflux.kedi.dev/oauth2/oidc/callback";
      };
    };

    postgresql = {
      enable = true;
      enableTCPIP = true;
      authentication = ''
        host wallabag wallabag 10.0.0.0/8 md5
      '';
      ensureDatabases = ["wallabag" "vaultwarden"];
      ensureUsers = [
        {
          name = "wallabag";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
        {
          name = "vaultwarden";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = {
        DATABASE_URL = "postgresql://vaultwarden@/vaultwarden?host=/run/postgresql";
        ROCKET_ADDRESS = "::";
        ROCKET_PORT = 8222;
        ROCKET_LOG = "critical";
        INVITATIONS_ALLOWED = true;
        SIGNUPS_ALLOWED = false;
        DOMAIN = "https://vaultwarden.kedi.dev";
        PUSH_ENABLED = true;
        PUSH_IDENTITY_URI = "https://identity.bitwarden.eu";
        PUSH_RELAY_URI = "https://api.bitwarden.eu";
        SMTP_FROM = "vault@kedi.dev";
        SMTP_FROM_NAME = "KEDI Vaultwarden";
      };
      environmentFile = "${vs.vaultwarden}/environment";
    };

    mealie = {
      enable = true;
      listenAddress = "127.0.0.1";
      credentialsFile = "${vs.mealie}/environment";
      database.createLocally = true;
    };

    homepage-dashboard = {
      enable = true;
      listenPort = 8802;
      allowedHosts = "kedi.dev";
      settings = {
        title = "KEDI";
        description = "Self-hosted apps for the people";
        base = "https://kedi.dev";
        target = "_blank";
      };
      environmentFiles = ["${vs.homepage}/environment"];
      services = [
        {
          "Media" = [
            {
              "Jellyfin (IPv6 only)" = {
                icon = "jellyfin";
                description = "Media Server";
                href = "https://tv.kedi.dev";
                siteMonitor = "https://tv.kedi.dev";
              };
            }
            {
              "Jellyfin" = {
                icon = "jellyfin";
                description = "Media Server";
                href = "https://tv.tail42937.ts.net";
                siteMonitor = "https://tv.tail42937.ts.net";
              };
            }
            {
              "Jellyseerr" = {
                icon = "jellyseerr";
                description = "Watch requests";
                href = "https://seerr.kedi.dev";
                siteMonitor = "https://seerr.kedi.dev";
              };
            }
            {
              "Wallabag" = {
                icon = "wallabag";
                description = "Read-it-later";
                href = "https://wallabag.kedi.dev";
                siteMonitor = "http://localhost:8085";
              };
            }
            {
              "Miniflux" = {
                icon = "miniflux";
                description = "RSS Feed Reader";
                href = "https://miniflux.kedi.dev";
                siteMonitor = "http://localhost:8088";
                widget = {
                  type = "miniflux";
                  url = "http://localhost:8088";
                  key = "{{HOMEPAGE_VAR_MINIFLUX_API_KEY}}";
                };
              };
            }
          ];
        }
        {
          "Tools" = [
            {
              "Seafile" = {
                icon = "seafile";
                description = "Files & Collaboration";
                href = "https://seafile.kedi.dev";
                siteMonitor = "https://seafile.kedi.dev";
              };
            }
            {
              "Immich" = {
                icon = "immich";
                description = "Photo & Video Library";
                href = "https://immich.kedi.dev";
                siteMonitor = "https://immich.kedi.dev";
              };
            }
            {
              "Actual" = {
                icon = "actual-budget";
                description = "Personal Budget Tracker";
                href = "https://actual.kedi.dev";
                siteMonitor = "http://localhost:3002";
              };
            }
            {
              "Mealie" = {
                icon = "mealie";
                description = "Recipes & Meal Planner";
                href = "https://mealie.kedi.dev";
                siteMonitor = "http://localhost:9000";
                widget = {
                  type = "mealie";
                  version = 2;
                  url = "http://localhost:9000";
                  key = "{{HOMEPAGE_VAR_MEALIE_API_KEY}}";
                };
              };
            }
            {
              "Vaultwarden" = {
                icon = "vaultwarden";
                description = "Password Manager";
                href = "https://vaultwarden.kedi.dev";
                siteMonitor = "http://localhost:8222";
              };
            }
          ];
        }
        {
          "Homes" = [
            {
              "6A" = [
                {
                  "Home Assistant" = {
                    icon = "home-assistant";
                    description = "Home Automation";
                    href = "https://6a.kedi.dev";
                  };
                }
                {
                  "Adguard Home" = {
                    icon = "adguard-home";
                    description = "Network-wide Ad Blocker";
                    href = "https://atlantis.tail42937.ts.net/adguard-home";
                  };
                }
              ];
            }
            {
              "T1" = [
                {
                  "Home Assistant" = {
                    icon = "home-assistant";
                    description = "Home Automation";
                    href = "https://t1.kedi.dev";
                  };
                }
              ];
            }
          ];
        }
        {
          "Internal" = [
            {
              "Monitoring" = [
                {
                  "Grafana" = {
                    icon = "grafana";
                    description = "Monitoring";
                    href = "https://metrics.kedi.dev";
                  };
                }
                {
                  "VictoriaMetrics" = {
                    icon = "victoriametrics";
                    description = "Metrics";
                    href = "http://localhost:8428";
                  };
                }
              ];
            }
            {
              "Arr" = [
                {
                  "Radarr" = {
                    icon = "radarr";
                    description = "Movies";
                    href = "http://endeavour:7878";
                  };
                }
                {
                  "Sonarr" = {
                    icon = "sonarr";
                    description = "TV Shows";
                    href = "http://endeavour:8989";
                  };
                }
                {
                  "Prowlarr" = {
                    icon = "prowlarr";
                    description = "Indexer";
                    href = "http://endeavour:9696";
                  };
                }
                {
                  "qBittorrent" = {
                    icon = "qbittorrent";
                    description = "Torrent downloader";
                    href = "http://endeavour:18080";
                  };
                }
              ];
            }
          ];
        }
      ];
    };
  };

  users = {
    groups = {
      news = {};
      mealie = {};
      hass = {};
      "homepage-secrets" = {};
    };
    users.mealie = {
      isSystemUser = true;
      group = "mealie";
    };
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes;
  in {
    autoEscape = true;
    autoUpdate.enable = true;

    volumes = {
      wallabag-data = {};
      wallabag-images = {};
    };

    containers.wallabag.containerConfig = {
      name = "wallabag";
      image = containerImages.wallabag;
      volumes = [
        "${volumes.wallabag-data.ref}:/var/www/wallabag/data"
        "${volumes.wallabag-images.ref}:/var/www/wallabag/web/assets/images"
      ];
      publishPorts = ["8085:80"];
      environmentFiles = ["${vs.wallabag}/environment"];
    };
  };

  system.stateVersion = "25.05";
}
