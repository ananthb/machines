{ config, ... }:

{
  services.jellyseerr.enable = true;

  systemd.services.jellyseerr.environment = {
    DB_TYPE = "postgres";
    DB_SOCKET_PATH = "/var/run/postgresql";
    DB_USER = "jellyseerr";
    DB_NAME = "jellyseerr";
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      autoEscape = true;
      autoUpdate.enable = true;

      volumes = {
        aphrodite_data = { };
        aphrodite_media = { };
        aphrodite_logs = { };
        aphrodite_static = { };
      };

      containers = {
        aphrodite = {
          containerConfig = {
            name = "aphrodite";
            image = "ghcr.io/jackkerouac/aphrodite:latest";
            autoUpdate = "registry";
            volumes = [
              "${volumes.aphrodite_data.ref}:/app/data"
              "${volumes.aphrodite_logs.ref}:/app/logs"
              "${volumes.aphrodite_media.ref}:/app/media"
              "${volumes.aphrodite_static.ref}:/app/api/static/originals"
            ];
            publishPorts = [ "8001:8000" ];
            environmentFiles = [ config.sops.templates."aphrodite/env".path ];
          };
          serviceConfig = {
            Restart = "on-failure";
          };
          unitConfig = {
            After = "postgresql.service redis-aphrodite.service";
            Wants = "postgresql.service redis-aphrodite.service";
          };
        };
      };
    };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      host aphrodite aphrodite 10.88.0.0/16 md5
    '';
    ensureDatabases = [
      "aphrodite"
      "jellyseerr"
    ];
    ensureUsers = [
      {
        name = "aphrodite";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
      {
        name = "jellyseerr";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  services.redis.servers.aphrodite = {
    enable = true;
    bind = "10.88.0.1";
    port = 6400;
    unixSocket = null;
    settings.protected-mode = "no";
  };

  networking.firewall.interfaces.podman0.allowedTCPPorts = [
    5432 # postgres
    6400 # redis-aphrodite
  ];

  sops.secrets = {
    "aphrodite/jellyfin/api_key" = { };
    "aphrodite/jellyfin/user_id" = { };
    "aphrodite/postgres/username" = { };
    "aphrodite/postgres/password" = { };
    "aphrodite/secret_key" = { };
  };

  sops.templates."aphrodite/env" = {
    content = ''
      # Database Configuration
      POSTGRES_HOST=host.containers.internal
      POSTGRES_DB=aphrodite
      POSTGRES_USER=${config.sops.placeholder."aphrodite/postgres/username"}
      POSTGRES_PASSWORD=${config.sops.placeholder."aphrodite/postgres/password"}
      POSTGRES_PORT=5432

      # Redis Configuration
      REDIS_URL=redis://host.containers.internal:6400/0}

      # Application Configuration
      API_HOST=0.0.0.0
      API_PORT=8000
      ENVIRONMENT=production
      SECRET_KEY=${config.sops.placeholder."aphrodite/secret_key"}

      # Network Configuration
      ALLOWED_HOSTS=*
      CORS_ORIGINS=*

      # Logging
      LOG_LEVEL=info
      LOG_FILE_PATH=/app/logs/aphrodite-v2.log
      DEBUG=false

      # Background Jobs
      CELERY_BROKER_URL=redis://host.containers.internal:6400/0}
      CELERY_RESULT_BACKEND=redis://host.containers.internal:6400/1}
      ENABLE_BACKGROUND_JOBS=true

      # Jellyfin Integration (configure via web interface)
      JELLYFIN_URL=http://10.15.16.124
      JELLYFIN_API_KEY=${config.sops.placeholder."aphrodite/jellyfin/api_key"}
      JELLYFIN_USER_ID=${config.sops.placeholder."aphrodite/jellyfin/user_id"}
    '';
  };

}
