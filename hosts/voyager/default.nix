{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../linux

    ./hardware-configuration.nix
    ./hass.nix
    ./monitoring.nix
  ];

  # System packages
  environment.systemPackages = [ ];

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  power.ups = {
    enable = true;
    mode = "netclient";

    users = {
      "nutmon" = {
        passwordFile = config.sops.secrets."nut/users/nutmon".path;
        upsmon = "primary";
      };
    };

    upsmon.monitor."apc1@endeavour" = {
      powerValue = 1;
      user = "nutmon";
    };
  };

  # Actual Budget
  services.actual.enable = true;
  services.actual.package = pkgs.unstable.actual-server;
  services.actual.settings.port = 3100;
  services.tsnsrv.services.ab = {
    funnel = true;
    urlParts.host = "localhost";
    urlParts.port = 3100;
  };
  systemd.services.actual.serviceConfig.EnvironmentFile =
    config.sops.templates."actual/config.env".path;

  sops.templates."actual/config.env" = {
    content = ''
      ACTUAL_OPENID_DISCOVERY_URL="https://accounts.google.com/.well-known/openid-configuration"
      ACTUAL_OPENID_SERVER_HOSTNAME="https://ab.${config.sops.placeholder."tailscale_api/tailnet"}"
      ACTUAL_OPENID_CLIENT_ID="${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}"
      ACTUAL_OPENID_CLIENT_SECRET="${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}"
    '';
  };
  systemd.timers."actual-budget-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services."actual-budget-backup" = {
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      #!/bin/bash

      set -euo pipefail

      backup_target="/var/lib/actual"
      systemctl stop actual-budget.service
      snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

      cleanup() {
        rm -rf "$snapshot_target"
        systemctl start actual-budget.service
      }
      trap cleanup EXIT

      ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target" 
      ${config.my-scripts.kopia-backup} "$snapshot_target"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # Radicale
  services = {
    radicale = {
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

    tsnsrv.services.cal = {
      funnel = true;
      urlParts.port = 5232;
    };
  };
  systemd.timers."radicale-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services."radicale-backup" = {
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      #!/bin/bash

      set -euo pipefail

      backup_target="/var/lib/radicale"
      systemctl stop radicale.service
      snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

      cleanup() {
        rm -rf "$snapshot_target"
        systemctl start radicale.service
      }
      trap cleanup EXIT

      ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target" 
      ${config.my-scripts.kopia-backup} "$snapshot_target"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  sops.secrets."radicale/htpasswd".owner = "radicale";

  # Jellyseerr
  services = {
    jellyseerr.enable = true;

    tsnsrv.services.watch = {
      funnel = true;
      urlParts.port = 5055;
    };

    postgresql = {
      enable = true;
      ensureDatabases = [ "jellyseerr" ];
      ensureUsers = [
        {
          name = "jellyseerr";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };
  };

  systemd.services = {
    tsnsrv-watch.wants = [ "jellyseerr.service" ];
    tsnsrv-watch.after = [ "jellyseerr.service" ];

    jellyseerr.environment = {
      DB_TYPE = "postgres";
      DB_SOCKET_PATH = "/var/run/postgresql";
      DB_USER = "jellyseerr";
      DB_NAME = "jellyseerr";
    };
  };

  # secrets
  sops.secrets."email/smtp/username".owner = config.users.users.grafana.name;
  sops.secrets."email/smtp/password".owner = config.users.users.grafana.name;
  sops.secrets."email/smtp/host".owner = config.users.users.grafana.name;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
