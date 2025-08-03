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
              };
            }
            {
              "Jellyseerr" = {
                description = "Same login as Jellyfin";
                href = "{{HOMEPAGE_VAR_JELLYSEERR_HREF}}";
              };
            }
            {
              "Immich" = {
                description = "Sign in with Google";
                href = "{{HOMEPAGE_VAR_IMMICH_HREF}}";
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

              };
            }
            {
              "Radarr" = {
                href = "http://endeavour:7878";
              };
            }
            {
              "Sonarr" = {
                href = "http://endeavour:8989";
              };
            }
            {
              "Prowlarr" = {
                href = "http://endeavour:9696";
              };
            }
          ];
        }
        {
          "Backend" = [
            {
              "Grafana" = {
                description = "Tailscale Login";
                href = "https://mon.tail42937.ts.net";
              };
            }
            {
              "Victoria Metrics" = {
                href = "http://endeavour:8428";
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

  sops.secrets."tsnsrv/nodes/homepage-dashboard" = { };
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
    '';
  };
}
