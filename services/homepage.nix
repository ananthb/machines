{ config, ... }:
{
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    allowedHosts = "apps.kedi.dev,[fdc0:6625:5195::50]:8082,10.15.16.50:8082";
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
              widget = {
                type = "jellyfin";
                url = "http://enterprise.local:8096";
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
            };
          }
          {
            "Wallabag" = {
              icon = "wallabag";
              description = "Read-it-later";
              href = "https://wallabag.kedi.dev";
            };
          }
          {
            "Miniflux" = {
              icon = "miniflux";
              description = "RSS Feed Reader";
              href = "https://miniflux.kedi.dev";
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
            };
          }
          {
            "Immich" = {
              icon = "immich";
              description = "Photo & Video Library";
              href = "https://immich.kedi.dev";
              widget = {
                type = "immich";
                url = "http://enterprise.local:2283";
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
            };
          }
          {
            "Mealie" = {
              icon = "mealie";
              description = "Recipes & Meal Planner";
              href = "https://mealie.kedi.dev";
              widget = {
                type = "mealie";
                url = "https://mealie.kedi.dev";
                key = "{{HOMEPAGE_VAR_MEALIE_API_KEY}}";
              };
            };
          }
          {
            "Open WebUI" = {
              icon = "open-webui";
              description = "Large Language Model (LLM) inference";
              href = "https://open-webui.kedi.dev";
            };
          }
          {
            "Radicale" = {
              icon = "radicale";
              description = "Contacts, Calendars, & Tasks";
              href = "https://radicale.kedi.dev";
            };
          }
          {
            "Vaultwarden" = {
              icon = "vaultwarden";
              description = "Password Manager";
              href = "https://vault.kedi.dev";
            };
          }
        ];
      }
      {
        "Arr" = [
          {
            "Jellyseerr" = {
              icon = "jellyseerr";
              description = "Watch requests";
              href = "http://endeavour:5055";
            };
          }
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
              href = "http://enterprise:8080";
            };
          }
        ];
      }
      {
        "Internal" = [
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
          {
            "Adguard Home (6A)" = {
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
    ];
  };

  sops.templates."homepage-dashboard.env" = {
    content = ''
      HOMEPAGE_VAR_ADGUARD_USERNAME=${config.sops.placeholder."adguard-home/username"}
      HOMEPAGE_VAR_ADGUARD_PASSWORD=${config.sops.placeholder."adguard-home/password"}
      HOMEPAGE_VAR_IMMICH_API_KEY=${config.sops.placeholder."immich/admin_api_key"}
      HOMEPAGE_VAR_JELLYFIN_API_KEY=${config.sops.placeholder."jellyfin/api_key"}
      HOMEPAGE_VAR_MEALIE_API_KEY=${config.sops.placeholder."mealie/api_key"}
    '';
  };

  sops.secrets = {
    "adguard-home/username" = { };
    "adguard-home/password" = { };
    "immich/admin_api_key" = { };
    "jellyfin/api_key" = { };
    "mealie/api_key" = { };
  };
}
