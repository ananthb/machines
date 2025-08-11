{ config, ... }:

{
  services = {
    homepage-dashboard = {
      enable = true;
      listenPort = 16160;
      environmentFile = config.sops.templates."homepage-dashboard/env".path;
      widgets = [ ]; # TODO: add weather
      # See https://gethomepage.dev/configs/settings
      settings = {
        title = "Ananth's Hosted Emporium";
        description = "Ananth self-hosts services for (some) people";
        headerStyle = "clean";
        target = "_blank";
        layout = {
          "Our Cloud" = {
            style = "row";
            columns = 4;
          };
          "Their Cloud" = { };
          "Backend" = { };
          "Arr" = {
            style = "row";
            columns = "4";
          };
        };
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
              "Jellyseerr" = {
                description = ''
                  Request specific movies and TV shows to download and add to Jellyfin.
                  Same login credentials as Jellyfin.
                '';
                href = "{{HOMEPAGE_VAR_JELLYSEERR_HREF}}";
                icon = "jellyseerr";
                widget = {
                  type = "jellyseerr";
                  url = "{{HOMEPAGE_VAR_JELLYSEERR_HREF}}";
                  key = "{{HOMEPAGE_VAR_JELLYSEERR_API_KEY}}";
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
              "Copyparty" = {
                description = ''
                  View and store files.
                                  Upload to your personal folder and to a server-wide public folder.
                                  Access by turning on Tailscale'';
                icon = "files";
                href = "{{HOMEPAGE_VAR_COPYPARTY_HREF}}";
              };
            }
          ];
        }
        {
          "Arr" = [
            {
              "transmission" = {
                href = "http://endeavour:9091";
                description = "Download torrents.";
                icon = "transmission";
                widget = {
                  type = "transmission";
                  url = "http://endeavour:9091";
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
                href = "http://endeavour:8428";
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
    "keys/jellyseerr_api" = { };
    "keys/jellyfin_api/homepage-dashboard" = { };
    "keys/immich_api/homepage-dashboard" = { };
    "keys/radarr_api" = { };
    "keys/sonarr_api" = { };
    "keys/prowlarr_api" = { };
    "tsnsrv/nodes/homepage-dashboard" = { };
  };
  sops.templates."homepage-dashboard/env" = {
    content = ''
      HOMEPAGE_ALLOWED_HOSTS="${config.sops.placeholder."tsnsrv/nodes/homepage-dashboard"}.${
        config.sops.placeholder."tsnsrv/tailnet"
      }"
      HOMEPAGE_VAR_IMMICH_HREF="https://${config.sops.placeholder."tsnsrv/nodes/immich"}.${
        config.sops.placeholder."tsnsrv/tailnet"
      }"
      HOMEPAGE_VAR_JELLYFIN_HREF="https://${config.sops.placeholder."tsnsrv/nodes/jellyfin"}.${
        config.sops.placeholder."tsnsrv/tailnet"
      }"
      HOMEPAGE_VAR_COPYPARTY_HREF="https://${config.sops.placeholder."tsnsrv/nodes/copyparty"}.${
        config.sops.placeholder."tsnsrv/tailnet"
      }"
      HOMEPAGE_VAR_JELLYSEERR_HREF="https://${config.sops.placeholder."tsnsrv/nodes/jellyseerr"}.${
        config.sops.placeholder."tsnsrv/tailnet"
      }"
      HOMEPAGE_VAR_JELLYFIN_API_KEY="${config.sops.placeholder."keys/jellyfin_api/homepage-dashboard"}"
      HOMEPAGE_VAR_JELLYSEERR_API_KEY="${config.sops.placeholder."keys/jellyseerr_api"}"
      HOMEPAGE_VAR_IMMICH_API_KEY="${config.sops.placeholder."keys/immich_api/homepage-dashboard"}"
      HOMEPAGE_VAR_RADARR_API_KEY="${config.sops.placeholder."keys/radarr_api"}"
      HOMEPAGE_VAR_SONARR_API_KEY="${config.sops.placeholder."keys/sonarr_api"}"
      HOMEPAGE_VAR_PROWLARR_API_KEY="${config.sops.placeholder."keys/prowlarr_api"}"
    '';
  };
}
