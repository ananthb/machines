{
  pkgs,
  ...
}@args:
(import ../../services/hass.nix {
  name = "6A";
  secretsPrefix = "home-assistant/6a";
  externalUrl = "https://6a.kedi.dev";
  internalUrl = "http://endeavour.local:8123";
  extraPackages =
    python3Packages: with python3Packages; [
      adguardhome
      aioimmich
      aiomealie
      aionut
      jellyfin-apiclient-python
      psycopg2
      qbittorrent-api
    ];
  extraComponents = [
    "broadlink"
    "luci"
  ];
  extraConfig = {
    recorder = {
      db_url = "postgresql://@/hass";
    };

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
        host = "atlantis";
        username = "!include /run/secrets/openwrt/atlantis/username";
        password = "!include /run/secrets/openwrt/atlantis/password";
      }
    ];
  };
  extraSecrets = {
    "openwrt/atlantis/username" = null;
    "openwrt/atlantis/password" = null;
  };
  extraModules = {
    imports = [ ../../services/monitoring/postgres.nix ];
    services = {
      frigate = {
        enable = true;
        hostname = "endeavour.local";

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

      nginx.virtualHosts."endeavour.local" = {
        listen = [
          {
            addr = "[::]";
            port = 8967;
          }
        ];
      };

      postgresql = {
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
    };
  };
})
  (args // { inherit pkgs; })
