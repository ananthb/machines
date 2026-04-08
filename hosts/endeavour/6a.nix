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

    input_boolean = {
      roomba_ran_today = {
        name = "Roomba ran today";
        icon = "mdi:robot-vacuum";
      };
    };

    automation = [
      {
        alias = "Run Roomba at 8am and 8pm";
        mode = "single";
        trigger = [
          {
            platform = "time";
            at = "08:00:00";
          }
          {
            platform = "time";
            at = "20:00:00";
          }
        ];
        action = [
          {
            service = "vacuum.start";
            target = {
              entity_id = "{{ states.vacuum | map(attribute='entity_id') | list }}";
            };
          }
        ];
      }
      {
        alias = "Run Roomba when everyone leaves home";
        mode = "single";
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
        condition = [
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
            condition = "state";
            entity_id = "input_boolean.roomba_ran_today";
            state = "off";
          }
        ];
        action = [
          {
            service = "vacuum.start";
            target = {
              entity_id = "{{ states.vacuum | map(attribute='entity_id') | list }}";
            };
          }
        ];
      }
      {
        alias = "Record Roomba run when docked after cleaning";
        mode = "single";
        trigger = [
          {
            platform = "template";
            value_template = "{{ states.vacuum | selectattr('state', 'eq', 'docked') | list | count == states.vacuum | list | count and states.vacuum | list | count > 0 }}";
          }
        ];
        condition = [
          {
            condition = "state";
            entity_id = "input_boolean.roomba_ran_today";
            state = "off";
          }
        ];
        action = [
          {
            service = "input_boolean.turn_on";
            target.entity_id = "input_boolean.roomba_ran_today";
          }
        ];
      }
      {
        alias = "Return Roomba to dock if idle";
        mode = "single";
        trigger = [
          {
            platform = "time_pattern";
            minutes = "/15";
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ states.vacuum | rejectattr('state', 'in', ['cleaning', 'docked', 'unavailable', 'unknown']) | list | count > 0 }}";
          }
        ];
        action = [
          {
            service = "vacuum.return_to_base";
            target = {
              entity_id = "{{ states.vacuum | rejectattr('state', 'in', ['cleaning', 'docked', 'unavailable', 'unknown']) | map(attribute='entity_id') | list }}";
            };
          }
        ];
      }
      {
        alias = "Reset Roomba ran today flag at midnight";
        mode = "single";
        trigger = [
          {
            platform = "time";
            at = "00:00:00";
          }
        ];
        action = [
          {
            service = "input_boolean.turn_off";
            target.entity_id = "input_boolean.roomba_ran_today";
          }
        ];
      }
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
              title = "Person at Front Door";
              message = "Person detected at front door cam.";
              data = {
                image = "/api/frigate/notifications/front_door_cam/person/snapshot.jpg";
              };
            };
          }
        ];
      }
      {
        alias = "Frigate - Package Delivery Detected";
        mode = "single";
        trigger = [
          {
            platform = "state";
            entity_id = "binary_sensor.front_door_cam_person";
            to = "on";
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ trigger.to_state.attributes.get('objects', []) | select('eq', 'package') | list | count > 0 }}";
          }
        ];
        action = [
          {
            service = "notify.notify";
            data = {
              title = "Package Delivered";
              message = "A package was detected at the front door.";
              data = {
                image = "/api/frigate/notifications/front_door_cam/person/snapshot.jpg";
              };
            };
          }
        ];
      }
      {
        alias = "Turn off fans when nobody is home";
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
            delay = "00:05:00";
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
            service = "fan.turn_off";
            target = {
              entity_id = "{{ states.fan | map(attribute='entity_id') | list }}";
            };
          }
        ];
      }
      {
        alias = "Alert on new network device";
        mode = "single";
        trigger = [
          {
            platform = "event";
            event_type = "entity_registry_updated";
            event_data = {
              action = "create";
            };
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ trigger.event.data.entity_id.startswith('device_tracker.') }}";
          }
        ];
        action = [
          {
            service = "notify.notify";
            data = {
              title = "New Device on Network";
              message = "New device detected: {{ state_attr(trigger.event.data.entity_id, 'friendly_name') | default(trigger.event.data.entity_id) }}";
            };
          }
        ];
      }
      {
        alias = "Weekly home summary";
        mode = "single";
        trigger = [
          {
            platform = "time";
            at = "09:00:00";
          }
        ];
        condition = [
          {
            condition = "time";
            weekday = ["sun"];
          }
        ];
        action = [
          {
            service = "notify.notify";
            data = {
              title = "Weekly Home Summary";
              message = ''
                Devices online: {{ states.device_tracker | selectattr('state', 'eq', 'home') | list | count }}
                Vacuums: {{ states.vacuum | map(attribute='state') | list | join(', ') }}
                Climate: {{ states.climate | selectattr('state', 'ne', 'off') | list | count }} running
                Low battery: {{ states.sensor | selectattr('attributes.device_class', 'defined') | selectattr('attributes.device_class', 'eq', 'battery') | selectattr('state', 'lt', '20') | list | count }} devices
              '';
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
