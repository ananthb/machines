{ }:
{
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    allowedHosts = "apps.kedi.dev";
    services = [
      {
        "Productivity" = [
          {
            "Seafile" = {
              description = "Files & Collaboration";
              href = "https://seafile.kedi.dev";
            };
          }
          {
            "Immich" = {
              description = "Photo & Video Library";
              href = "https://immich.kedi.dev";
            };
          }
          {
            "Mealie" = {
              description = "Recipes & Meal Planner";
              href = "https://mealie.kedi.dev";
            };
          }
          {
            "Open WebUI" = {
              description = "Large Language Model (LLM) inference";
              href = "https://open-webui.kedi.dev";
            };
          }
        ];
      }
      {
        "Organisation" = [
          {
            "Radicale" = {
              description = "Contacts, Calendars, & Tasks";
              href = "https://radicale.kedi.dev";
            };
          }
          {
            "Actual" = {
              description = "Personal Budget Tracker";
              href = "https://actual.kedi.dev";
            };
          }
          {
            "Vaultwarden" = {
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
              description = "Watch requests";
              href = "http://voyager:5055";
            };
          }
          {
            "Radarr" = {
              description = "Movies";
              href = "http://endeavour:7878";
            };

          }
          {
            "Sonarr" = {
              description = "TV Shows";
              href = "http://endeavour:8989";
            };
          }
          {
            "Prowlarr" = {
              description = "Indexer";
              href = "http://endeavour:9696";
            };
          }
          {
            "qBittorrent" = {
              description = "Torrent downloader";
              href = "http://endeavour:8080";
            };
          }
        ];
      }
      {
        "Internal" = [
          {
            "Grafana" = {
              description = "Monitoring";
              href = "https://mon.tail42937.ts.net";
            };
          }
          {
            "VictoriaMetrics" = {
              description = "Metrics";
              href = "http://voyager:8428";
            };
          }
          {
            "Upptime" = {
              description = "Uptime Status Website";
              href = "uptime.kedi.dev";
            };
          }
        ];
      }
    ];
  };
}
