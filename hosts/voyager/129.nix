{...}: {
  imports = [
    ../../services/hass.nix
    ../../services/frigate.nix
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
      config = {
        recorder.db_url = "postgresql://@/hass";
        frigate.url = "http://localhost:5000";
      };
    };

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

  my-services.frigate = {
    enable = true;
    settings = {
      mqtt = {
        enabled = true;
        host = "endeavour";
      };

      detectors.coral = {
        type = "edgetpu";
        device = "usb";
      };

      detect.enabled = true;
      auth.enabled = false;
      tls.enabled = false;

      record = {
        enabled = true;
        retain = {
          days = 2;
          mode = "all";
        };
      };

      # TODO: update RTSP URLs when cameras are installed
      cameras = {
        "vigi_1".ffmpeg.inputs = [
          {
            path = "rtsp://VIGI_1_IP:554/stream1";
            roles = ["record"];
          }
        ];
        "vigi_2".ffmpeg.inputs = [
          {
            path = "rtsp://VIGI_2_IP:554/stream1";
            roles = ["record"];
          }
        ];
        "vigi_3".ffmpeg.inputs = [
          {
            path = "rtsp://VIGI_3_IP:554/stream1";
            roles = ["record"];
          }
        ];
        "vigi_4".ffmpeg.inputs = [
          {
            path = "rtsp://VIGI_4_IP:554/stream1";
            roles = ["record"];
          }
        ];
        "vigi_5".ffmpeg.inputs = [
          {
            path = "rtsp://VIGI_5_IP:554/stream1";
            roles = ["record"];
          }
        ];
        "vigi_6".ffmpeg.inputs = [
          {
            path = "rtsp://VIGI_6_IP:554/stream1";
            roles = ["record"];
          }
        ];
      };
    };
  };
}
