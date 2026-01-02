{ config, lib, ... }:
{

  services.victoriametrics = {
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
              targets = [
                "endeavour.local:9115"
                "stargazer:9115"
                "voyager:9115"
              ];
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
              replacement = "endeavour.local:9115";
            }
          ];
          params.module = [ "icmp" ];
          static_configs = [
            {
              targets = [
                "endeavour.local"
                "enterprise.local"
                "stargazer"
                "voyager"
                "pikvm"
              ];
              labels.type = "node";
              labels.os = "linux";
              labels.role = "server";
            }
            {
              targets = [
                "discovery.local"
              ];
              labels.type = "node";
              labels.os = "darwin";
            }
            {
              targets = [
                "atlantis.local"
                "ds9"
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
              replacement = "endeavour.local:9115";
            }
          ];
          static_configs = [
            {
              targets = [
                "http://endeavour.local:7878" # radarr
                "http://endeavour.local:8989" # sonarr
                "http://endeavour.local:9696" # prowlarr
              ];
              labels.type = "app";
              labels.role = "server";
            }
            {
              targets = [
                "http://enterprise.local:2283/auth/login" # immich-server
              ];
              labels.type = "app";
              labels.role = "server";
              labels.app = "immich";
            }
            {
              targets = [
                "http://enterprise.local:8096/web/" # jellyfin
              ];
              labels.app = "jellyfin";
              labels.type = "app";
              labels.role = "server";
            }
            {
              targets = [
                "http://atlantis.local"
                "http://ds9"
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
              replacement = "endeavour.local:9115";
            }
          ];
          static_configs = [
            {
              targets = [
                "https://bhaskararaman.com"
                "https://calculon.tech"
                "https://coredump.blog"
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
        }
        {
          job_name = "blackbox_https_2xx_private";
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
              replacement = "endeavour.local:9115";
            }
          ];
          file_sd_configs = [
            {
              files = [
                config.sops.templates."victoriametrics/file_sd_configs/blackbox_https_2xx_private.json".path
              ];
            }
          ];
        }
        {
          job_name = "blackbox_https_2xx_via_warp";
          metrics_path = "/probe";
          params.module = [ "https_2xx_via_warp" ];
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
              replacement = "endeavour.local:9115";
            }
            {
              source_labels = [ "__address__" ];
              regex = ".*";
              replacement = "warp";
              target_label = "via";
              action = "replace";
            }
          ];
          static_configs = [
            {
              targets = [
                "https://bhaskararaman.com"
                "https://calculon.tech"
                "https://coredump.blog"
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
        }
        {
          job_name = "blackbox_https_2xx_via_warp_private";
          metrics_path = "/probe";
          params.module = [ "https_2xx_via_warp" ];
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
              replacement = "endeavour.local:9115";
            }
            {
              source_labels = [ "__address__" ];
              regex = ".*";
              replacement = "warp";
              target_label = "via";
              action = "replace";
            }
          ];
          file_sd_configs = [
            {
              files = [
                config.sops.templates."victoriametrics/file_sd_configs/blackbox_https_2xx_private.json".path
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
                "ds9:9100"
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
                "enterprise.local:9100"
                "stargazer:9100"
                "voyager:9100"
              ];
              labels.os = "linux";
              labels.type = "exporter";
              labels.role = "server";
            }
            {
              targets = [
                "discovery.local:9100"
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
                "endeavour.local:9708" # radarr exporter
                "endeavour.local:9709" # sonarr exporter
                "endeavour.local:9710" # prowlarr exporter
                "endeavour.local:9187" # postgres exporter
                "enterprise.local:9187" # postgres exporter
                "voyager.local:9187" # postgres exporter
              ];
              labels.type = "exporter";
              labels.role = "server";
            }
            {
              targets = [
                "enterprise.local:8081" # immich-server api metrics
                "enterprise.local:8081" # immich-server microservices metrics
              ];
              labels.type = "exporter";
              labels.role = "server";
              labels.app = "immich";
            }
            {
              targets = [
                "enterprise.local:8096" # jellyfin
              ];
              labels.type = "exporter";
              labels.role = "server";
              labels.app = "jellyfin";
            }
            {
              targets = [ "endeavour.local:9199" ]; # nut exporter meta metrics
              labels.type = "exporter";
              labels.role = "ups";
            }
            {
              # smartctl exporters
              targets = [
                "endeavour.local:9633"
                "enterprise.local:9633"
                "stargazer:9633"
                "voyager:9633"
              ];
              labels.type = "exporter";
              labels.role = "disks";
            }
          ];
        }
        {
          job_name = "nut";
          metrics_path = "/ups_metrics";
          static_configs = [
            {
              targets = [ "endeavour.local:9199" ]; # nut exporter
              labels.type = "exporter";
              labels.role = "ups";
            }
          ];
        }
        {
          job_name = "home_assistant_6a";
          metrics_path = "/api/prometheus";
          scheme = "https";
          authorization = {
            type = "Bearer";
            credentials_file = config.sops.secrets."homes/6a/hass/prometheus_token".path;
          };
          static_configs = [
            {
              targets = [ "6a.kedi.dev" ];
              labels.type = "app";
              labels.app = "home-assistant";
            }
          ];
        }
        {
          job_name = "home_assistant_t1";
          metrics_path = "/api/prometheus";
          scheme = "https";
          authorization = {
            type = "Bearer";
            credentials_file = config.sops.secrets."homes/t1/hass/prometheus_token".path;
          };
          static_configs = [
            {
              targets = [ "t1.kedi.dev" ];
              labels.type = "app";
              labels.app = "home-assistant";
            }
          ];
        }
      ];
    };
  };

  systemd.services.victoriametrics.serviceConfig.ReadOnlyPaths = lib.concatStringsSep " " [
    config.sops.templates."victoriametrics/file_sd_configs/blackbox_https_2xx_private.json".path
    config.sops.secrets."homes/6a/hass/prometheus_token".path
    config.sops.secrets."homes/t1/hass/prometheus_token".path
  ];

  sops.secrets = {
    "homes/6a/hass/prometheus_token" = { };
    "homes/t1/hass/prometheus_token" = { };
  };

  sops.templates."victoriametrics/file_sd_configs/blackbox_https_2xx_private.json" = {
    owner = config.users.users.grafana.name;
    content = ''
      [
          {
              "targets": [
                "https://6a.kedi.dev",
                "https://actual.kedi.dev",
                "https://mealie.kedi.dev",
                "https://mon.${config.sops.placeholder."tailscale_api/tailnet"}",
                "https://open-webui.kedi.dev.",
                "https://radicale.kedi.dev",
                "https://vault.kedi.dev"
              ],
              "labels": {
                  "type": "app",
                  "role": "server"
              }
          },
          {
              "targets": [
                "https://wallabag.kedi.dev",
                "https://miniflux.kedi.dev"
              ],
              "labels": {
                  "type": "app",
                  "role": "server",
                  "app": "news"
              }
          },
          {
              "targets": [
                "https://immich.kedi.dev/auth/login"
              ],
              "labels": {
                  "type": "app",
                  "role": "server",
                  "app": "immich"
              }
          },
          {
              "targets": [
                "https://seafile.kedi.dev/accounts/login/"
              ],
              "labels": {
                  "type": "app",
                  "role": "server",
                  "app": "seafile"
              }
          },
          {
              "targets": [
                "https://tv.${config.sops.placeholder."tailscale_api/tailnet"}/web/",
                "https://tv.kedi.dev/web/"
              ],
              "labels": {
                  "type": "app",
                  "role": "server",
                  "app": "jellyfin"
              }
          }
      ]
    '';
  };

}
