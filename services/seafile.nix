/**
  Seafile deployment using Podman containers managed by nix-quadlet.

  Components:
  - Seafile server
  - Notification server
  - Metadata server
  - Thumbnail server
  - AI server
  - Seadoc server
  - Collabora CODE

  Dependencies:
  - MySQL (MariaDB)
  - Redis
  - Caddy (ingress) - listening on port 4000 on all interfaces

  Configuration files and secrets are managed using SOPS templates.
*/
{
  config,
  lib,
  pkgs,
  ...
}:
{

  imports = [
    ./caddy.nix
  ];

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      autoEscape = true;
      autoUpdate.enable = true;

      networks = {
        seafile = { };
      };

      containers = {
        seafile = {
          containerConfig = {
            name = "seafile";
            image = "docker.io/seafileltd/seafile-mc:13.0-latest";
            autoUpdate = "registry";
            volumes = [
              "/srv/seafile/seafile-server:/shared"
            ];
            networks = [
              networks.seafile.ref
            ];
            publishPorts = [ "4001:80" ];
            environmentFiles = [ config.sops.templates."seafile/seafile.env".path ];
          };
          serviceConfig = {
            Restart = "on-failure";
            ExecStartPre = ''
              ${pkgs.coreutils}/bin/cp \
                ${config.sops.templates."seafile/seahub_settings.py".path} \
                /srv/seafile/seafile-server/seafile/conf/seahub_settings.py
            '';
          };
          unitConfig = {
            Before = "caddy.service";
            After = lib.concatStringsSep " " [
              "collabora-code.service"
              "mysql.service"
              "redis-seafile.service"
              "seadoc.service"
              "seafile-ai.service"
              "seafile-md-server.service"
              "seafile-notification-server.service"
              "seafile-thumbnail-server.service"
            ];
            Wants = lib.concatStringsSep " " [
              "caddy.service"
              "collabora-code.service"
              "mysql.service"
              "redis-seafile.service"
              "seadoc.service"
              "seafile-ai.service"
              "seafile-md-server.service"
              "seafile-notification-server.service"
              "seafile-thumbnail-server.service"
            ];
          };
        };

        seafile-notification-server = {
          containerConfig = {
            name = "seafile-notification-server";
            image = "docker.io/seafileltd/notification-server:13.0-latest";
            autoUpdate = "registry";
            networks = [
              networks.seafile.ref
            ];
            publishPorts = [ "8083:8083" ];
            environmentFiles = [ config.sops.templates."seafile/notification-server.env".path ];
          };
          serviceConfig.Restart = "on-failure";
          unitConfig = {
            Before = "caddy.service";
            After = "mysql.service";
            Wants = "mysql.service caddy.service";
          };
        };

        seafile-md-server = {
          containerConfig = {
            name = "seafile-md-server";
            image = "docker.io/seafileltd/seafile-md-server:13.0-latest";
            autoUpdate = "registry";
            volumes = [
              "/srv/seafile/seafile-server:/shared"
            ];
            networks = [
              networks.seafile.ref
            ];
            publishPorts = [ "8084:8084" ];
            environmentFiles = [ config.sops.templates."seafile/md-server.env".path ];
          };
          serviceConfig.Restart = "on-failure";
          unitConfig = {
            Before = "caddy.service";
            After = "mysql.service redis-seafile.service";
            Wants = "caddy.service mysql.service redis-seafile.service";
          };
        };

        seafile-thumbnail-server = {
          containerConfig = {
            name = "seafile-thumbnail-server";
            image = "docker.io/seafileltd/thumbnail-server:13.0-latest";
            autoUpdate = "registry";
            volumes = [
              "/srv/seafile/seafile-server:/shared"
            ];
            networks = [
              networks.seafile.ref
            ];
            publishPorts = [ "4003:80" ];
            environmentFiles = [ config.sops.templates."seafile/thumbnail-server.env".path ];
          };
          serviceConfig.Restart = "on-failure";
          unitConfig = {
            Before = "caddy.service";
            After = "mysql.service";
            Wants = "mysql.service caddy.service";
          };
        };

        seafile-ai = {
          containerConfig = {
            name = "seafile-ai";
            image = "docker.io/seafileltd/seafile-ai:13.0-latest";
            autoUpdate = "registry";
            volumes = [
              "/srv/seafile/seafile-server:/shared"
            ];
            networks = [
              networks.seafile.ref
            ];
            environmentFiles = [ config.sops.templates."seafile/ai.env".path ];
          };
          serviceConfig.Restart = "on-failure";
          unitConfig = {
            After = "redis-seafile.service";
            Wants = "redis-seafile.service";
          };
        };

        seadoc = {
          containerConfig = {
            name = "seadoc";
            image = "docker.io/seafileltd/sdoc-server:2.0-latest";
            autoUpdate = "registry";
            volumes = [
              "/srv/seafile/seadoc:/shared"
            ];
            networks = [
              networks.seafile.ref
            ];
            publishPorts = [ "4002:80" ];
            environmentFiles = [ config.sops.templates."seafile/seadoc.env".path ];
          };
          serviceConfig.Restart = "on-failure";
        };

        collabora-code = {
          containerConfig = {
            name = "collabora-code";
            image = "docker.io/collabora/code:latest";
            podmanArgs = [ "--privileged" ];
            autoUpdate = "registry";
            networks = [
              networks.seafile.ref
            ];
            publishPorts = [ "9980:9980" ];
            environmentFiles = [ config.sops.templates."collabora/code.env".path ];
            environments = {
              extra_params = lib.concatStringsSep " " [
                "--o:logging.file[@enable]=false"
                "--o:admin_console.enable=true"
                "--o:ssl.enable=false"
                "--o:ssl.termination=true"
                "--o:net.service_root=/collabora-code"
              ];
            };
          };
          serviceConfig.Restart = "on-failure";
          unitConfig = {
            Before = "caddy.service";
            Wants = "caddy.service";
          };
        };
      };
    };

  services.caddy = {
    enable = true;
    virtualHosts.":4000".extraConfig = ''
      # seafile
      reverse_proxy http://localhost:4001

      # notification server
      handle_path /notification* {
        reverse_proxy http://localhost:8083
      }

      # thumbnail server
      handle /thumbnail/* {
        reverse_proxy http://localhost:4003

      }
      handle_path /thumbnail/ping {
        rewrite /ping
        reverse_proxy http://localhost:4003
      }

      # seadoc
      reverse_proxy /socket.io/* http://localhost:4002
      handle_path /sdoc-server/* {
        reverse_proxy http://localhost:4002
      }

      # collabora code
      reverse_proxy /collabora-code/* http://localhost:9980
    '';
  };

  networking.firewall.allowedTCPPorts = [ 4000 ];

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    settings = {
      client = {
        default-character-set = "utf8mb4";
      };
      mysqld = {
        skip-name-resolve = 1;
        # localhost and podman bridge network
        bind-address = "::1,10.89.0.1";
        # See https://github.com/MariaDB/mariadb-docker/issues/560#issuecomment-1956517890
        character-set-server = "utf8mb4";
        collation-server = "utf8mb4_bin";
      };
    };
    ensureUsers = [
      {
        name = "seafile";
        ensurePermissions = {
          "ccnet_db.*" = "ALL PRIVILEGES";
          "sdoc_db.*" = "ALL PRIVILEGES";
          "seafile_db.*" = "ALL PRIVILEGES";
          "seahub_db.*" = "ALL PRIVILEGES";
        };
      }
    ];
    ensureDatabases = [
      "ccnet_db"
      "sdoc_db"
      "seafile_db"
      "seahub_db"
    ];
  };

  services.redis.servers.seafile = {
    enable = true;
    bind = "10.89.0.1";
    port = 6400;
    unixSocket = null;
    settings.protected-mode = "no";
  };

  # Seafile access to services running on the host
  networking.firewall.interfaces.podman1.allowedTCPPorts = [
    3306 # mysql
    6400 # redis-seafile
    8090 # open-webui
  ];

  systemd.services."seafile-mysql-backup" = {
    startAt = "hourly";
    script = ''
      backup_dir="/srv/seafile/backups"
      mkdir -p "$backup_dir"

      # Removes all but 2 files starting from the oldest
      pushd "$backup_dir"
      ls -t | tail -n +3 | tr '\n' '\0' | xargs -0 rm --
      popd

      dump_file="$backup_dir/seafile_dbs_dump-$(date --utc --iso-8601=seconds).sql"
      # Dump databases
      ${pkgs.sudo}/bin/sudo ${pkgs.mariadb}/bin/mysqldump \
        --databases ccnet_db sdoc_db seafile_db seahub_db | \
          ${pkgs.zstd}/bin/zstd > "$dump_file.zst"
    '';
  };

  # Config files
  sops.templates."seafile/seafile.env" = {
    content = ''
      # initial variables (valid only during first-time init)
      INIT_SEAFILE_ADMIN_EMAIL=admin@example.com
      INIT_SEAFILE_ADMIN_PASSWORD=change me soon

      # startup parameters
      SEAFILE_LOG_TO_STDOUT=true
      SEAFILE_SERVER_HOSTNAME=seafile.kedi.dev
      SEAFILE_SERVER_PROTOCOL=https
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      TIME_ZONE=Asia/Kolkata
      NON_ROOT=false

      # database
      SEAFILE_MYSQL_DB_HOST=host.containers.internal
      SEAFILE_MYSQL_DB_USER=${config.sops.placeholder."seafile/mysql/username"}
      SEAFILE_MYSQL_DB_PASSWORD=${config.sops.placeholder."seafile/mysql/password"}
      SEAFILE_MYSQL_DB_PORT=3306
      SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db
      SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
      SEAFILE_MYSQL_DB_SEAHUB_DB_NAME=seahub_db

      # redis
      CACHE_PROVIDER=redis
      REDIS_HOST=host.containers.internal
      REDIS_PORT=6400

      # seadoc
      ENABLE_SEADOC=true
      SEADOC_SERVER_URL=https://seafile.kedi.dev/sdoc-server

      # metadata server
      MD_FILE_COUNT_LIMIT=100000

      # notification server
      ENABLE_NOTIFICATION_SERVER=true
      INNER_NOTIFICATION_SERVER_URL=http://seafile-notification-server:8083
      NOTIFICATION_SERVER_URL=https://seafile.kedi.dev/notification

      # ai server
      ENABLE_SEAFILE_AI=true
      SEAFILE_AI_SERVER_URL=http://seafile-ai:8888
      SEAFILE_AI_SECRET_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
    '';
  };

  sops.templates."seafile/seahub_settings.py" = {
    content = ''
      # -*- coding: utf-8 -*-
      SECRET_KEY = "${config.sops.placeholder."seafile/seahub_secret_key"}"

      TIME_ZONE = "Asia/Kolkata"

      CSRF_TRUSTED_ORIGINS = ["https://seafile.kedi.dev"]
      USE_X_FORWARDED_HOST = True
      SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
      SECURE_SSL_REDIRECT = True
      SESSION_COOKIE_SECURE = True
      CSRF_COOKIE_SECURE = True

      # OAuth Setup
      ENABLE_OAUTH = True
      OAUTH_CREATE_UNKNOWN_USER = True
      OAUTH_ACTIVATE_USER_AFTER_CREATION = False
      OAUTH_CLIENT_ID = "${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}"
      OAUTH_CLIENT_SECRET = "${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}"
      OAUTH_REDIRECT_URL = "https://seafile.kedi.dev/oauth/callback/"
      OAUTH_PROVIDER_DOMAIN = "google.com"
      OAUTH_AUTHORIZATION_URL = "https://accounts.google.com/o/oauth2/v2/auth"
      OAUTH_TOKEN_URL = "https://www.googleapis.com/oauth2/v4/token"
      OAUTH_USER_INFO_URL = "https://www.googleapis.com/oauth2/v1/userinfo"
      OAUTH_SCOPE = [
          "openid",
          "https://www.googleapis.com/auth/userinfo.email",
          "https://www.googleapis.com/auth/userinfo.profile",
      ]
      OAUTH_ATTRIBUTE_MAP = {
          "id": (True, "uid"),
          "name": (False, "name"),
          "email": (False, "contact_email"),
      }

      # SMTP
      EMAIL_USE_TLS = True
      EMAIL_HOST = "${config.sops.placeholder."email/smtp/host"}"
      EMAIL_HOST_USER = "${config.sops.placeholder."email/smtp/username"}"
      EMAIL_HOST_PASSWORD = "${config.sops.placeholder."email/smtp/password"}"
      EMAIL_PORT = 25
      DEFAULT_FROM_EMAIL = "${config.sops.placeholder."email/from/seafile"}"
      SERVER_EMAIL = DEFAULT_FROM_EMAIL

      # Enable metadata server
      ENABLE_METADATA_MANAGEMENT = True
      METADATA_SERVER_URL = 'http://seafile-md-server:8084'

      # Collabora Code
      OFFICE_SERVER_TYPE = 'CollaboraOffice'
      ENABLE_OFFICE_WEB_APP = True
      OFFICE_WEB_APP_BASE_URL = 'http://collabora-code:9980/collabora-code/hosting/discovery'

      # Expiration of WOPI access token
      # WOPI access token is a string used by Seafile to determine the file's
      # identity and permissions when use LibreOffice Online view it online
      # And for security reason, this token should expire after a set time period
      WOPI_ACCESS_TOKEN_EXPIRATION = 30 * 60   # seconds

      # List of file formats that you want to view through LibreOffice Online
      # You can change this value according to your preferences
      # And of course you should make sure your LibreOffice Online supports to preview
      # the files with the specified extensions
      OFFICE_WEB_APP_FILE_EXTENSION = (
          'odp',
          'ods',
          'odt',
          'xls',
          'xlsb',
          'xlsm',
          'xlsx',
          'ppsx',
          'ppt',
          'pptm',
          'pptx',
          'doc',
          'docm',
          'docx',
      )

      # Enable edit files through LibreOffice Online
      ENABLE_OFFICE_WEB_APP_EDIT = True

      # types of files should be editable through LibreOffice Online
      OFFICE_WEB_APP_EDIT_FILE_EXTENSION = (
          'odp',
          'ods',
          'odt',
          'xls',
          'xlsb',
          'xlsm',
          'xlsx',
          'ppsx',
          'ppt',
          'pptm',
          'pptx',
          'doc',
          'docm',
          'docx',
      )
    '';
  };

  sops.templates."seafile/notification-server.env" = {
    content = ''
      SEAFILE_MYSQL_DB_HOST=host.containers.internal
      SEAFILE_MYSQL_DB_USER=${config.sops.placeholder."seafile/mysql/username"}
      SEAFILE_MYSQL_DB_PASSWORD=${config.sops.placeholder."seafile/mysql/password"}
      SEAFILE_MYSQL_DB_PORT=3306
      SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db
      SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      SEAFILE_LOG_TO_STDOUT=true
      NOTIFICATION_SERVER_LOG_LEVEL=info
    '';
  };

  sops.templates."seafile/md-server.env" = {
    content = ''
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      SEAFILE_MYSQL_DB_HOST=host.containers.internal
      SEAFILE_MYSQL_DB_USER=${config.sops.placeholder."seafile/mysql/username"}
      SEAFILE_MYSQL_DB_PASSWORD=${config.sops.placeholder."seafile/mysql/password"}
      SEAFILE_MYSQL_DB_PORT=3306
      SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
      SEAFILE_LOG_TO_STDOUT=true
      MD_PORT=8084
      MD_LOG_LEVEL=info
      MD_MAX_CACHE_SIZE=1GB
      MD_CHECK_UPDATE_INTERVAL=30m
      MD_FILE_COUNT_LIMIT=100000
      SEAF_SERVER_STORAGE_TYPE=disk
      MD_STORAGE_TYPE=disk
      CACHE_PROVIDER=redis
      REDIS_HOST=host.containers.internal
      REDIS_PORT=6400
    '';
  };

  sops.templates."seafile/thumbnail-server.env" = {
    content = ''
      TIME_ZONE=Asia/Kolkata
      SEAFILE_MYSQL_DB_HOST=host.containers.internal
      SEAFILE_MYSQL_DB_USER=${config.sops.placeholder."seafile/mysql/username"}
      SEAFILE_MYSQL_DB_PASSWORD=${config.sops.placeholder."seafile/mysql/password"}
      SEAFILE_MYSQL_DB_PORT=3306
      SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db
      SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      INNER_SEAHUB_SERVICE_URL=http://seafile
      THUMBNAIL_IMAGE_ORIGINAL_SIZE_LIMIT=256
      SEAF_SERVER_STORAGE_TYPE=disk
    '';
  };

  sops.templates."seafile/ai.env" = {
    content = ''
      SEAFILE_AI_LLM_TYPE=openai
      SEAFILE_AI_LLM_URL=http://host.containers.internal:8090/ollama/v1
      SEAFILE_AI_LLM_KEY=${config.sops.placeholder."open-webui/api_key"}
      SEAFILE_AI_LLM_MODEL=gemma3:12b
      SEAFILE_SERVER_URL=http://seafile
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      SEAFILE_AI_LOG_LEVEL=info
      CACHE_PROVIDER=redis
      REDIS_HOST=host.containers.internal
      REDIS_PORT=6400
    '';
  };

  sops.templates."seafile/seadoc.env" = {
    content = ''
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      SEAFILE_SERVER_HOSTNAME=seafile.kedi.dev
      SEAFILE_SERVER_PROTOCOL=https
      TIME_ZONE=Asia/Kolkata
      SEAHUB_SERVICE_URL=http://seafile
      DB_HOST=host.containers.internal
      DB_USER=${config.sops.placeholder."seafile/mysql/username"}
      DB_PASSWORD=${config.sops.placeholder."seafile/mysql/password"}
      DB_PORT=3306
      DB_NAME=sdoc_db
      NON_ROOT=false
    '';
  };

  sops.templates."collabora/code.env" = {
    content = ''
      server_name=seafile.kedi.dev
      aliasgroup1=https://seafile.kedi.dev:443
      username=${config.sops.placeholder."collabora/code/username"}
      password=${config.sops.placeholder."collabora/code/password"}
      DONT_GEN_SSL_CERT=true
      TZ=Asia/Kolkata
    '';
  };

  sops.secrets = {
    "collabora/code/username" = { };
    "collabora/code/password" = { };
    "email/from/seafile" = { };
    "gcloud/oauth_self-hosted_clients/id" = { };
    "gcloud/oauth_self-hosted_clients/secret" = { };
    "seafile/jwt_private_key" = { };
    "seafile/mysql/username" = { };
    "seafile/mysql/password" = { };
    "seafile/seahub_secret_key" = { };
    "open-webui/api_key" = { };
  };

}
