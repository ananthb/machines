{ config, pkgs, ... }:
{

  services = {
    victoriametrics = {
      enable = true;
      listenAddress = "[::1]:8428";
      retentionPeriod = "1y";
      extraOptions = [
        "-enableTCP6"
      ];
      prometheusConfig = {
        global.scrape_interval = "15s";
        scrape_configs = [
          {
            job_name = "blackbox_exporter";
            static_configs = [
              {
                targets = [ "localhost:9115" ];
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
                  "phoenix.local"
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
          # Query these addresses via the warp proxy.
          # This checks if the proxy is working and if
          # these sites are accessible from the internet.
          {
            job_name = "blackbox_https_2xx_warp_proxy";
            metrics_path = "/probe";
            params.module = [ "https_2xx_warp_proxy" ];
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
                  "https://www.google.com"
                  "https://www.cloudflare.com"
                ];
                labels.role = "canary";
                labels.type = "internet-site";
              }
            ];
            file_sd_configs = [
              {
                files = [
                  config.sops.templates."victoriametrics/file_sd_configs/blackbox_https_2xx_warp_proxy.json".path
                ];
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
                  "http://localhost:7878"
                  "http://localhost:8989"
                  "http://localhost:9696"
                ];
                labels.type = "app";
                labels.role = "server";
              }
              {
                targets = [
                  "http://atlantis.local"
                  "http://intrepid.local"
                  "http://phoenix.local"
                ];
                labels.type = "node";
                labels.os = "openwrt";
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
                  "https://devhuman.net"
                  "https://bhaskararaman.com"
                  "https://futuraphysio.com"
                  "https://drvibhu.com"
                  "https://lilaartscentre.com"
                ];
                labels.type = "hosted-site";
                labels.location = "cloud";
              }
              {
                targets = [
                  "https://www.google.com"
                  "https://www.cloudflare.com"
                ];
                labels.type = "internet-site";
                labels.role = "canary";
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
                  "phoenix.local:9100"
                ];
                labels.type = "node";
                labels.os = "openwrt";
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
                ];
                labels.type = "node";
                labels.os = "linux";
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
          /*
            {
              job_name = "tsnsrvs";
              static_configs = [
                {
                  targets = [
                    "localhost:9099"
                    "localhost:9098"
                    "localhost:9097"
                    "localhost:9096"
                    "localhost:9095"
                    "localhost:9094"
                  ];
                  labels.type = "reverse_proxy";
                }
              ];
            }
          */
        ];
      };
    };

    prometheus.exporters.node = {
      enable = true;
      openFirewall = true;
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
      enabledCollectors = [
        "ethtool"
        "perf"
        "systemd"
        "tcpstat"
        "wifi"
      ];
      disabledCollectors = [ "textfile" ];
    };

    prometheus.exporters.blackbox = {
      enable = true;
      listenAddress = "[::1]";
      configFile = pkgs.writeText "blackbox_exporter.conf" ''
        modules:
          icmp:
            prober: icmp
          https_2xx_warp_proxy:
            prober: http
            http:
              proxy_url: "socks5://localhost:8080"
              method: GET
              valid_status_codes: [200]
              no_follow_redirects: true
              fail_if_not_ssl: true
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

    grafana = {
      enable = true;
      settings = {
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

    tsnsrv.services.mon = {
      funnel = true;
      urlParts.port = 3000;
      extraArgs = [
        "-prometheusAddr=[::1]:9099"
      ];
    };
  };

  sops.secrets."tsnsrv/nodes/grafana" = { };
  sops.secrets."email/from/grafana".owner = config.users.users.grafana.name;
  sops.templates."fqdns/grafana.txt" = {
    owner = config.users.users.grafana.name;
    content = "${config.sops.placeholder."tsnsrv/nodes/grafana"}.${
      config.sops.placeholder."tsnsrv/tailnet"
    }";
  };
  sops.templates."victoriametrics/file_sd_configs/blackbox_https_2xx_warp_proxy.json" = {
    mode = "0444";
    content = ''
      [
          {
              "targets" = [
                "https://${config.sops.placeholder."tsnsrv/nodes/jellyfin"}.${
                  config.sops.placeholder."tsnsrv/tailnet"
                }",
                "https://${config.sops.placeholder."tsnsrv/nodes/jellyseerr"}.${
                  config.sops.placeholder."tsnsrv/tailnet"
                }",
                "https://${config.sops.placeholder."tsnsrv/nodes/ha-6a"}.${
                  config.sops.placeholder."tsnsrv/tailnet"
                }",
                "https://${config.sops.placeholder."tsnsrv/nodes/ha-t1"}.${
                  config.sops.placeholder."tsnsrv/tailnet"
                }",
                "https://${config.sops.placeholder."tsnsrv/nodes/immich"}.${
                  config.sops.placeholder."tsnsrv/tailnet"
                }",
              ],
              "labels" = {
                  "type" = "app",
                  "role" = "server"
              }
          }
      ]
    '';
  };
}
