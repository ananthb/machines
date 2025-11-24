{ config, ... }:
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets."miniflux/admin_creds".path;
    config.LISTEN_ADDR = "[::]:8088";
    config.BASE_URL = "https://miniflux.kedi.dev";
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

      containers.wallabag = {
        containerConfig = {
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
    };

  networking.firewall.allowedTCPPorts = [ 8088 ];

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "wallabag" ];
    ensureUsers = [
      {
        name = "wallabag";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  sops.templates."wallabag/env" = {
    content = ''
      SYMFONY__ENV__DOMAIN_NAME=https://wallabag.kedi.dev
      SYMFONY__ENV__DATABASE_DRIVER=pdo_pgsql
      SYMFONY__ENV__DATABASE_HOST=<remote db's ip>
      SYMFONY__ENV__DATABASE_PORT=5432
      SYMFONY__ENV__DATABASE_NAME=wallabag
      SYMFONY__ENV__DATABASE_USER=${config.sops.placeholder."wallabag/db/username"}
      SYMFONY__ENV__DATABASE_PASSWORD=${config.sops.placeholder."wallabag/db/password"}
      SYMFONY__ENV__DATABASE_CHARSET=utf8
      SYMFONY__ENV__MAILER_HOST=${config.sops.placeholder."email/smtp/host"}
      SYMFONY__ENV__MAILER_USER=${config.sops.placeholder."email/smtp/username"}
      SYMFONY__ENV__MAILER_PASSWORD=${config.sops.placeholder."email/smtp/password"}
      SYMFONY__ENV__FROM_EMAIL=wallabag@example.com
    '';
  };

  sops.secrets = {
    "email/from/wallabag" = { };
    "miniflux/admin_creds" = { };
    "wallabag/db/password" = { };
  };
}
