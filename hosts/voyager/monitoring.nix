{ config, pkgs, ... }:

{
  services = {
    victoriametrics = {
      enable = true;
      retentionPeriod = "1y";
      extraOptions = [
        "-enableTCP6"
      ];
      prometheusConfig = {
        global.scrape_interval = "10s";

        /**
          Label definitions:

          1. type: node|app|exporter|internet-dns|internet-host
          2. role: server|router|canary|ups
        */

        scrape_configs = [
          {
            job_name = "blackbox_exporter";
            static_configs = [
              {
                targets = [ "localhost:9115" ];
                labels.type = "exporter";
              }
            ];
          }
          {
            job_name = "blackbox_ping";
            metrics_path = "/probe";
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "localhost:9115";
              }
            ];
            params.module = [ "icmp" ];
            static_configs = [
              {
                targets = [ "endeavour.local" ];
                labels.type = "node";
                labels.os = "linux";
                labels.role = "server";
              }
              {
                targets = [
                  "enterprise.local"
                  "discovery.local"
                ];
                labels.type = "node";
                labels.os = "darwin";
              }
              {
                targets = [
                  "atlantis.local"
                  "intrepid.local"
                ];
                labels.type = "node";
                labels.os = "openwrt";
                labels.role = "router";
              }
              {
                targets = [
                  "2001:4860:4860::8888"
                  "2001:4860:4860::8844"
                  "2606:4700:4700::1001"
                  "2606:4700:4700::1111"
                  "8.8.8.8"
                  "8.8.4.4"
                  "1.1.1.1"
                  "1.0.0.1"
                ];
                labels.role = "canary";
                labels.type = "internet-dns";
              }
            ];
          }
          {
            job_name = "blackbox_http_2xx";
            metrics_path = "/probe";
            params.module = [ "http_2xx" ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "localhost:9115";
              }
            ];
            static_configs = [
              {
                targets = [
                  "http://endeavour:8096" # jellyfin
                  "http://localhost:2283" # immich-server
                  "http://endeavour:9696" # prowlarr
                  "http://endeavour:7878" # radarr
                  "http://endeavour:8989" # sonarr
                ];
                labels.type = "app";
                labels.role = "server";
              }
              {
                targets = [
                  "http://atlantis.local"
                  "http://intrepid.local"
                ];
                labels.os = "openwrt";
                labels.type = "node";
                labels.role = "router";
              }
            ];
          }
          {
            job_name = "blackbox_https_2xx";
            metrics_path = "/probe";
            params.module = [ "https_2xx" ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "localhost:9115";
              }
            ];
            static_configs = [
              {
                targets = [
                  "https://actual.kedi.dev"
                  "https://bhaskararaman.com"
                  "https://calculon.tech"
                  "https://coredump.blog"
                  "https://devhuman.net"
                  "https://drvibhu.com"
                  "https://futuraphysio.com"
                  "https://lilaartscentre.com"
                  "https://shakthipalace.com"
                ];
                labels.type = "internet-host";
                labels.role = "server";
              }
              {
                targets = [
                  "https://www.google.com"
                  "https://www.cloudflare.com"
                ];
                labels.type = "internet-host";
                labels.role = "canary";
              }
            ];
            file_sd_configs = [
              {
                files = [
                  config.sops.templates."victoriametrics/file_sd_configs/blackbox_https_2xx.json".path
                ];
              }
            ];
          }
          {
            job_name = "network";
            static_configs = [
              {
                targets = [
                  "atlantis.local:9100"
                  "intrepid.local:9100"
                ];
                labels.os = "openwrt";
                labels.type = "exporter";
                labels.role = "router";
              }
            ];
          }
          {
            job_name = "machines";
            static_configs = [
              {
                targets = [
                  "endeavour.local:9100"
                  "voyager.local:9100"
                ];
                labels.os = "linux";
                labels.type = "exporter";
                labels.role = "server";
              }
              {
                targets = [
                  "discovery.local:9100"
                  "enterprise.local:9100"
                ];
                labels.type = "node";
                labels.os = "darwin";
              }
            ];
          }
          {
            job_name = "apps";
            static_configs = [
              {
                targets = [
                  "endeavour:8081" # immich exporter
                  "endeavour:8096" # jellyfin
                  "endeavour:9187" # postgres exporter
                  "endeavour:9121" # redis exporter
                  "voyager:9187"   # postgres exporter
                  "voyager:9708"   # radarr exporter
                  "voyager:9709"   # sonarr exporter
                  "voyager:9710"   # prowlarr exporter
                ];
                labels.type = "exporter";
                labels.role = "server";
              }
              {
                targets = [ "endeavour:9199" ]; # nut exporter meta metrics
                labels.type = "exporter";
                labels.role = "ups";
              }
            ];
          }
          {
            job_name = "nut";
            metrics_path = "/ups_metrics";
            static_configs = [
              {
                targets = [ "endeavour:9199" ]; # nut exporter
                labels.type = "exporter";
                labels.role = "ups";
              }
            ];
          }
        ];
      };
    };

    prometheus.exporters = {
      postgres.enable = true;
      postgres.runAsLocalSuperUser = true;

      exportarr-radarr = {
        enable = true;
        url = "http://endeavour:7878";
        port = 9708;
        apiKeyFile = config.sops.secrets."keys/arr_apis/radarr".path;
      };

      exportarr-sonarr = {
        enable = true;
        url = "http://endeavour:8989";
        port = 9709;
        apiKeyFile = config.sops.secrets."keys/arr_apis/sonarr".path;
      };

      exportarr-prowlarr = {
        enable = true;
        url = "http://endeavour:9696";
        port = 9710;
        apiKeyFile = config.sops.secrets."keys/arr_apis/prowlarr".path;
      };

      blackbox = {
        enable = true;
        listenAddress = "[::1]";
        configFile = pkgs.writeText "blackbox_exporter.conf" ''
          modules:
            icmp:
              prober: icmp
            http_2xx:
              prober: http
              http:
                method: GET
                no_follow_redirects: true
                fail_if_ssl: true
            https_2xx:
              prober: http
              http:
                method: GET
                no_follow_redirects: true
                fail_if_not_ssl: true
        '';
      };

    };

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
          http_addr = "::1";
          domain = "$__file{${config.sops.templates."fqdns/grafana.txt".path}}";
        };

        smtp = {
          enabled = true;
          user = "$__file{${config.sops.secrets."email/smtp/username".path}}";
          password = "$__file{${config.sops.secrets."email/smtp/password".path}}";
          host = "$__file{${config.sops.secrets."email/smtp/host".path}}:587";
          from_address = "$__file{${config.sops.secrets."email/from/grafana".path}}";
          startTLS_policy = "MandatoryStartTLS";
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
      };
    };

    postgresql = {
      enable = true;
      ensureDatabases = [ "grafana" ];
      ensureUsers = [
        {
          name = "grafana";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    tsnsrv.services.mon = {
      urlParts.port = 3000;
    };
  };

  sops.secrets."keys/arr_apis/radarr".mode = "0444";
  sops.secrets."keys/arr_apis/sonarr".mode = "0444";
  sops.secrets."keys/arr_apis/prowlarr".mode = "0444";

  systemd.services.grafana.environment = {
    GF_AUTH_DISABLE_LOGIN_FORM = "true";
    GF_AUTH_BASIC_ENABLED = "false";
    GF_AUTH_PROXY_ENABLED = "true";
    GF_AUTH_PROXY_HEADER_NAME = "X-Tailscale-User-LoginName";
    GF_AUTH_PROXY_HEADER_PROPERTY = "username";
    GF_AUTH_PROXY_AUTO_SIGN_UP = "false";
    GF_AUTH_PROXY_SYNC_TTL = "60";
    GF_AUTH_PROXY_WHITELIST = "::1";
    GF_AUTH_PROXY_HEADERS = "Name:X-Tailscale-User-DisplayName";
    GF_AUTH_PROXY_ENABLE_LOGIN_TOKEN = "true";
  };

  sops.secrets = {
    "email/smtp/username".owner = config.users.users.grafana.name;
    "email/smtp/password".owner = config.users.users.grafana.name;
    "email/smtp/host".owner = config.users.users.grafana.name;
    "email/from/grafana".owner = config.users.users.grafana.name;
  };

  sops.templates."fqdns/grafana.txt" = {
    owner = config.users.users.grafana.name;
    content = "mon.${config.sops.placeholder."keys/tailscale_api/tailnet"}";
  };
  sops.templates."victoriametrics/file_sd_configs/blackbox_https_2xx.json" = {
    mode = "0444";
    content = ''
      [
          {
              "targets": [
                "https://6a.${config.sops.placeholder."keys/tailscale_api/tailnet"}",
                "https://ai.${config.sops.placeholder."keys/tailscale_api/tailnet"}",
                "https://imm.${config.sops.placeholder."keys/tailscale_api/tailnet"}",
                "https://mon.${config.sops.placeholder."keys/tailscale_api/tailnet"}",
                "https://sf.${config.sops.placeholder."keys/tailscale_api/tailnet"}",
                "https://tv.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
              ],
              "labels": {
                  "type": "app",
                  "role": "server"
              }
          }
      ]
    '';
  };
}
