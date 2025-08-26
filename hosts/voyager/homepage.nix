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
              columns = "5";
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
            {
              "Open WebUI" = {
                description = ''
                  Converse with chat LLMs, search the web and feed the results to models for analysis,
                  and generate code with specialised models.
                '';
                icon = "open-webui";
                href = "{{HOMEPAGE_VAR_OPENWEBUI_HREF}}";
              };
            }
            {
              "Actual Budget" = {
                description = ''
                  Maintain personal and shared books of accounts.
                  Sign in with Google.'';
                href = "https://actual.kedi.dev";
                icon = "actual-budget";
              };
            }
          ];
        }
      ];
    };

    tsnsrv.services.home = {
      funnel = true;
      urlParts.host = "127.0.0.1";
      urlParts.port = 16160;
    };
  };

  systemd.services.homepage-dashboard.serviceConfig.BindReadOnlyPaths = "/srv";

  systemd.services.tsnsrv-home.wants = [ "homepage-dashboard.service" ];
  systemd.services.tsnsrv-home.after = [ "homepage-dashboard.service" ];

  sops.secrets = {
    "keys/openweathermap_api/homepage-dashboard" = { };
  };
  sops.templates."homepage-dashboard/env" = {
    content = ''
      HOMEPAGE_ALLOWED_HOSTS="home.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      HOMEPAGE_VAR_IMMICH_HREF="https://imm.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      HOMEPAGE_VAR_JELLYFIN_HREF="https://tv.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      HOMEPAGE_VAR_SEAFILE_HREF="https://sf.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      HOMEPAGE_VAR_OPENWEBUI_HREF="https://ai.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      HOMEPAGE_VAR_OPENWEATHERMAP_API_KEY="${
        config.sops.placeholder."keys/openweathermap_api/homepage-dashboard"
      }"
    '';
  };
}
