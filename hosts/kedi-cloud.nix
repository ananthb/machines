# Garnix-hosted NixOS server running cloud-friendly services.
{
  config,
  garnix-lib,
  lib,
  pkgs,
  containerImages,
  ...
}: let
  vs = config.vault-secrets.secrets;
in {
  imports = [
    garnix-lib.nixosModules.garnix
    ./nixos-common.nix
  ];

  garnix.server = {
    enable = true;
    persistence = {
      enable = true;
      name = "kedi-cloud";
    };
  };

  sops = {
    defaultSopsFile = ../secrets/kedi-cloud.yaml;
    age.keyFile = "/var/garnix/keys/repo-key";
    # CF Access service token for reaching vault.kedi.dev through Cloudflare Access.
    # Decrypted by sops at boot; used by the local vault proxy below.
    secrets."cf-access-client-id" = {};
    secrets."cf-access-client-secret" = {};
  };

  # Local reverse proxy that injects CF Access headers when talking to Vault.
  # vault-secrets services connect to this instead of vault.kedi.dev directly.
  vault-secrets.vaultAddress = "http://localhost:8200";

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
      services = ["mealie"];
      group = "mealie";
    };

    homepage = {
      services = ["homepage-dashboard"];
      group = "homepage-secrets";
    };
  };

  systemd = {
    services = lib.mkMerge [
      # Make all vault-secrets services wait for the CF Access proxy
      (lib.mapAttrs' (
          name: _value:
            lib.nameValuePair "${name}-secrets" {
              requires = ["vault-cf-proxy.service"];
              after = ["vault-cf-proxy.service"];
            }
        )
        config.vault-secrets.secrets)
      {
        # Local caddy instance that injects CF Access headers for Vault.
        vault-cf-proxy = let
          caddyfileTemplate = pkgs.writeText "vault-cf-proxy-caddyfile" ''
            {
              admin off
            }
            :8200 {
              reverse_proxy https://vault.kedi.dev {
                header_up CF-Access-Client-Id {{CF_ID}}
                header_up CF-Access-Client-Secret {{CF_SECRET}}
              }
            }
          '';
        in {
          description = "CF Access proxy for Vault";
          wantedBy = ["multi-user.target"];
          wants = ["network-online.target"];
          after = ["network-online.target" "sops-install-secrets.service"];
          requires = ["sops-install-secrets.service"];
          serviceConfig = {
            ExecStart = toString [
              "${config.services.caddy.package}/bin/caddy"
              "run"
              "--config"
              "/run/vault-cf-proxy/Caddyfile"
            ];
            ExecStartPre = let
              script = pkgs.writeShellScript "vault-cf-proxy-config" ''
                CF_ID=$(cat ${config.sops.secrets."cf-access-client-id".path})
                CF_SECRET=$(cat ${config.sops.secrets."cf-access-client-secret".path})
                ${pkgs.gnused}/bin/sed \
                  -e "s|{{CF_ID}}|$CF_ID|" \
                  -e "s|{{CF_SECRET}}|$CF_SECRET|" \
                  ${caddyfileTemplate} > /run/vault-cf-proxy/Caddyfile
              '';
            in "!${script}";
            Restart = "on-failure";
            DynamicUser = true;
            RuntimeDirectory = "vault-cf-proxy";
          };
        };

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
      }
    ];

    tmpfiles.rules = [
      "Z /var/lib/mealie - mealie mealie - -"
    ];
  };

  services = {
    # Caddy reverse proxy — each subdomain gets its own virtual host on port 80
    caddy = {
      enable = true;
      virtualHosts = {
        "uptime.kedi.dev:80" = {
          extraConfig = "reverse_proxy localhost:3001";
        };
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
      };
    };

    uptime-kuma = {
      enable = true;
      settings = {
        HOST = "127.0.0.1";
        PORT = "3001";
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
      ensureDatabases = ["wallabag"];
      ensureUsers = [
        {
          name = "wallabag";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    mealie = {
      enable = true;
      listenAddress = "127.0.0.1";
      credentialsFile = "${vs.mealie}/environment";
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
                siteMonitor = "https://wallabag.kedi.dev";
              };
            }
            {
              "Miniflux" = {
                icon = "miniflux";
                description = "RSS Feed Reader";
                href = "https://miniflux.kedi.dev";
                siteMonitor = "https://miniflux.kedi.dev";
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
                siteMonitor = "https://actual.kedi.dev";
              };
            }
            {
              "Mealie" = {
                icon = "mealie";
                description = "Recipes & Meal Planner";
                href = "https://mealie.kedi.dev";
                siteMonitor = "https://mealie.kedi.dev";
                widget = {
                  type = "mealie";
                  url = "https://mealie.kedi.dev";
                  key = "{{HOMEPAGE_VAR_MEALIE_API_KEY}}";
                };
              };
            }
            {
              "Vaultwarden" = {
                icon = "vaultwarden";
                description = "Password Manager";
                href = "https://vaultwarden.kedi.dev";
                siteMonitor = "https://vaultwarden.kedi.dev";
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
                    href = "http://endeavour:8428";
                  };
                }
                {
                  "Uptime Kuma" = {
                    icon = "uptime-kuma";
                    description = "Uptime Monitor";
                    href = "https://uptime.kedi.dev";
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
            {
              "Books" = [
                {
                  "Calibre" = {
                    icon = "mdi-book-open-page-variant";
                    description = "Ebook Library";
                    href = "https://calibre.kedi.dev";
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

  networking.firewall = {
    allowedTCPPorts = [80];
    interfaces.podman0.allowedTCPPorts = [5432];
  };

  system.stateVersion = "25.05";
}
