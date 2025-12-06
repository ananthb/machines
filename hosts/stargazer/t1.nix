{
  config,
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
        ollama
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
      "bluetooth_le_tracker"
      "bluetooth_tracker"
      "camera"
      "cast"
      "ecovacs"
      "esphome"
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

      http = {
        trusted_proxies = [
          "::1"
          "127.0.0.0/8"
        ];
        use_x_forwarded_for = true;
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
      };

      homeassistant = {
        name = "T1";
        unit_system = "metric";
        time_zone = "Asia/Kolkata";
        latitude = "!include ${config.sops.secrets."homes/t1/latitude".path}";
        longitude = "!include ${config.sops.secrets."homes/t1/longitude".path}";
        elevation = "!include ${config.sops.secrets."homes/t1/elevation".path}";
        temperature_unit = "C";
        currency = "INR";
        country = "IN";
        external_url = "https://t1.kedi.dev";
        internal_url = "http://stargazer.local:8123";
      };

      smartir = { };
    };
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
    "homes/t1/latitude".owner = config.users.users.hass.name;
    "homes/t1/longitude".owner = config.users.users.hass.name;
    "homes/t1/elevation".owner = config.users.users.hass.name;
  };
}
