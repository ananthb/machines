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
            environmentFiles = [ "${vs.seafile}/seafile.env" ];
          };
          serviceConfig = {
            Restart = "on-failure";
            ExecStartPre = ''
              ${pkgs.coreutils}/bin/cp \
                ${vs.seafile}/seahub_settings.py \
                /srv/seafile/seafile-server/seafile/conf/seahub_settings.py
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
            environmentFiles = [ "${vs.seafile}/notification-server.env" ];
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
            environmentFiles = [ "${vs.seafile}/md-server.env" ];
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
            environmentFiles = [ "${vs.seafile}/thumbnail-server.env" ];
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
            environmentFiles = [ "${vs.seafile}/ai.env" ];
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
            environmentFiles = [ "${vs.seafile}/seadoc.env" ];
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
