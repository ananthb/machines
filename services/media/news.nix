{
  config,
  ...
}:
{
  imports = [
    ../monitoring/postgres.nix
  ];

  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets."miniflux/admin_creds".path;
    config = {
      LISTEN_ADDR = "[::]:8088";
      BASE_URL = "https://miniflux.kedi.dev";
      FETCH_YOUTUBE_WATCH_TIME = "1";
      METRICS_COLLECTOR = "1";
      DISABLE_LOCAL_AUTH = "1";
      OAUTH2_USER_CREATION = "1";
      OAUTH2_CLIENT_ID_FILE = config.sops.secrets."gcloud/oauth/self-hosted_clients/id".path;
      OAUTH2_CLIENT_SECRET_FILE = config.sops.secrets."gcloud/oauth/self-hosted_clients/secret".path;
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://accounts.google.com";
      OAUTH2_PROVIDER = "google";
      OAUTH2_REDIRECT_URL = "https://miniflux.kedi.dev/oauth2/oidc/callback";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      autoEscape = true;
      autoUpdate.enable = true;

      volumes = {
        wallabag-data = { };
        wallabag-images = { };
      };

      containers.wallabag.containerConfig = {
        name = "wallabag";
        image = "docker.io/wallabag/wallabag:latest";
        volumes = [
          "${volumes.wallabag-data.ref}:/var/www/wallabag/data"
          "${volumes.wallabag-images.ref}:/var/www/wallabag/web/assets/images"
        ];
        publishPorts = [ "8085:80" ];
        environmentFiles = [ config.sops.templates."wallabag/env".path ];
      };
    };

  networking.firewall = {
    allowedTCPPorts = [
      8085 # wallabag
      8088 # miniflux
    ];
    interfaces.podman1.allowedTCPPorts = [
      5432 # postgres
    ];
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      host wallabag wallabag 10.98.0.0/16 md5
    '';
    ensureDatabases = [
      "wallabag"
    ];
    ensureUsers = [
      {
        name = "wallabag";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  sops.templates."wallabag/env".content = ''
    SYMFONY__ENV__DOMAIN_NAME=https://wallabag.kedi.dev
    SYMFONY__ENV__DATABASE_DRIVER=pdo_pgsql
    SYMFONY__ENV__DATABASE_HOST=10.98.0.1
    SYMFONY__ENV__DATABASE_PORT=5432
    SYMFONY__ENV__DATABASE_NAME=wallabag
    SYMFONY__ENV__DATABASE_USER=${config.sops.placeholder."wallabag/db/username"}
    SYMFONY__ENV__DATABASE_PASSWORD=${config.sops.placeholder."wallabag/db/password"}
    SYMFONY__ENV__DATABASE_CHARSET=utf8
    SYMFONY__ENV__MAILER_HOST=${config.sops.placeholder."email/smtp/host"}
    SYMFONY__ENV__MAILER_USER=${config.sops.placeholder."email/smtp/username"}
    SYMFONY__ENV__MAILER_PASSWORD=${config.sops.placeholder."email/smtp/password"}
    SYMFONY__ENV__FROM_EMAIL=${config.sops.placeholder."email/from/wallabag"}
  '';

  sops.secrets = {
    "email/from/wallabag" = { };
    "gcloud/oauth/self-hosted_clients/id".mode = "0444";
    "gcloud/oauth/self-hosted_clients/secret".mode = "0444";
    "miniflux/admin_creds" = { };
    "wallabag/db/username" = { };
    "wallabag/db/password" = { };
  };
}
