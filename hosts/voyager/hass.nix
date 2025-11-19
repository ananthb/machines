{
  config,
  pkgs-unstable,
  ...
}:

{
  services.home-assistant = {
    enable = true;
    package = pkgs-unstable.home-assistant.overrideAttrs (oldAttrs: {
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
      #"esphome"
      "luci"
    ];
    customComponents = with pkgs-unstable.home-assistant-custom-components; [
      ecoflow_cloud
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
        internal_url = "http://voyager.local:8123";
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
          host = "atlantis.local";
          username = "!include ${config.sops.secrets."homes/6a/openwrt/username".path}";
          password = "!include ${config.sops.secrets."homes/6a/openwrt/password".path}";
        }
        {
          platform = "ubus";
          host = "intrepid.local";
          username = "!include ${config.sops.secrets."homes/6a/openwrt/username".path}";
          password = "!include ${config.sops.secrets."homes/6a/openwrt/password".path}";
        }
        {
          platform = "ubus";
          host = "ds9.local";
          username = "!include ${config.sops.secrets."homes/6a/openwrt/username".path}";
          password = "!include ${config.sops.secrets."homes/6a/openwrt/password".path}";
        }
      ];
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
