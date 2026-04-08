{...}: {
  imports = [
    ../../services/hass.nix
    ../../services/monitoring/postgres.nix
  ];

  my-services.hass = {
    enable = true;
    name = "#129";
    secretsPrefix = "homes/129";
    externalUrl = "https://129.kedi.dev";
    internalUrl = "http://voyager.local:8123";
  };

  services = {
    home-assistant = {
      extraPackages = ps: [ps.aionut ps.psycopg2];
      extraComponents = ["luci"];
      config.recorder.db_url = "postgresql://@/hass";
    };

    frigate = {
      enable = true;
      hostname = "voyager.local";
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

        cameras."frontdoor".ffmpeg.inputs = [
          {
            path = "rtsp://192.168.1.142:8000/test1";
            input_args = "preset-rtsp-restream";
            roles = ["record"];
          }
        ];
      };
    };

    nginx.virtualHosts."voyager.local".listen = [
      {
        addr = "[::]";
        port = 8967;
      }
    ];

    postgresql = {
      enable = true;
      ensureDatabases = ["hass"];
      ensureUsers = [
        {
          name = "hass";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };
  };
}
