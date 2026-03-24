{
  config,
  pkgs,
  ...
} @ args:
(import ../../services/hass.nix {
  name = "6A";
  secretsPrefix = "home-assistant/6a";
  externalUrl = "https://6a.kedi.dev";
  internalUrl = "http://endeavour.local:8123";
  extraPackages = python3Packages:
    with python3Packages; [
      adguardhome
      aioimmich
      aiomealie
      aionut
      jellyfin-apiclient-python
      psycopg2
      pywizlight
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

    frigate = {
      url = "http://enterprise:8967";
    };

    automation = [
      {
        alias = "Frigate - Front Door Person Detected";
        mode = "single";
        trigger = [
          {
            platform = "state";
            entity_id = "binary_sensor.front_door_cam_person";
            to = "on";
          }
        ];
        action = [
          {
            service = "notify.notify";
            data = {
              message = "Person detected at front door cam.";
            };
          }
        ];
      }
      {
        alias = "Turn off ACs running for more than 4 hours";
        mode = "single";
        trigger = [
          {
            platform = "time_pattern";
            minutes = "/5";
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ states.climate | selectattr('state', 'ne', 'off') | selectattr('last_changed', 'lt', now() - timedelta(hours=4)) | list | count > 0 }}";
          }
        ];
        action = [
          {
            service = "climate.turn_off";
            target = {
              entity_id = "{{ states.climate | selectattr('state', 'ne', 'off') | selectattr('last_changed', 'lt', now() - timedelta(hours=4)) | map(attribute='entity_id') | list }}";
            };
          }
        ];
      }
      {
        alias = "Turn off ACs when nobody is home";
        mode = "restart";
        trigger = [
          {
            platform = "state";
            entity_id = [
              "person.ananth"
              "person.arul_priya"
            ];
            to = "not_home";
          }
        ];
        action = [
          {
            delay = "00:15:00";
          }
          {
            condition = "state";
            entity_id = "person.ananth";
            state = "not_home";
          }
          {
            condition = "state";
            entity_id = "person.arul_priya";
            state = "not_home";
          }
          {
            service = "climate.turn_off";
            target = {
              entity_id = "{{ states.climate | map(attribute='entity_id') | list }}";
            };
          }
        ];
      }
    ];

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
        username = "!include /run/secrets/openwrt-atlantis/username";
        password = "!include /run/secrets/openwrt-atlantis/password";
      }
    ];
  };
  extraModules = {
    imports = [../../services/monitoring/postgres.nix];
    vault-secrets.secrets.openwrt-atlantis = {
      services = ["home-assistant"];
      user = config.users.users.hass.name;
      inherit (config.users.users.hass) group;
    };
    services = {
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
  };
})
(args // {inherit pkgs;})
