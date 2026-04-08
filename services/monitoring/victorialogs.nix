# Centralized log aggregation pipeline:
#   systemd-journal-upload (all hosts, configured in nixos-common.nix)
#   → systemd-journal-remote (receives and stores per-host journals)
#   → fluent-bit (reads journals, pushes to VictoriaLogs)
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
          -retentionPeriod=30d
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  my-services.kediTargets.victorialogs = true;

  # --- fluent-bit: reads journals, pushes to VictoriaLogs via Loki API ---
  services.fluent-bit = {
    enable = true;
    settings = {
      pipeline = {
        inputs = [
          {
            name = "systemd";
            tag = "journal.local";
            read_from_tail = "on";
            db = "/var/lib/fluent-bit/journal-local.db";
          }
          {
            name = "systemd";
            tag = "journal.remote";
            path = "/var/log/journal/remote";
            read_from_tail = "on";
            db = "/var/lib/fluent-bit/journal-remote.db";
          }
        ];
        filters = [
          {
            name = "modify";
            match = "journal.local";
            set = "host ${config.networking.hostName}";
          }
          {
            name = "modify";
            match = "journal.remote";
            rename = "_HOSTNAME host";
          }
          {
            name = "modify";
            match = "*";
            rename = "_SYSTEMD_UNIT unit";
          }
          {
            name = "modify";
            match = "*";
            rename = "PRIORITY priority";
          }
        ];
        outputs = [
          {
            name = "loki";
            match = "*";
            host = "localhost";
            port = 9428;
            uri = "/insert/loki/api/v1/push?_stream_fields=host,unit,job";
            labels = "job=systemd-journal";
            label_keys = "$host,$unit,$priority";
            auto_kubernetes_labels = "off";
          }
        ];
      };
    };
  };

  systemd.services.fluent-bit.serviceConfig.StateDirectory = "fluent-bit";
}
