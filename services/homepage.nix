{
  config,
  ...
}:
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8802;
    allowedHosts = "apps.kedi.dev";
    settings = {
      title = "KEDI Applications";
      description = "KEDI Server running apps for the people";
      base = "https://apps.kedi.dev";
      target = "_blank";
    };
    environmentFile = config.sops.templates."homepage-dashboard.env".path;
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
            "Radicale" = {
              icon = "radicale";
              description = "Contacts, Calendars, & Tasks";
              href = "https://radicale.kedi.dev";
              siteMonitor = "https://radicale.kedi.dev";
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
                  href = "https://mon.tail42937.ts.net";
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
        ];
      }
    ];
  };

  sops.templates."homepage-dashboard.env" = {
    content = ''
      HOMEPAGE_VAR_ADGUARD_USERNAME=${config.sops.placeholder."adguard-home/username"}
      HOMEPAGE_VAR_ADGUARD_PASSWORD=${config.sops.placeholder."adguard-home/password"}
      HOMEPAGE_VAR_HA_6A_TOKEN=${config.sops.placeholder."home-assistant/6a/access_token"}
      HOMEPAGE_VAR_HA_T1_TOKEN=${config.sops.placeholder."home-assistant/t1/access_token"}
      HOMEPAGE_VAR_IMMICH_API_KEY=${config.sops.placeholder."immich/admin_api_key"}
      HOMEPAGE_VAR_JELLYSEERR_API_KEY=${config.sops.placeholder."jellyseerr/api_key"}
      HOMEPAGE_VAR_JELLYFIN_API_KEY=${config.sops.placeholder."jellyfin/api_key"}
      HOMEPAGE_VAR_MEALIE_API_KEY=${config.sops.placeholder."mealie/api_key"}
      HOMEPAGE_VAR_MINIFLUX_API_KEY=${config.sops.placeholder."miniflux/api_key"}
    '';
  };

  sops.secrets = {
    "adguard-home/username" = { };
    "adguard-home/password" = { };
    "home-assistant/6a/access_token" = { };
    "home-assistant/t1/access_token" = { };
    "immich/admin_api_key" = { };
    "jellyseerr/api_key" = { };
    "jellyfin/api_key" = { };
    "mealie/api_key" = { };
    "miniflux/api_key" = { };
  };
}
