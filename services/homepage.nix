{
  config,
  ...
}:
let
  vs = config.vault-secrets.secrets;
in
{
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
    environmentFiles = [ "${vs.homepage}/environment" ];
    services = [
      {
        "Media" = [
          {
            "Jellyfin (IPv6 only)" = {
              icon = "jellyfin";
              description = "Media Server";
              href = "https://tv.kedi.dev";
              siteMonitor = "https://tv.kedi.dev";
              widget = {
                type = "jellyfin";
                url = "http://localhost:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
                enableBlocks = true;
                enableNowPlaying = true;
                enableMediaControl = false;
              };
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
              widget = {
                type = "jellyseerr";
                url = "http://localhost:5055";
                key = "{{HOMEPAGE_VAR_JELLYSEERR_API_KEY}}";
              };
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
              widget = {
                type = "immich";
                url = "http://localhost:2283";
                key = "{{HOMEPAGE_VAR_IMMICH_API_KEY}}";
                version = 2;
              };
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
                version = 2;
              };
            };
          }
          {
            "Vaultwarden" = {
              icon = "vaultwarden";
              description = "Password Manager";
              href = "https://vault.kedi.dev";
              siteMonitor = "https://vault.kedi.dev";
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
                  widget = {
                    type = "homeassistant";
                    url = "http://localhost:8123";
                    key = "{{HOMEPAGE_VAR_HA_6A_TOKEN}}";
                  };
                };
              }
              {
                "Adguard Home" = {
                  icon = "adguard-home";
                  description = "Network-wide Ad Blocker";
                  href = "https://atlantis.tail42937.ts.net/adguard-home";
                  widget = {
                    type = "adguard";
                    url = "http://atlantis.local:8080";
                    username = "{{HOMEPAGE_VAR_ADGUARD_USERNAME}}";
                    password = "{{HOMEPAGE_VAR_ADGUARD_PASSWORD}}";
                  };
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
                  widget = {
                    type = "homeassistant";
                    url = "http://stargazer:8123";
                    key = "{{HOMEPAGE_VAR_HA_T1_TOKEN}}";
                  };
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
                "Upptime" = {
                  icon = "mdi-arrow-up-circle";
                  description = "Uptime Status Website";
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
                  href = "http://endeavour:8080";
                  widget = {
                    type = "qbittorrent";
                    url = "http://localhost:8080";
                  };
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

  vault-secrets.secrets.homepage = {
    services = [ "homepage-dashboard" ];
  };

  my-services.kediTargets.homepage-dashboard = true;

  systemd.services.homepage-dashboard = {
    partOf = [ "kedi.target" ];
  };

}
