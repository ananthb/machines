{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  services.actual.enable = true;
  services.actual.package = pkgs-unstable.actual-server;
  services.actual.settings.port = 3100;
  systemd.services.actual.serviceConfig.EnvironmentFile =
    config.sops.templates."actual/config.env".path;

  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      DATABASE_URL = "postgresql://vaultwarden@/vaultwarden?host=/run/postgresql";

      ROCKET_ADDRESS = "::";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";

      # sign ups
      INVITATIONS_ALLOWED = true;
      SIGNUPS_ALLOWED = false;
    };
    environmentFile = config.sops.templates."vaultwarden/secrets.env".path;
  };

  services.mealie = {
    enable = true;
    package = pkgs-unstable.mealie;
    listenAddress = "[::]";
    database.createLocally = true;
    credentialsFile = config.sops.templates."mealie/env".path;
  };

  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "[::]:5232" ];
      auth = {
        type = "htpasswd";
        htpasswd_filename = "${config.sops.secrets."radicale/htpasswd".path}";
        htpasswd_encryption = "autodetect";
      };
    };
  };

  services.jellyseerr.enable = true;
  systemd.services.jellyseerr.environment = {
    DB_TYPE = "postgres";
    DB_SOCKET_PATH = "/var/run/postgresql";
    DB_USER = "jellyseerr";
    DB_NAME = "jellyseerr";
  };

  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets."kavita/token".path;
  };

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
      3100 # actual
      5000 # kavita
      5232 # radicale
      8088 # miniflux
      8222 # vaultwarden
      9000 # mealie
    ];
    interfaces.podman0.allowedTCPPorts = [
      5432 # postgres
    ];
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      host wallabag wallabag 10.88.0.0/16 md5
    '';
    ensureDatabases = [
      "jellyseerr"
      "vaultwarden"
      "wallabag"
    ];
    ensureUsers = [
      {
        name = "jellyseerr";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
      {
        name = "wallabag";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  systemd.services = {
    "actual-backup" = {
      startAt = "daily";
      environment.KOPIA_CHECK_FOR_UPDATES = "false";
      preStart = "systemctl stop actual.service";
      script = ''
        backup_target="/var/lib/actual"
        snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

        trap '{
          rm -rf "$snapshot_target"
        }' EXIT

        ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target" 
        ${config.my-scripts.kopia-backup} "$snapshot_target" "$backup_target"
      '';
      postStop = "systemctl start actual.service";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };

    "vaultwarden-backup" = {
      startAt = "daily";
      environment.KOPIA_CHECK_FOR_UPDATES = "false";
      preStart = "systemctl is-active vaultwarden.service && systemctl stop vaultwarden.service";
      script = ''
        backup_target="/var/lib/vaultwarden"
        snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"
        dump_file="$snapshot_target/db.dump"
          
        trap '{
          rm -f "$dump_file"
          rm -rf "$snapshot_target"
        }' EXIT

        # Dump database
        ${pkgs.sudo-rs}/bin/sudo -u vaultwarden \
          ${pkgs.postgresql_16}/bin/pg_dump \
            -Fc -U vaultwarden vaultwarden > "$dump_file"
        printf 'Dumped database to %s' "$dump_file"

        ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target"

        ${config.my-scripts.kopia-backup} "$snapshot_target" "$backup_target"
      '';
      postStop = "systemctl start vaultwarden.service";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };

    "mealie-backup" = {
      startAt = "weekly";
      environment.KOPIA_CHECK_FOR_UPDATES = "false";
      script = ''
        backup_api_url="http://localhost:9000/api/admin/backups"

        http() {
          ${pkgs.httpie}/bin/http -A bearer -a "$backups_key" \
            --check-status \
            --ignore-stdin \
            --timeout=2.5 \
            "$@"
        }

        # Delete all backups
         http GET "$backup_api_url" \
          | ${pkgs.jq}/bin/jq -r '.imports[].name' \
          | ${pkgs.findutils}/bin/xargs -I{} \
            ${pkgs.httpie}/bin/http -A bearer -a "$backups_key" \
              --check-status \
              --ignore-stdin \
              --timeout=2.5 \
              DELETE "$backup_api_url/"{}

        # Create new backup
        http POST "$backup_api_url"

        # Upload new backup
        ${config.my-scripts.kopia-backup} /var/lib/mealie/backups
      '';
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = "${config.sops.secrets."mealie/api_keys".path}";
      };
    };

    "radicale-backup" = {
      startAt = "daily";
      environment.KOPIA_CHECK_FOR_UPDATES = "false";
      preStart = "systemctl is-active radicale.service && systemctl stop radicale.service";
      script = ''
        backup_target="/var/lib/radicale"
        snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

        trap '{
          rm -rf "$snapshot_target"
        }' EXIT

        ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target" 
        ${config.my-scripts.kopia-backup} "$snapshot_target" "$backup_target"
      '';
      postStop = "systemctl start radicale.service";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };

  };

  sops.templates = {
    "actual/config.env" = {
      content = ''
        ACTUAL_OPENID_DISCOVERY_URL=https://accounts.google.com/.well-known/openid-configuration
        ACTUAL_OPENID_SERVER_HOSTNAME=https://actual.kedi.dev
        ACTUAL_OPENID_CLIENT_ID=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}
        ACTUAL_OPENID_CLIENT_SECRET=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}
      '';
    };

    "vaultwarden/secrets.env" = {
      content = ''
        DOMAIN=https://vault.kedi.dev
        ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin_token"}

        # smtp
        SMTP_HOST=${config.sops.placeholder."email/smtp/host"}
        SMTP_PORT=587
        SMTP_SECURITY=starttls
        SMTP_USERNAME=${config.sops.placeholder."email/smtp/username"}
        SMTP_PASSWORD=${config.sops.placeholder."email/smtp/password"}
        SMTP_FROM=${config.sops.placeholder."email/from/vaultwarden"}
        SMTP_FROM_NAME=KEDI Vaultwarden

        # push notifications
        PUSH_ENABLED=true
        PUSH_RELAY_URI=https://api.bitwarden.eu
        PUSH_IDENTITY_URI=https://identity.bitwarden.eu
        PUSH_INSTALLATION_ID=${config.sops.placeholder."vaultwarden/installation_id"}
        PUSH_INSTALLATION_KEY=${config.sops.placeholder."vaultwarden/installation_key"}
      '';
    };

    "mealie/env" = {
      content = ''
        # general
        BASE_URL=https://mealie.kedi.dev

        # TODO: this blasted setting doesn't work
        #FORWARDED_ALLOW_IPS=[::1],127.0.0.1,[fdc0:6625:5195::50],10.15.16.50
        FORWARDED_ALLOW_IPS=*

        # auth
        ALLOW_PASSWORD_LOGIN=False
        OIDC_AUTH_ENABLED=True
        OIDC_SIGNUP_ENABLED=False
        OIDC_CLIENT_ID=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}
        OIDC_CLIENT_SECRET=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}
        OIDC_PROVIDER_NAME=Google
        OIDC_CONFIGURATION_URL=https://accounts.google.com/.well-known/openid-configuration

        # smtp
        SMTP_HOST=${config.sops.placeholder."email/smtp/host"}
        SMTP_FROM_EMAIL=${config.sops.placeholder."email/from/mealie"}
        SMTP_USER=${config.sops.placeholder."email/smtp/username"}
        SMTP_PASSWORD=${config.sops.placeholder."email/smtp/password"}

        # open-webui
        OPENAI_BASE_URL=http://endeavour.local:8090/ollama/v1
        OPENAI_MODEL=gemma3:12b
        OPENAI_API_KEY=${config.sops.placeholder."open-webui/api_key"}
      '';
    };

    "wallabag/env" = {
      content = ''
        SYMFONY__ENV__DOMAIN_NAME=https://wallabag.kedi.dev
        SYMFONY__ENV__DATABASE_DRIVER=pdo_pgsql
        SYMFONY__ENV__DATABASE_HOST=10.88.0.1
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
    };

  };

  sops.secrets = {
    "email/from/mealie" = { };
    "email/from/vaultwarden" = { };
    "email/from/wallabag" = { };
    "kavita/token" = { };
    "mealie/api_keys" = { };
    "miniflux/admin_creds" = { };
    "open-webui/api_key" = { };
    "radicale/htpasswd".owner = "radicale";
    "vaultwarden/admin_token" = { };
    "vaultwarden/installation_id" = { };
    "vaultwarden/installation_key" = { };
    "wallabag/db/username" = { };
    "wallabag/db/password" = { };
  };
}
