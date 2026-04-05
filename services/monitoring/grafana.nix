{
  config,
  inputs,
  ...
}: let
  vs = config.vault-secrets.secrets;
  datasourceUid = "P3D437DB70E32EE8A";

  # Helper to build a Grafana alert rule with less boilerplate.
  mkAlert = {
    uid,
    title,
    expr,
    threshold ? 1,
    thresholdType ? "lt",
    duration ? "1m",
    keepFiring ? null,
    noData ? "NoData",
    muteAtNight ? false,
    summary,
    description ? "{{ $labels.instance }}",
  }:
    {
      inherit uid title;
      condition = "C";
      data = [
        {
          refId = "A";
          relativeTimeRange = {
            from = 600;
            to = 0;
          };
          inherit datasourceUid;
          model = {
            editorMode = "builder";
            inherit expr;
            instant = true;
            intervalMs = 1000;
            legendFormat = "__auto";
            maxDataPoints = 43200;
            range = false;
            refId = "A";
          };
        }
        {
          refId = "C";
          datasourceUid = "__expr__";
          model = {
            conditions = [
              {
                evaluator = {
                  params = [threshold];
                  type = thresholdType;
                };
                operator.type = "and";
                query.params = ["C"];
                reducer = {
                  params = [];
                  type = "last";
                };
                type = "query";
              }
            ];
            datasource = {
              type = "__expr__";
              uid = "__expr__";
            };
            expression = "A";
            intervalMs = 1000;
            maxDataPoints = 43200;
            refId = "C";
            type = "threshold";
          };
        }
      ];
      noDataState = noData;
      execErrState = "Error";
      for = duration;
      isPaused = false;
      annotations = {
        inherit summary description;
      };
      notification_settings =
        {
          receiver = "grafana-default-telegram";
        }
        // (
          if muteAtNight
          then {mute_time_intervals = ["Indian Nights"];}
          else {}
        );
    }
    // (
      if keepFiring != null
      then {keepFiringFor = keepFiring;}
      else {}
    );
