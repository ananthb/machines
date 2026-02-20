/**
  Seafile deployment using Podman containers managed by nix-quadlet.

  Components:
  - Seafile server
  - Notification server
  - Metadata server
  - Thumbnail server
  - AI server
  - Seadoc server
  - Collabora CODE (can be hosted separately)

  Dependencies:
  - MySQL (MariaDB)
  - Redis
  - Caddy (ingress) - listening on port 4444 on all interfaces

  Configuration files and secrets are managed using vault-secrets.
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  vs = config.vault-secrets.secrets;
  seafileHostname = "seafile.kedi.dev";
  seahubSettings = pkgs.writeText "seahub_settings.py" ''
    TIME_ZONE = "Asia/Kolkata"

    CSRF_TRUSTED_ORIGINS = ["https://seafile.kedi.dev", "http://endeavour.local:4000"]
    USE_X_FORWARDED_HOST = True
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

    # OAuth Setup
    ENABLE_OAUTH = True
    OAUTH_CREATE_UNKNOWN_USER = True
    OAUTH_ACTIVATE_USER_AFTER_CREATION = False
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
    EMAIL_HOST = "smtp.tem.scw.cloud"
    EMAIL_PORT = 25
    DEFAULT_FROM_EMAIL = "seafile@kedi.dev"
    SERVER_EMAIL = DEFAULT_FROM_EMAIL

    # Enable metadata server
    ENABLE_METADATA_MANAGEMENT = True
    METADATA_SERVER_URL = "http://seafile-md-server:8084"

    # Collabora Code
    OFFICE_SERVER_TYPE = "CollaboraOffice"
    ENABLE_OFFICE_WEB_APP = True
    OFFICE_WEB_APP_BASE_URL = "http://collabora-code:9980/collabora-code/hosting/discovery"

    # Expiration of WOPI access token
    # WOPI access token is a string used by Seafile to determine the file's
    # identity and permissions when use LibreOffice Online view it online
    # And for security reason, this token should expire after a set time period
    WOPI_ACCESS_TOKEN_EXPIRATION = 30 * 60  # seconds

    # List of file formats that you want to view through LibreOffice Online
    # You can change this value according to your preferences
    # And of course you should make sure your LibreOffice Online supports to preview
    # the files with the specified extensions
    OFFICE_WEB_APP_FILE_EXTENSION = (
        "odp",
        "ods",
        "odt",
        "xls",
        "xlsb",
        "xlsm",
        "xlsx",
        "ppsx",
        "ppt",
        "pptm",
        "pptx",
        "doc",
        "docm",
        "docx",
    )

    # Enable edit files through LibreOffice Online
    ENABLE_OFFICE_WEB_APP_EDIT = True

    # types of files should be editable through LibreOffice Online
    OFFICE_WEB_APP_EDIT_FILE_EXTENSION = (
        "odp",
        "ods",
        "odt",
        "xls",
        "xlsb",
        "xlsm",
        "xlsx",
        "ppsx",
        "ppt",
        "pptm",
        "pptx",
        "doc",
        "docm",
        "docx",
    )
  '';
  seafileConf = pkgs.writeText "seafile.conf" ''
    [fileserver]
    port=8082
    max_download_dir_size=10000

    [notification]
    enabled = true
    host = 127.0.0.1
    port = 8083
  '';
  seafileEnv = pkgs.writeText "seafile.env" ''
    # initial variables (valid only during first-time init)
    INIT_SEAFILE_ADMIN_EMAIL=admin@example.com

    # startup parameters
    SEAFILE_LOG_TO_STDOUT=true
    SEAFILE_SERVER_HOSTNAME=${seafileHostname}
    SEAFILE_SERVER_PROTOCOL=https
    TIME_ZONE=Asia/Kolkata
    NON_ROOT=false

    # database
    SEAFILE_MYSQL_DB_HOST=host.containers.internal
    SEAFILE_MYSQL_DB_USER=seafile
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
    SEADOC_SERVER_URL=https://${seafileHostname}/sdoc-server

    # metadata server
    MD_FILE_COUNT_LIMIT=100000

    # notification server
    ENABLE_NOTIFICATION_SERVER=true
    INNER_NOTIFICATION_SERVER_URL=http://seafile-notification-server:8083
    NOTIFICATION_SERVER_URL=https://${seafileHostname}/notification

    # ai server
    ENABLE_SEAFILE_AI=true
    SEAFILE_AI_SERVER_URL=http://seafile-ai:8888
  '';
  notificationServerEnv = pkgs.writeText "seafile-notification-server.env" ''
    SEAFILE_MYSQL_DB_HOST=host.containers.internal
    SEAFILE_MYSQL_DB_USER=seafile
    SEAFILE_MYSQL_DB_PORT=3306
    SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db
    SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
    SEAFILE_LOG_TO_STDOUT=true
    NOTIFICATION_SERVER_LOG_LEVEL=info
  '';
  mdServerEnv = pkgs.writeText "seafile-md-server.env" ''
    SEAFILE_MYSQL_DB_HOST=host.containers.internal
    SEAFILE_MYSQL_DB_USER=seafile
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
  thumbnailServerEnv = pkgs.writeText "seafile-thumbnail-server.env" ''
    TIME_ZONE=Asia/Kolkata
    SEAFILE_MYSQL_DB_HOST=host.containers.internal
    SEAFILE_MYSQL_DB_USER=seafile
    SEAFILE_MYSQL_DB_PORT=3306
    SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db
    SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
    INNER_SEAHUB_SERVICE_URL=http://seafile
    THUMBNAIL_IMAGE_ORIGINAL_SIZE_LIMIT=256
    SEAF_SERVER_STORAGE_TYPE=disk
  '';
  aiEnv = pkgs.writeText "seafile-ai.env" ''
    SEAFILE_AI_LLM_TYPE=openai
    SEAFILE_AI_LLM_URL=http://enterprise:11434/v1
    SEAFILE_AI_LLM_MODEL=gemma3:12b
    SEAFILE_SERVER_URL=http://seafile
    SEAFILE_AI_LOG_LEVEL=info
    CACHE_PROVIDER=redis
    REDIS_HOST=host.containers.internal
    REDIS_PORT=6400
  '';
  seadocEnv = pkgs.writeText "seadoc.env" ''
    SEAFILE_SERVER_HOSTNAME=${seafileHostname}
    SEAFILE_SERVER_PROTOCOL=https
    TIME_ZONE=Asia/Kolkata
    SEAHUB_SERVICE_URL=http://seafile
    DB_HOST=host.containers.internal
    DB_USER=seafile
    DB_PORT=3306
    DB_NAME=sdoc_db
    NON_ROOT=false
  '';
in
{

  imports = [
    ./caddy.nix
    ./warp.nix
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
            publishPorts = [ "4450:80" ];
            environmentFiles = [
              "${seafileEnv}"
              "${vs.seafile}/seafile.env"
            ];
          };
          serviceConfig = {
            Restart = "on-failure";
            ExecStartPre = ''
              ${pkgs.coreutils}/bin/cat \
                ${vs.seafile}/seahub_settings.enc.py \
                ${seahubSettings} \
                > /srv/seafile/seafile-server/seafile/conf/seahub_settings.py
              ${pkgs.coreutils}/bin/cp \
                ${seafileConf} \
                /srv/seafile/seafile-server/seafile/conf/seafile.conf
            '';
          };
          unitConfig = {
            Before = "caddy.service";
            After = lib.concatStringsSep " " [
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
            environmentFiles = [
              "${notificationServerEnv}"
              "${vs.seafile}/notification-server.env"
            ];
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
            environmentFiles = [
              "${mdServerEnv}"
              "${vs.seafile}/md-server.env"
            ];
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
            publishPorts = [ "4453:80" ];
            environmentFiles = [
              "${thumbnailServerEnv}"
              "${vs.seafile}/thumbnail-server.env"
            ];
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
            environmentFiles = [
              "${aiEnv}"
              "${vs.seafile}/ai.env"
            ];
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
            publishPorts = [ "4451:80" ];
            environmentFiles = [
              "${seadocEnv}"
              "${vs.seafile}/seadoc.env"
            ];
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
            environmentFiles = [ "${vs.collabora}/code.env" ];
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
        };
      };
    };

  services = {
    caddy = {
      enable = true;
      virtualHosts.":4444".extraConfig = ''
        # seafile
        reverse_proxy http://localhost:4450

        # notification server
        handle_path /notification* {
          reverse_proxy http://localhost:8083
        }

        # thumbnail server
        handle /thumbnail/* {
          reverse_proxy http://localhost:4453

        }
        handle_path /thumbnail/ping {
          rewrite /ping
          reverse_proxy http://localhost:4453
        }

        # seadoc
        reverse_proxy /socket.io/* http://localhost:4451
        handle_path /sdoc-server/* {
          reverse_proxy http://localhost:4451
        }

        # collabora code
        reverse_proxy /collabora-code/* http://localhost:9980
      '';
    };

    mysql = {
      enable = true;
      package = pkgs.mariadb;
      settings = {
        client = {
          default-character-set = "utf8mb4";
        };
        mysqld = {
          skip-name-resolve = 1;
          bind-address = "*";
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

    redis.servers.seafile = {
      enable = true;
      bind = "0.0.0.0";
      port = 6400;
      unixSocket = null;
      settings.protected-mode = "no";
    };
  };

  networking.firewall.allowedTCPPorts = [ 4000 ];

  # Seafile access to services running on the host
  networking.firewall.interfaces.podman1.allowedTCPPorts = [
    3306 # mysql
    6400 # redis-seafile
  ];

  systemd.services = {
    "redis-seafile" = {
      after = [ "seafile-network.service" ];
      wants = [ "seafile-network.service" ];
    };
    "seafile-mysql-backup" = {
      startAt = "hourly";
      script = ''
        if ! ${pkgs.systemd}/bin/systemctl is-active seafile.service; then
          # Exit successfully if seafile is not running
          exit 0
        fi

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
    "seafile-backup" = {
      # TODO: re-enable after we've trimmed down unnecessary files
      #startAt = "weekly";
      environment.KOPIA_CHECK_FOR_UPDATES = "false";
      script = ''
        ${pkgs.systemd}/bin/systemctl start seafile-mysql-backup.service
        ${config.my-scripts.kopia-snapshot-backup} /srv/seafile
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };

  # Config files
  systemd.tmpfiles.rules = [
    "d /srv/seafile 0755 root root -"
  ];

  vault-secrets.secrets.seafile = {
    services = [
      "seafile"
      "seafile-notification-server"
      "seafile-md-server"
      "seafile-thumbnail-server"
      "seafile-ai"
      "seadoc-server"
    ];
  };

  vault-secrets.secrets.collabora = {
    services = [ "collabora-code" ];
  };

}
