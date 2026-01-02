(import ../../services/hass.nix {
  name = "6A";
  secretsPrefix = "homes/6a";
  externalUrl = "https://6a.kedi.dev";
  internalUrl = "http://endeavour.local:8123";
  extraPackages =
    python3Packages: with python3Packages; [
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
  extraTrustedProxies = [
    "fdc0:6625:5195::0/64"
    "10.15.16.0/24"
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
        host = "10.15.16.1";
        username = "!include /run/secrets/homes/6a/openwrt/username";
        password = "!include /run/secrets/homes/6a/openwrt/password";
      }
    ];
  };
  extraSecrets = {
    "homes/6a/openwrt/username" = null;
    "homes/6a/openwrt/password" = null;
  };
  extraModules = {
    services.frigate = {
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

    services.nginx.virtualHosts."endeavour.local" = {
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
  };
})