in {
  imports = [
    ./postgres.nix
  ];

  services = {
    grafana = {
      enable = true;
      settings = {
        database = {
          type = "postgres";
          host = "/run/postgresql";
          name = "grafana";
          user = "grafana";
        };

        server = {
          http_addr = "::";
          domain = "metrics.kedi.dev";
          root_url = "https://metrics.kedi.dev";
        };

        users = {
          allow_sign_up = false;
        };

        "auth.basic" = {
          enabled = false;
        };

        auth = {
          disable_login_form = true;
        };

        "auth.google" = {
          enabled = true;
          client_id = "$__file{${vs.grafana}/oauth_client_id}";
          client_secret = "$__file{${vs.grafana}/oauth_client_secret}";
          allow_sign_up = false;
          auto_login = true;
          skip_org_role_sync = true;
          scopes = "openid email profile";
        };

        security = {
          secret_key = "$__file{${vs.grafana}/secret_key}";
        };
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            url = "http://localhost:8428";
            name = "VictoraMetrics";
            type = "prometheus";
            jsonData = {
              httpMethod = "POST";
              manageAlerts = true;
            };
          }
        ];
        dashboards.settings.providers = [
          {
            name = "applications";
            orgId = 1;
            folder = "Applications";
            type = "file";
            disableDeletion = false;
            editable = true;
            options = {
              path = "${./grafana/dashboards/Applications}";
            };
          }
          {
            name = "infrastructure";
            orgId = 1;
            folder = "Infrastructure";
            type = "file";
            disableDeletion = false;
            editable = true;
            options = {
              path = "${./grafana/dashboards/Infrastructure}";
            };
          }
          {
            name = "starla";
            orgId = 1;
            folder = "Applications";
            type = "file";
            disableDeletion = false;
            editable = true;
            options = {
              path = "${inputs.starla}/grafana";
            };
          }
        ];
        alerting = {
          rules.settings = {
            apiVersion = 1;
            groups = [
              {
                orgId = 1;
                name = "Right About Now";
                folder = "Applications";
                interval = "30s";
                rules = [
                  (mkAlert {
                    uid = "dex9yo4k0n6dcb";
                    title = "Application Down";
                    expr = ''(probe_success{type="app"} or up{type="app", job!~"blackbox_.*"} or up{job="apps", role="server"})'';
                    keepFiring = "1m";
                    muteAtNight = true;
                    summary = ''{{ if $labels.app }}{{ $labels.app }}{{ else }}{{ $labels.instance }}{{ end }} is down (seen from {{ reReplaceAll `blackbox_.*-` `` $labels.job }})'';
                  })
                  (mkAlert {
                    uid = "aex9ssl4k0n6dca";
                    title = "SSL Certificate Expiring";
                    expr = ''(probe_ssl_earliest_cert_expiry - time()) / 86400'';
                    threshold = 7;
                    duration = "1h";
                    muteAtNight = true;
                    summary = "SSL cert for {{ $labels.instance }} expires in {{ $value }} days";
                  })
                ];
              }
              {
                orgId = 1;
                name = "Right About Now";
                folder = "Infrastructure";
                interval = "30s";
                rules = [
                  (mkAlert {
                    uid = "fexk4g07p6134a";
                    title = "Home Network Down";
                    expr = ''up{role=~"router|server", type="node"}'';
                    summary = "{{ $labels.instance }} is unreachable";
                  })
                  (mkAlert {
                    uid = "ff9dwibe8wqv4a";
                    title = "NUT UPS AC Power Outage";
                    expr = "network_ups_tools_input_voltage";
                    threshold = 200;
                    duration = "30s";
                    summary = "AC power lost on UPS {{ $labels.instance }}";
                  })
                  (mkAlert {
                    uid = "cf9dwz9m0fkzka";
                    title = "EcoFlow Battery AC Power Outage";
                    expr = "ecoflow_inv_ac_in_vol";
                    threshold = 200000;
                    duration = "30s";
                    summary = "AC power lost on EcoFlow {{ $labels.instance }}";
                  })
                  (mkAlert {
                    uid = "gex1disk0n6dcf";
                    title = "Disk Space Critical";
                    expr = ''node_filesystem_avail_bytes{mountpoint=~"/|/srv|/var/garnix/persist"} / node_filesystem_size_bytes * 100'';
                    threshold = 10;
                    duration = "5m";
                    summary = "{{ $labels.instance }} {{ $labels.mountpoint }} has {{ $value | printf \"%.0f\" }}% free";
                  })
                  (mkAlert {
                    uid = "hex2mem0n6dcg";
                    title = "High Memory Pressure";
                    expr = ''node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100'';
                    threshold = 10;
                    duration = "5m";
                    muteAtNight = true;
                    summary = "{{ $labels.instance }} has {{ $value | printf \"%.0f\" }}% memory available";
                  })
                  (mkAlert {
                    uid = "iex3sysd0n6dch";
                    title = "Systemd Service Failed";
                    expr = ''node_systemd_unit_state{state="failed"}'';
                    threshold = 1;
                    thresholdType = "gt";
                    duration = "2m";
                    muteAtNight = true;
                    summary = "{{ $labels.name }} failed on {{ $labels.instance }}";
                  })
                  (mkAlert {
                    uid = "jex4bkup0n6dci";
                    title = "Backup Stale";
                    expr = ''(time() - kopia_backups_total) / 3600'';
                    threshold = 48;
                    thresholdType = "gt";
                    duration = "1h";
                    noData = "OK";
                    muteAtNight = true;
                    summary = "No backup for {{ $labels.instance }} in {{ $value | printf \"%.0f\" }}h";
                  })
                  (mkAlert {
                    uid = "kex5inet0n6dcj";
                    title = "Internet Connectivity Lost";
                    expr = ''avg by (job) (probe_success{type="internet-dns"})'';
                    duration = "2m";
                    summary = "Internet down (seen from {{ reReplaceAll `blackbox_.*-` `` $labels.job }})";
                  })
                ];
              }
            ];
          };
          policies.settings = {
            apiVersion = 1;
            policies = [
              {
                orgId = 1;
                receiver = "grafana-default-telegram";
                group_by = [
                  "grafana_folder"
                  "alertname"
                ];
                group_wait = "5m";
                group_interval = "5m";
                repeat_interval = "4h";
              }
            ];
          };
          contactPoints.path = "${vs.grafana}/contactpoints.yaml";
        };
      };
    };

    postgresql = {
      enable = true;
      ensureDatabases = ["grafana"];
      ensureUsers = [
        {
          name = "grafana";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [3000];

  vault-secrets.secrets.grafana = {
    services = ["grafana"];
    group = config.users.groups.grafana.name;
  };
}
