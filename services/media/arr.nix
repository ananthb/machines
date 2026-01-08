{
  config,
  username,
  ...
}:
{
  imports = [ ../warp.nix ];

  # Radarr
  services.radarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };
  systemd.services.radarr = {
    serviceConfig.UMask = "0002";
    after = [ "postgresql.service" ];
    wants = [ "qbittorrent.service" ];
  };

  # Sonarr
  services.sonarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };
  systemd.services.sonarr = {
    serviceConfig.UMask = "0002";
    after = [ "postgresql.service" ];
    wants = [ "postgresql.service" ];
  };

  # Prowlarr
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.prowlarr = {
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

  # Jellyseerr
  services.jellyseerr.enable = true;
  systemd.services.jellyseerr.environment = {
    DB_TYPE = "postgres";
    DB_SOCKET_PATH = "/var/run/postgresql";
    DB_USER = "jellyseerr";
    DB_NAME = "jellyseerr";
  };
  networking.firewall.allowedTCPPorts = [ 5055 ];

  # Media group membership
  users.groups.media.members = [
    username
    "radarr"
    "sonarr"
  ];

  # PostgreSQL databases
  services.postgresql = {
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

  # Prometheus exporters
  services.prometheus.exporters.exportarr-radarr = {
    enable = true;
    url = "http://localhost:7878";
    port = 9708;
    apiKeyFile = config.sops.secrets."arr_apis/radarr".path;
  };

  services.prometheus.exporters.exportarr-sonarr = {
    enable = true;
    url = "http://localhost:8989";
    port = 9709;
    apiKeyFile = config.sops.secrets."arr_apis/sonarr".path;
  };

  services.prometheus.exporters.exportarr-prowlarr = {
    enable = true;
    url = "http://localhost:9696";
    port = 9710;
    apiKeyFile = config.sops.secrets."arr_apis/prowlarr".path;
  };

  # Secrets
  sops.secrets."arr_apis/radarr".mode = "0444";
  sops.secrets."arr_apis/sonarr".mode = "0444";
  sops.secrets."arr_apis/prowlarr".mode = "0444";
}
