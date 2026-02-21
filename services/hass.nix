{
  name,
  secretsPrefix,
  externalUrl,
  internalUrl,
  extraPackages ? (_: [ ]),
  extraComponents ? [ ],
  extraCustomComponents ? [ ],
  extraTrustedProxies ? [ ],
  extraConfig ? { },
  extraModules ? { },
}:
{
  config,
  lib,
  pkgs,
  ...
}:
lib.recursiveUpdate (
  let
    vs = config.vault-secrets.secrets;
    secretName = lib.replaceStrings [ "/" ] [ "-" ] secretsPrefix;
  in
  {
    services.home-assistant = {
      enable = true;
      package = pkgs.home-assistant.overrideAttrs (_oldAttrs: {
        doInstallCheck = false;
      });
      openFirewall = true;
      extraPackages =
        python3Packages:
        with python3Packages;
        [
          ollama
          speedtest-cli
        ]
        ++ (extraPackages python3Packages);
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
        "camera"
        "cast"
        "ecovacs"
        "esphome"
      ]
      ++ extraComponents;
      customComponents =
        with pkgs.home-assistant-custom-components;
        [
          ecoflow_cloud
          frigate
          miraie
          prometheus_sensor
          smartir
          spook
        ]
        ++ extraCustomComponents;
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };

        prometheus = { };

        http = {
          trusted_proxies = [
            "::1"
            "127.0.0.0/8"
          ]
          ++ extraTrustedProxies;
          use_x_forwarded_for = true;
          ip_ban_enabled = true;
          login_attempts_threshold = 5;
        };

        homeassistant = {
          inherit name;
          unit_system = "metric";
          time_zone = "Asia/Kolkata";
          latitude = "!include ${vs.${secretName}}/latitude";
          longitude = "!include ${vs.${secretName}}/longitude";
          elevation = "!include ${vs.${secretName}}/elevation";
          temperature_unit = "C";
          currency = "INR";
          country = "IN";
          external_url = externalUrl;
          internal_url = internalUrl;
        };

        smartir = { };
      }
      // extraConfig;
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

    vault-secrets.secrets.${secretName} = {
      services = [ "home-assistant" ];
      user = config.users.users.hass.name;
      inherit (config.users.users.hass) group;
    };

  }
) extraModules
