{
  config,
  pkgs,
  ...
}:
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks volumes;
    in
    {
      autoEscape = true;
      autoUpdate.enable = true;

      networks = {
        seafile = { };
      };

      volumes = {
        seafile-mysql-data = { };
      };

      containers = {
        seafile-mysql = {
          containerConfig = {
            name = "seafile-mysql";
            image = "docker.io/library/mariadb:10.11";
            networks = [ networks.seafile.ref ];
            autoUpdate = "registry";
            environments = {
              MYSQL_LOG_CONSOLE = "true";
              MARIADB_AUTO_UPGRADE = "1";
              MYSQL_ROOT_PASSWORD = "password";
            };
            volumes = [
              "${volumes.seafile-mysql-data.ref}:/var/lib/mysql"
            ];
          };
          serviceConfig.Restart = "on-failure";
        };

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
        @ws {
          header Connection *Upgrade*
          header Upgrade    websocket
        }

        reverse_proxy @ws http://localhost:4002

        handle_path /socket.io/* {
          rewrite * /socket.io{uri}
          reverse_proxy http://localhost:4002
        }

        handle_path /sdoc-server/* {
          rewrite * {uri}
          reverse_proxy http://localhost:4002
        }
      '';
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
          "seafile_db.*" = "ALL PRIVILEGES";
          "seadoc_db.*" = "ALL PRIVILEGES";
          "seahub_db.*" = "ALL PRIVILEGES";
        };
      }
    ];
    ensureDatabases = [
      "ccnet_db"
      "seafile_db"
      "seadoc_db"
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

  services.tsnsrv.services = {
    sf = {
      funnel = true;
      urlParts.port = 4000;
    };
  };

  systemd.services."seafile-backup" = {
    # TODO: re-enable after we've trimmed down unnecessary files
    #startAt = "weekly";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      backup_target="/srv/seafile"
      dump_file="$backup_target/seafile-mysql-data.tar"

      # Dump database volume
      systemctl stop seafile-pod.service
      ${pkgs.podman}/bin/podman volume export \
        seafile-mysql-data -o "$dump_file"
      systemctl start seafile-pod.service

      trap '{
        rm -f "$dump_file"
      }' EXIT

      ${config.my-scripts.kopia-snapshot-backup} "$backup_target"
    '';
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
      #SEAFILE_MYSQL_DB_HOST=host.containers.internal
      SEAFILE_MYSQL_DB_HOST=seafile-mysql
      SEAFILE_MYSQL_DB_USER=root
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
      INNER_NOTIFICATION_SERVER_URL=http://127.0.0.1:8083
      NOTIFICATION_SERVER_URL=https://sf.${config.sops.placeholder."tailscale_api/tailnet"}/notification

      # ai server
      ENABLE_SEAFILE_AI=false
      SEAFILE_AI_SERVER_URL=http://seafile-ai:8888
      SEAFILE_AI_SECRET_KEY=key
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
      DB_NAME=seadoc_db

      NON_ROOT=false
    '';
  };

  sops.secrets = {
    "email/from/seafile" = { };
    "seafile/jwt_private_key" = { };
    "seafile/mysql/username" = { };
    "seafile/mysql/password" = { };
    "seafile/seahub_secret_key" = { };
  };

}
