{ config, ... }:

{
  services = {
    homepage-dashboard = {
      enable = true;
      listenPort = 16160;
      environmentFile = config.sops.templates."homepage-dashboard/env".path;
      widgets = [
        {
          resources = {
            cpu = true;
            disk = "/srv";
            memory = true;
          };
        }
      ];
      settings = {
        title = "Ananth's Hosted Emporium";
        description = "Ananth self-hosts services for (some) people";
      };

      services = [
        {
          "Our Cloud" = [
            {
              "Jellyfin" = {
                description = "Login with your assigned username and password";
                href = "{{HOMEPAGE_VAR_JELLYFIN_HREF}}";
                widget = {
                  type = "jellyfin";
                  key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
                  enableBlocks = true;
                };
              };
            }
            {
              "Jellyseerr" = {
                description = "Same login as Jellyfin";
                href = "{{HOMEPAGE_VAR_JELLYSEERR_HREF}}";
                widget = {
                  type = "jellyseerr";
                  url = "{{HOMEPAGE_VAR_JELLYSEERR_HREF}}";
                  key = "{{HOMEPAGE_VAR_JELLYSEERR_API_KEY}}";
                };
              };
            }
            {
              "Immich" = {
                description = "Sign in with Google";
                href = "{{HOMEPAGE_VAR_IMMICH_HREF}}";
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
                description = "Access via Tailscale";
                href = "{{HOMEPAGE_VAR_COPYPARTY_HREF}}";
              };
            }
          ];
        }
        {
          "Their Cloud" = [
            {
              "Actual Budget" = {
                description = "Sign in with Google";
                href = "https://actual.kedi.dev";
              };
            }
            {
              "The Lounge" = {
                description = "https://irc.kedi.dev";
                href = "_blank";
              };
            }
          ];
        }
        {
          "Arr" = [
            {
              "qBittorrent" = {
                href = "http://endeavour:9091";
                widget = {
                  type = "qbittorrent";
                  url = "http://localhost:9091";
                  enableLeechProgress = true;
                };
              };
            }
            {
              "Radarr" = {
                href = "http://endeavour:7878";
                widget = {
                  type = "radarr";
                  url = "http://localhost:7878";
                  key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
                };
              };
            }
            {
              "Sonarr" = {
                href = "http://endeavour:8989";
                widget = {
                  type = "sonarr";
                  url = "http://localhost:8989";
                  key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
                };
              };
            }
            {
              "Prowlarr" = {
                href = "http://endeavour:9696";
                widget = {
                  type = "prowlarr";
                  url = "http://localhost:9696";
                  key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
                };
              };
            }
          ];
        }
        {
          "Backend" = [
            {
              "Grafana" = {
                description = "Login via Tailscale";
                href = "https://mon.tail42937.ts.net";
              };
            }
            {
              "Victoria Metrics" = {
                href = "http://endeavour:8428";
                widget = {
                  type = "prometheus";
                  url = "http://localhost:8428";
                };
              };
            }
          ];
        }
      ];
    };

    tsnsrv.services.home.urlParts.host = "127.0.0.1";
    tsnsrv.services.home.urlParts.port = 16160;
  };

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
