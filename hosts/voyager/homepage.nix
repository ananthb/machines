{ config, ... }:

{
  services = {
    homepage-dashboard = {
      enable = true;
      listenPort = 16160;
      environmentFile = config.sops.templates."homepage-dashboard/env".path;
      widgets = [
        {
          "openweathermap" = {
            label = "Weather";
            units = "metric";
            provider = "openweathermap";
            apiKey = "{{HOMEPAGE_VAR_OPENWEATHERMAP_API_KEY}}";
            cache = 5; # minutes
          };
        }
      ];
      # See https://gethomepage.dev/configs/settings
      settings = {
        title = "Ananth's Hosted Emporium";
        description = "Ananth self-hosts services for (some) people";
        headerStyle = "clean";
        target = "_blank";
        layout = [
          {
            "Our Cloud" = {
              style = "row";
              columns = 3;
            };
          }
          {
            "Their Cloud" = { };
          }
          {
            "Backend" = { };
          }
          {
            "Arr" = {
              style = "row";
              columns = "4";
            };
          }
        ];
      };

      services = [
        {
          "Our Cloud" = [
            {
              "Jellyfin" = {
                description = ''
                  Watch movies and TV shows. Listen to music.
                  Login with your assigned username and password'';
                href = "{{HOMEPAGE_VAR_JELLYFIN_HREF}}";
                icon = "jellyfin";
                widget = {
                  type = "jellyfin";
                  url = "http://endeavour:8096";
                  key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
                  enableBlocks = true;
                  enableMediaControl = false;
                };
              };
            }
            {
              "Immich" = {
                description = ''
                  View and share photos and videos. 
                                  Set up automatic backups from your phone. 
                                  Sign in with Google'';
                href = "{{HOMEPAGE_VAR_IMMICH_HREF}}";
                icon = "immich";
                widget = {
                  type = "immich";
                  url = "{{HOMEPAGE_VAR_IMMICH_HREF}}";
                  key = "{{HOMEPAGE_VAR_IMMICH_API_KEY}}";
                  version = 2;
                };
              };
            }
            {
              "Seafile" = {
                description = ''
                  Upload your files. Organise them into libraries.
                  Share files with people.
                  Sign in with Google.
                '';
                icon = "files";
                href = "{{HOMEPAGE_VAR_SEAFILE_HREF}}";
              };
            }
          ];
        }
        {
          "Arr" = [
            {
              "qBittorrent" = {
                href = "http://endeavour:8080";
                description = "Download torrents.";
                icon = "qbittorrent";
                widget = {
                  type = "qbittorrent";
                  url = "http://endeavour:8080";
                };
              };
            }
            {
              "Radarr" = {
                href = "http://endeavour:7878";
                description = "Manage the movie library.";
                icon = "radarr";
                widget = {
                  type = "radarr";
                  url = "http://endeavour:7878";
                  key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
                };
              };
            }
            {
              "Sonarr" = {
                href = "http://endeavour:8989";
                description = "Manage the TV show library.";
                icon = "sonarr";
                widget = {
                  type = "sonarr";
                  url = "http://endeavour:8989";
                  key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
                };
              };
            }
            {
              "Prowlarr" = {
                href = "http://endeavour:9696";
                description = "Query torrent indexers.";
                icon = "prowlarr";
                widget = {
                  type = "prowlarr";
                  url = "http://endeavour:9696";
                  key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
                };
              };
            }
          ];
        }
        {
          "Their Cloud" = [
            {
              "Actual Budget" = {
                description = ''
                  Double-entry bookkeeping software to manage personal budgets.
                                  Sign in with Google.'';
                href = "https://actual.kedi.dev";
                icon = "actual-budget";
              };
            }
            {
              "The Lounge" = {
                description = ''
                  IRC application on the web.
                                  Sign in with assigned username and password.'';
                href = "https://irc.kedi.dev";
                icon = "thelounge";
              };
            }
          ];
        }
        {
          "Backend" = [
            {
              "Grafana" = {
                description = "Monitor services and manage alerts.";
                href = "https://mon.tail42937.ts.net";
                icon = "grafana";
              };
            }
            {
              "Victoria Metrics" = {
                href = "http://voyager:8428";
                description = "Collect metrics from everything.";
                icon = "victoriametrics";
              };
            }
          ];
        }
      ];
    };

    tsnsrv.services.home.urlParts.host = "127.0.0.1";
    tsnsrv.services.home.urlParts.port = 16160;
  };

  systemd.services.homepage-dashboard.serviceConfig.BindReadOnlyPaths = "/srv";

  systemd.services.tsnsrv-home.wants = [ "homepage-dashboard.service" ];
  systemd.services.tsnsrv-home.after = [ "homepage-dashboard.service" ];

  sops.secrets = {
    "keys/jellyfin_api/homepage-dashboard" = { };
    "keys/immich_api/homepage-dashboard" = { };
    "keys/openweathermap_api/homepage-dashboard" = { };
    "keys/prowlarr_api" = { };
    "keys/radarr_api" = { };
    "keys/sonarr_api" = { };
  };
  sops.templates."homepage-dashboard/env" = {
    content = ''
      HOMEPAGE_VAR_JELLYFIN_API_KEY="${config.sops.placeholder."keys/jellyfin_api/homepage-dashboard"}"
      HOMEPAGE_VAR_IMMICH_API_KEY="${config.sops.placeholder."keys/immich_api/homepage-dashboard"}"
      HOMEPAGE_VAR_PROWLARR_API_KEY="${config.sops.placeholder."keys/prowlarr_api"}"
      HOMEPAGE_VAR_RADARR_API_KEY="${config.sops.placeholder."keys/radarr_api"}"
      HOMEPAGE_VAR_SONARR_API_KEY="${config.sops.placeholder."keys/sonarr_api"}"
      HOMEPAGE_ALLOWED_HOSTS="home.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      HOMEPAGE_VAR_IMMICH_HREF="https://imm.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      HOMEPAGE_VAR_JELLYFIN_HREF="https://tv.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      HOMEPAGE_VAR_SEAFILE_HREF="https://sf.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      HOMEPAGE_VAR_OPENWEATHERMAP_API_KEY="${
        config.sops.placeholder."keys/openweathermap_api/homepage-dashboard"
      }"
    '';
  };
}
