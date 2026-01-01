{ ... }:
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
    services = [
      {
        "Productivity" = [
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
          {
            "Open WebUI" = {
              icon = "open-webui";
              description = "Large Language Model (LLM) inference";
              href = "https://open-webui.kedi.dev";
            };
          }
        ];
      }
      {
        "Organisation" = [
          {
            "Mealie" = {
              icon = "mealie";
              description = "Recipes & Meal Planner";
              href = "https://mealie.kedi.dev";
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
        ];
      }
    ];
  };
}
