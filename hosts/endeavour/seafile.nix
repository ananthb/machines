{
  config,
  pkgs,
  ...
}:
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks pods volumes;
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

      pods = {
        seafile.podConfig = {
          networks = [
            networks.seafile.ref
          ];
          volumes = [
            "${config.sops.templates."seafile/Caddyfile".path}:/etc/caddy/Caddyfile"
            "${config.sops.templates."seafile/seahub_settings.py".path}:/shared/seafile/conf/seahub_settings.py"
            "${volumes.seafile-mysql-data.ref}:/var/lib/mysql"
            "/srv/seafile/seafile-data:/shared"
          ];
          publishPorts = [ "4000:4000" ];
        };
      };

      containers = {
        seafile-caddy = {
          containerConfig = {
            name = "seafile-caddy";
            image = "docker.io/library/caddy:2";
            pod = pods.seafile.ref;
            autoUpdate = "registry";
          };
          serviceConfig.Restart = "on-failure";
        };

        seafile-mysql = {
          containerConfig = {
            name = "seafile-mysql";
            image = "docker.io/library/mariadb:10.11";
            pod = pods.seafile.ref;
            autoUpdate = "registry";
            environments = {
              MYSQL_LOG_CONSOLE = "true";
              MARIADB_AUTO_UPGRADE = "1";
              MYSQL_ROOT_PASSWORD = "password";
            };
          };
          serviceConfig.Restart = "on-failure";
        };

        seafile-redis = {
          containerConfig = {
            name = "seafile-redis";
            image = "docker.io/library/redis";
            pod = pods.seafile.ref;
            autoUpdate = "registry";
          };
          serviceConfig.Restart = "on-failure";
        };

        seafile-server = {
          containerConfig = {
            name = "seafile";
            image = "docker.io/seafileltd/seafile-mc:13.0-latest";
            pod = pods.seafile.ref;
            autoUpdate = "registry";
            environmentFiles = [ config.sops.templates."seafile/seafile.env".path ];
            environments = {
              TIME_ZONE = "Asia/Kolkata";
              INIT_SEAFILE_ADMIN_EMAIL = "admin@example.com";
              INIT_SEAFILE_ADMIN_PASSWORD = "change me soon";
              SEAFILE_SERVER_PROTOCOL = "https";
              SITE_ROOT = "/";
              NON_ROOT = "false";
              SEAFILE_LOG_TO_STDOUT = "true";

              ENABLE_SEADOC = "true";

              SEAFILE_MYSQL_DB_HOST = "127.0.0.1";
              SEAFILE_MYSQL_DB_PORT = "3306";
              SEAFILE_MYSQL_DB_USER = "root";
              SEAFILE_MYSQL_DB_PASSWORD = "password";
              INIT_SEAFILE_MYSQL_ROOT_PASSWORD = "password";
              SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
              SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
              SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";

              CACHE_PROVIDER = "redis";
              REDIS_HOST = "127.0.0.1";
              REDIS_PORT = "6379";

              ENABLE_NOTIFICATION_SERVER = "false";
              INNER_NOTIFICATION_SERVER_URL = "http://127.0.0.1:8083";
              ENABLE_SEAFILE_AI = "false";
              SEAFILE_AI_SERVER_URL = "http://seafile-ai:8888";
              SEAFILE_AI_SECRET_KEY = "key";
              MD_FILE_COUNT_LIMIT = "100000";
            };
          };
          serviceConfig.Restart = "on-failure";
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
            environmentFiles = [ config.sops.templates."seafile/seadoc.env".path ];
            environments = {
              DB_HOST = "seafile-mysql";
              DB_PORT = "3306";
              DB_USER = "root";
              DB_PASSWORD = "password";
              DB_NAME = "seadoc_db";
              TIME_ZONE = "Asia/Kolkata";
              NON_ROOT = "false";
              SEAHUB_SERVICE_URL = "http://seafile:4000";
            };
          };
          serviceConfig.Restart = "on-failure";
        };
      };
    };

  services.tsnsrv.services = {
    sf = {
      funnel = true;
      urlParts.host = "127.0.0.1";
      urlParts.port = 4000;
    };
  };

  # TODO: re-enable after we've trimmed down unnecessary files
  #systemd.timers."seafile-backup" = {
  #  wantedBy = [ "timers.target" ];
  #  timerConfig = {
  #    # Runs on the 28th of each month
  #    OnCalendar = "weekly";
  #    Persistent = true;
  #  };
  #};

  systemd.services."seafile-backup" = {
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

  sops.templates."seafile/Caddyfile" = {
    content = ''
      :4000 {
        header Access-Control-Allow-Origin

        handle_path /seafhttp* {
          reverse_proxy 127.0.0.1:8082
        }

        handle_path /notification* {
          reverse_proxy 127.0.0.1:8083
        }

        redir /seafdav /seafdav/ permanent
        reverse_proxy /seafdav/* 127.0.0.1:8080

        reverse_proxy /media* 127.0.0.1:80 {
          header_down -Access-Control-Allow-Origin
        }

        handle_path /sdoc-server/* {
          reverse_proxy seadoc:7070 {
            header_down Access-Control-Allow-Origin "https://sf.${
              config.sops.placeholder."tailscale_api/tailnet"
            }"
          }
        }

        handle_path /socket.io* {
          reverse_proxy seadoc:7070 {
            header_down Access-Control-Allow-Origin "https://sf.${
              config.sops.placeholder."tailscale_api/tailnet"
            }"
          }
        }

        reverse_proxy 127.0.0.1:8000
      }
    '';
  };

  sops.templates."seafile/seafile.env" = {
    content = ''
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      SEAFILE_SERVER_HOSTNAME=sf.${config.sops.placeholder."tailscale_api/tailnet"}
      SEAFILE_SERVER_PROTOCOL=https
      SEADOC_SERVER_URL=https://sf.${config.sops.placeholder."tailscale_api/tailnet"}/sdoc-server
      NOTIFICATION_SERVER_URL=https://sf.${config.sops.placeholder."tailscale_api/tailnet"}/notification
    '';
  };

  sops.templates."seafile/seahub_settings.py" = {
    content = ''
      # -*- coding: utf-8 -*-
      SECRET_KEY = "${config.sops.placeholder."seafile/seahub_secret_key"}"

      TIME_ZONE = 'Asia/Kolkata'

      CSRF_TRUSTED_ORIGINS = ["https://*.${config.sops.placeholder."tailscale_api/tailnet"}"]
      USE_X_FORWARDED_HOST = True
      SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
      SECURE_SSL_REDIRECT = True
      SESSION_COOKIE_SECURE = True
      CSRF_COOKIE_SECURE = True

      # OAuth Setup
      ENABLE_OAUTH = True
      OAUTH_CREATE_UNKNOWN_USER = True
      OAUTH_ACTIVATE_USER_AFTER_CREATION = False
      OAUTH_CLIENT_ID = "${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}"
      OAUTH_CLIENT_SECRET = "${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}"
      OAUTH_REDIRECT_URL = 'https://sf.${config.sops.placeholder."tailscale_api/tailnet"}/oauth/callback/'
      OAUTH_PROVIDER_DOMAIN = 'google.com'
      OAUTH_AUTHORIZATION_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
      OAUTH_TOKEN_URL = 'https://www.googleapis.com/oauth2/v4/token'
      OAUTH_USER_INFO_URL = 'https://www.googleapis.com/oauth2/v1/userinfo'
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
      EMAIL_HOST = '${config.sops.placeholder."email/smtp/host"}'
      EMAIL_HOST_USER = '${config.sops.placeholder."email/smtp/username"}'
      EMAIL_HOST_PASSWORD = '${config.sops.placeholder."email/smtp/password"}'
      EMAIL_PORT = 25
      DEFAULT_FROM_EMAIL = '${config.sops.placeholder."email/from/seafile"}'
      SERVER_EMAIL = DEFAULT_FROM_EMAIL
    '';
  };

  sops.templates."seafile/seadoc.env" = {
    content = ''
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      SEAFILE_SERVER_HOSTNAME=sf.${config.sops.placeholder."tailscale_api/tailnet"}
      SEAFILE_SERVER_PROTOCOL=https
    '';
  };

  sops.secrets = {
    "email/from/seafile" = { };
    "seafile/jwt_private_key" = { };
    "seafile/seahub_secret_key" = { };
  };

}
