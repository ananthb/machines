{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  services = {
    home-assistant = {
      enable = true;
      package = pkgs-unstable.home-assistant.overrideAttrs (oldAttrs: {
        doInstallCheck = false;
      });
      openFirewall = true;
      extraPackages =
        python3Packages: with python3Packages; [
          psycopg2
        ];
      extraComponents = [
        # Components required to complete the onboarding
        "analytics"
        "google_translate"
        "met"
        "radio_browser"
        "shopping_list"

        "default_config"
        "dhcp"

        # "radio_browser"
        # "shopping_list"
        # Recommended for fast zlib compression
        # https://www.home-assistant.io/integrations/isal
        "isal"

        # home stuff
        "androidtv"
        "androidtv_remote"
        "apple_tv"
        "bluetooth"
        "bluetooth_le_tracker"
        "bluetooth_tracker"
        "broadlink"
        "camera"
        "cast"
        "ecovacs"
        "esphome"
        "luci"
      ];
      customComponents = with pkgs-unstable.home-assistant-custom-components; [
        frigate
        miraie
        prometheus_sensor
        smartir
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };

        recorder = {
          db_url = "postgresql://@/hass";
        };

        http = {
          trusted_proxies = [
            "::1"
            "127.0.0.1"
          ];
          use_x_forwarded_for = true;
          ip_ban_enabled = true;
          login_attempts_threshold = 5;
        };

        homeassistant = {
          name = "6A";
          unit_system = "metric";
          time_zone = "Asia/Kolkata";
          latitude = "!include ${config.sops.secrets."home/6a/latitude".path}";
          longitude = "!include ${config.sops.secrets."home/6a/longitude".path}";
          elevation = "!include ${config.sops.secrets."home/6a/elevation".path}";
          temperature_unit = "C";
          currency = "INR";
          country = "IN";
          external_url = "!include ${config.sops.templates."fqdns/ha-6a.txt".path}";
          internal_url = "http://voyager.local:8123";
        };
      };
    };

    esphome = {
      enable = true;
    };

    tsnsrv.services."6a" = {
      funnel = true;
      urlParts.port = 8123;
    };
    tsnsrv.services.esp = {
      urlParts.port = 6053;
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  systemd.timers."home-assistant-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  systemd.services."home-assistant-backup" = {
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      #!/bin/bash

      set -euo pipefail

      backup_target="/var/lib/hass"
      snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"
      dump_file="$snapshot_target/db.dump"

      systemctl stop home-assistant.service

      cleanup() {
        rm -f "$dump_file"
        rm -rf "$snapshot_target"
        systemctl start home-assistant.service
      }
      trap cleanup EXIT

      # Dump database
      ${pkgs.sudo-rs}/bin/sudo -u hass \
        ${pkgs.postgresql_16}/bin/pg_dump \
          -Fc -U hass hass > "$dump_file"
      printf 'Dumped database to %s' "$dump_file"

      ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target"

      ${config.my-scripts.kopia-backup} "$snapshot_target"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  sops.secrets."home/6a/latitude".owner = config.users.users.hass.name;
  sops.secrets."home/6a/longitude".owner = config.users.users.hass.name;
  sops.secrets."home/6a/elevation".owner = config.users.users.hass.name;
  sops.templates."fqdns/ha-6a.txt" = {
    owner = config.users.users.hass.name;
    content = "https://6a.${config.sops.placeholder."tailscale_api/tailnet"}";
  };
}
