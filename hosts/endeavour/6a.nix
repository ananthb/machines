{
  config,
  hostname,
  pkgs,
  ...
}:

{
  services.home-assistant = {
    enable = true;
    package = pkgs.home-assistant.overrideAttrs (oldAttrs: {
      doInstallCheck = false;
    });
    openFirewall = true;
    extraPackages =
      python3Packages: with python3Packages; [
        aioimmich
        aiomealie
        aionut
        jellyfin-apiclient-python
        ollama
        psycopg2
        qbittorrent-api
        speedtest-cli
      ];
    extraComponents = [
      # baseline components
      "analytics"
      "default_config"
      "dhcp"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
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
      "bluetooth_adapters"
      "bluetooth_le_tracker"
      "broadlink"
      "camera"
      "cast"
      "ecovacs"
      "esphome"
      "luci"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      ecoflow_cloud
      frigate
      miraie
      prometheus_sensor
      smartir
      spook
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
          "127.0.0.0/8"
          "fdc0:6625:5195::0/64"
          "10.15.16.0/24"
        ];
        use_x_forwarded_for = true;
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
      };

      homeassistant = {
        name = "6A";
        unit_system = "metric";
        time_zone = "Asia/Kolkata";
        latitude = "!include ${config.sops.secrets."homes/6a/latitude".path}";
        longitude = "!include ${config.sops.secrets."homes/6a/longitude".path}";
        elevation = "!include ${config.sops.secrets."homes/6a/elevation".path}";
        temperature_unit = "C";
        currency = "INR";
        country = "IN";
        external_url = "https://6a.kedi.dev";
        internal_url = "http://${hostname}.local:8123";
      };

      smartir = { };

      fan = [
        {
          platform = "smartir";
          name = "Sylvia Plath Pedestal fan";
          unique_id = "sylvia_plath_pedestal_fan";
          device_code = "1170";
          controller_data = "remote.sylvia_plath_room_remote";
          power_sensor = "binary_sensor.fan_power";
        }
      ];

      # Example configuration.yaml entry
      device_tracker = [
        {
          platform = "ubus";
          host = "10.15.16.1";
          username = "!include ${config.sops.secrets."homes/6a/openwrt/username".path}";
          password = "!include ${config.sops.secrets."homes/6a/openwrt/password".path}";
        }
      ];
    };
  };

  services.frigate = {
    enable = true;
    hostname = "${hostname}.local";

    settings = {
      mqtt.enabled = false;

      record = {
        enabled = true;
        retain = {
          days = 2;
          mode = "all";
        };
      };

      ffmpeg.hwaccel_args = "preset-vaapi";

      cameras."frontdoor" = {
        ffmpeg.inputs = [
          {
            path = "rtsp://192.168.1.142:8000/test1";
            input_args = "preset-rtsp-restream";
            roles = [ "record" ];
          }
        ];
      };
    };
  };

  services.nginx.virtualHosts."${hostname}.local" = {
    listen = [
      {
        addr = "[::]";
        port = 8967;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    8967 # frigate
  ];

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

  systemd.services."home-assistant-backup" = {
    startAt = "daily";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${config.my-scripts.kopia-backup} /var/lib/hass/backups";
    };
  };

  sops.secrets = {
    "homes/6a/latitude".owner = config.users.users.hass.name;
    "homes/6a/longitude".owner = config.users.users.hass.name;
    "homes/6a/elevation".owner = config.users.users.hass.name;
    "homes/6a/openwrt/username".owner = config.users.users.hass.name;
    "homes/6a/openwrt/password".owner = config.users.users.hass.name;
  };
}
