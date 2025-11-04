{
  config,
  pkgs,
  ...
}:
{
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
              #"${config.sops.templates."seafile/seahub_settings.py".path}:/shared/seafile/conf/seahub_settings.py"
              "/srv/seafile/seafile:/shared"
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
                /srv/seafile/seafile/seafile/conf/seahub_settings.py
            '';
          };
          unitConfig = {
            Before = "caddy.service";
            After = "mysql.service redis-seafile.service seafile-notification-server.service seadoc.service collabora-code.service";
            Wants = "mysql.service redis-seafile.service seafile-notification-server.service seadoc.service collabora-code.service caddy.service";
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
    virtualHosts.":4000" = {
      listenAddresses = [ "::1" ];
      extraConfig = ''
        # seafile
        reverse_proxy http://localhost:4001

        # seadoc
        handle_path /socket.io/* {
          rewrite * /socket.io{uri}
          reverse_proxy http://localhost:4002
        }
        handle_path /sdoc-server/* {
          rewrite * {uri}
          reverse_proxy http://localhost:4002
        }

        # notification server
        handle_path /notification* {
          rewrite * {uri}
          reverse_proxy http://localhost:8083
        }

        # collabora code
        handle_path /collabora-code/* {
          rewrite * /collabora-code{uri}
          reverse_proxy http://localhost:9980
        }
      '';
    };
  };

  services.tsnsrv.services.sf = {
    funnel = true;
    urlParts.port = 4000;
  };

  systemd.services = {
    tsnsrv-sf = {
      wants = [
        "caddy.service"
        "collabora-code.service"
        "seadoc.service"
        "seafile.service"
      ];
      after = [
        "caddy.service"
        "collabora-code.service"
        "seadoc.service"
        "seafile.service"
      ];
    };
  };

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

  # Let seafile access redis and mysql
  networking.firewall.interfaces.podman1.allowedTCPPorts = [
    3306
    6400
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

  systemd.services."seafile-backup" = {
    # TODO: re-enable after we've trimmed down unnecessary files
    #startAt = "weekly";
    script = ''
      systemctl start seafile-mysql-backup.service
      ${config.my-scripts.kopia-snapshot-backup} /srv/seafile
    '';
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  #
  # Config files
  #
  sops.templates."seafile/seafile.env" = {
    content = ''
      # startup parameters
      SEAFILE_SERVER_HOSTNAME=sf.${config.sops.placeholder."tailscale_api/tailnet"}
      SEAFILE_SERVER_PROTOCOL=https
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      TIME_ZONE=Asia/Kolkata

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

      # initial variables (valid only during first-time init)
      INIT_SEAFILE_ADMIN_EMAIL=admin@example.com
      INIT_SEAFILE_ADMIN_PASSWORD=change me soon


      SITE_ROOT=/
      NON_ROOT=false
      SEAFILE_LOG_TO_STDOUT=true

      # seadoc
      ENABLE_SEADOC=true
      SEADOC_SERVER_URL=https://sf.${config.sops.placeholder."tailscale_api/tailnet"}/sdoc-server

      # metadata server
      MD_FILE_COUNT_LIMIT=100000

      # notification server
      ENABLE_NOTIFICATION_SERVER=true
      NOTIFICATION_SERVER_URL=https://sf.${config.sops.placeholder."tailscale_api/tailnet"}/notification

      # ai server
      ENABLE_SEAFILE_AI=false
    '';
  };

  sops.templates."seafile/seahub_settings.py" = {
    content = ''
      # -*- coding: utf-8 -*-
      SECRET_KEY = "${config.sops.placeholder."seafile/seahub_secret_key"}"

      TIME_ZONE = "Asia/Kolkata"

      CSRF_TRUSTED_ORIGINS = ["https://*.${config.sops.placeholder."tailscale_api/tailnet"}"]
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
      OAUTH_REDIRECT_URL = "https://sf.${config.sops.placeholder."tailscale_api/tailnet"}/oauth/callback/"
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

  sops.templates."seafile/seadoc.env" = {
    content = ''
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      SEAFILE_SERVER_HOSTNAME=tv.${config.sops.placeholder."tailscale_api/tailnet"}
      SEAFILE_SERVER_PROTOCOL=https
      TIME_ZONE=Asia/Kolkata
      SEAHUB_SERVICE_URL=http://seafile

      # database
      DB_HOST=host.containers.internal
      DB_USER=${config.sops.placeholder."seafile/mysql/username"}
      DB_PASSWORD=${config.sops.placeholder."seafile/mysql/password"}
      DB_PORT=3306
      DB_NAME=sdoc_db

      NON_ROOT=false
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

  sops.templates."collabora/code.env" = {
    content = ''
      server_name=sf.${config.sops.placeholder."tailscale_api/tailnet"}
      username=${config.sops.placeholder."collabora/code/username"}
      password=${config.sops.placeholder."collabora/code/password"}
      DONT_GEN_SSL_CERT=true
      TZ=Asia/Kolkata
      extra_params=--o:logging.file[@enable]=false --o:logging.file.property[0]=/opt/cool/logs/coolwsd.log --o:admin_console.enable=true --o:ssl.enable=false --o:ssl.termination=true --o:net.service_root=/collabora-code
    '';
  };

  sops.secrets = {
    "collabora/code/username" = { };
    "collabora/code/password" = { };
    "email/from/seafile" = { };
    "seafile/jwt_private_key" = { };
    "seafile/mysql/username" = { };
    "seafile/mysql/password" = { };
    "seafile/seahub_secret_key" = { };
  };

}
