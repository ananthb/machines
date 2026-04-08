# Centralized log aggregation pipeline:
#   systemd-journal-upload (all hosts, configured in nixos-common.nix)
#   → systemd-journal-remote (receives and stores per-host journals)
#   → Promtail (reads journals, pushes to VictoriaLogs)
#   → VictoriaLogs (stores and indexes, Grafana-queryable)
{
  config,
  pkgs,
  ...
}: {
  # --- journal-remote: receive journals from all hosts ---
  networking.firewall.allowedTCPPorts = [19532];

  services.journald.remote = {
    enable = true;
    listen = "http";
    port = 19532;
    settings.Remote.SplitMode = "host";
  };

  # --- VictoriaLogs: log storage and query engine ---
  systemd.services.victorialogs = {
    description = "VictoriaLogs";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    partOf = ["kedi.target"];
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "victorialogs";
      ExecStart = ''
        ${pkgs.victorialogs}/bin/victoria-logs \
          -storageDataPath=/var/lib/victorialogs \
          -httpListenAddr=:9428 \
          -retentionPeriod=90d
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  my-services.kediTargets.victorialogs = true;

  # --- Promtail: reads journals, pushes to VictoriaLogs via Loki API ---
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };

      positions.filename = "/var/lib/promtail/positions.yaml";

      clients = [
        {
          # VictoriaLogs accepts Loki-compatible push API
          url = "http://localhost:9428/insert/loki/api/v1/push?_stream_fields=host,unit,job";
        }
      ];

      scrape_configs = [
        {
          # Local journal (this host)
          job_name = "journal-local";
          journal = {
            max_age = "12h";
            labels = {
              host = config.networking.hostName;
              job = "systemd-journal";
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
            {
              source_labels = ["__journal_priority_keyword"];
              target_label = "priority";
            }
          ];
        }
        {
          # Remote journals from other hosts (received via journal-remote)
          job_name = "journal-remote";
          journal = {
            max_age = "12h";
            path = "/var/log/journal/remote";
            labels.job = "systemd-journal";
          };
          relabel_configs = [
            {
              source_labels = ["__journal__hostname"];
              target_label = "host";
            }
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
            {
              source_labels = ["__journal_priority_keyword"];
              target_label = "priority";
            }
          ];
        }
      ];
    };
  };

  # Promtail needs to read journal-remote's output
  systemd.services.promtail.serviceConfig.SupplementaryGroups = ["systemd-journal"];
}
