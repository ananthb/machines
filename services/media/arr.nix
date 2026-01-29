{
  config,
  username,
  ...
}:
{
  imports = [
    ../warp.nix
    ../monitoring/postgres.nix
  ];

  # Media group membership
  users.groups.media.members = [
    username
    "radarr"
    "sonarr"
    "cross-seed"
  ];

  # Services
  services = {
    radarr = {
      enable = true;
      group = "media";
      openFirewall = true;
    };

    sonarr = {
      enable = true;
      group = "media";
      openFirewall = true;
    };

    prowlarr = {
      enable = true;
      openFirewall = true;
    };

    jellyseerr.enable = true;

    cross-seed = {
      enable = true;
      group = "media";
    };

    postgresql = {
      enable = true;
      ensureDatabases = [
        "radarr-main"
        "radarr-log"
        "sonarr-main"
        "sonarr-log"
        "prowlarr-main"
        "prowlarr-log"
        "jellyseerr"
      ];
      ensureUsers = [
        {
          name = "radarr";
          ensureClauses.login = true;
        }
        {
          name = "sonarr";
          ensureClauses.login = true;
        }
        {
          name = "prowlarr";
          ensureClauses.login = true;
        }
        {
          name = "jellyseerr";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    prometheus.exporters = {
      exportarr-radarr = {
        enable = true;
        url = "http://localhost:7878";
        port = 9708;
        apiKeyFile = config.sops.secrets."arr_apis/radarr".path;
      };

      exportarr-sonarr = {
        enable = true;
        url = "http://localhost:8989";
        port = 9709;
        apiKeyFile = config.sops.secrets."arr_apis/sonarr".path;
      };

      exportarr-prowlarr = {
        enable = true;
        url = "http://localhost:9696";
        port = 9710;
        apiKeyFile = config.sops.secrets."arr_apis/prowlarr".path;
      };
    };
  };

  systemd.services = {
    radarr = {
      serviceConfig.UMask = "0002";
      after = [ "postgresql.service" ];
      wants = [ "qbittorrent.service" ];
    };

    sonarr = {
      serviceConfig.UMask = "0002";
      after = [ "postgresql.service" ];
      wants = [ "postgresql.service" ];
    };

    prowlarr = {
      after = [
        "postgresql.service"
        "radarr.service"
        "sonarr.service"
      ];
      wants = [
        "postgresql.service"
        "radarr.service"
        "sonarr.service"
      ];
    };

    jellyseerr.environment = {
      DB_TYPE = "postgres";
      DB_SOCKET_PATH = "/var/run/postgresql";
      DB_USER = "jellyseerr";
      DB_NAME = "jellyseerr";
    };

    cross-seed = {
      after = [ "qbittorrent.service" ];
      wants = [ "qbittorrent.service" ];
      serviceConfig.UMask = "0002";
    };
  };

  # Secrets
  sops.secrets = {
    "arr_apis/radarr".mode = "0444";
    "arr_apis/sonarr".mode = "0444";
    "arr_apis/prowlarr".mode = "0444";
  };
}
