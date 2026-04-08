# Homepage dashboard configuration for kedi-cloud-garnix1.
{config, ...}: let
  vs = config.vault-secrets.secrets;
in {
  users.groups."homepage-secrets" = {};

  services.homepage-dashboard = {
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

  vault-secrets.secrets.homepage = {
    services = ["homepage-dashboard"];
    group = "homepage-secrets";
  };

  my-services.kediTargets.homepage-dashboard = true;

  systemd.services.homepage-dashboard = {
    partOf = ["kedi.target"];
    serviceConfig.SupplementaryGroups = ["homepage-secrets"];
  };

  systemd.services.homepage-secrets.serviceConfig.UMask = "0027";
}
