{ config, pkgs, ... }:

{
  # Enable the OpenSSH daemon.
  openssh.enable = true;
  openssh.settings.PermitRootLogin = "no";
  openssh.settings.PasswordAuthentication = false;

  # Yubikey stuff
  udev.packages = with pkgs; [ yubikey-personalization ];
  pcscd.enable = true;

  # Enable resolved and avahi
  resolved.enable = true;
  avahi.enable = true;
  # Enable tailscale
  tailscale.enable = true;

  cloudflare-warp.enable = true;
  cloudflare-warp.openFirewall = false;

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
              labels.type = "internet";
              labels.location = "penthouse";
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
                "https://tv.tail42937.ts.net"
                "https://see.tail42937.ts.net"
                "https://6a.tail42937.ts.net"
                "https://t1.tail42937.ts.net"
              ];
              labels.type = "app";
              labels.role = "server";
              labels.location = "cloud";
            }
            {
              targets = [
                "https://www.google.com"
                "https://www.cloudflare.com"
              ];
              labels.role = "canary";
              labels.type = "internet";
              labels.location = "penthouse";
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
              labels.type = "website";
            }
            {
              targets = [
                "https://www.google.com"
                "https://www.cloudflare.com"
              ];
              labels.type = "internet";
              labels.role = "canary";
              labels.location = "penthouse";
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
        https_2ss:
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
        domain = "mon.tail42937.ts.net";
      };

      smtp = {
        enabled = true;
        user = "$__file{${config.sops.secrets."smtp/username".path}}";
        password = "$__file{${config.sops.secrets."smtp/password".path}}";
        host = "$__file{${config.sops.secrets."smtp/host".path}}:587";
        from_address = "mon@kedi.dev";
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

  home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      "default_config"
      "dhcp"

      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "mobile_app"
      # "radio_browser"
      # "shopping_list"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"

      # home stuff
      "androidtv"
      "androidtv_remote"
      "apple_tv"
      "bluetooth"
      "bluetooth_le_tracker"
      "bluetooth_tracker"
      "broadlink"
      "camera"
      "cast"
      "ecovacs"
      "esphome"
      "luci"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      smartir
      frigate
      prometheus_sensor
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };

      http = {
        trusted_proxies = [
          "::1"
          "127.0.0.1"
        ];
        use_x_forwarded_for = true;
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
      };

      homeassistant = {
        name = "6A";
        unit_system = "metric";
        time_zone = "Asia/Kolkata";
        latitude = "!include ${config.sops.secrets."home/6a/latitude".path}";
        longitude = "!include ${config.sops.secrets."home/6a/longitude".path}";
        elevation = "!include ${config.sops.secrets."home/6a/elevation".path}";
        temperature_unit = "C";
        currency = "INR";
        country = "IN";
        external_url = "https://6a.tail42937.ts.net";
        internal_url = "http://endeavour.local:8123";
      };
    };
  };

  esphome = {
    enable = true;
  };

  jellyfin.enable = true;
  jellyfin.group = "media";
  jellyfin.openFirewall = true;

  meilisearch.enable = true;
  meilisearch.package = pkgs.meilisearch;

  transmission = {
    enable = true;
    package = pkgs.transmission_4;
    group = "media";
    downloadDirPermissions = "775";
    settings = {
      rpc-bind-address = "[::]";
      rpc-whitelist = "*";
      rpc-host-whitelist = "*";

      umask = "002";
      proxy_url = "socks5://localhost:8080";

      watch-dir-enabled = true;

      alt-speed-up = 1000; # 1000KB/s
      alt-speed-down = 1000; # 1000KB/s

      # Scheduling option docs:
      # https://github.com/transmission/transmission/blob/main/docs/Editing-Configuration-Files.md#scheduling
      alt-speed-time-enabled = true;
      alt-speed-time-begin = 540; # 9am
      alt-speed-time-end = 1020; # 5pm
      alt-speed-time-day = 127; # all days of the week
    };
  };

  radarr = {
    enable = true;
    group = "media";
  };

  sonarr = {
    enable = true;
    group = "media";
  };

  prowlarr = {
    enable = true;
  };

  jellyseerr = {
    enable = true;
  };

  tsnsrv = {
    enable = true;
    defaults.authKeyPath = config.sops.secrets."tsnsrv/auth_key".path;
    defaults.urlParts.host = "localhost";

    services.mon = {
      funnel = true;
      urlParts.port = 3000;
      extraArgs = [
        "-prometheusAddr=[::1]:9099"
      ];
    };

    services."6a" = {
      funnel = true;
      urlParts.port = 8123;
      extraArgs = [
        "-prometheusAddr=[::1]:9098"
      ];
    };

    services.tv = {
      funnel = true;
      urlParts.port = 8096;
      extraArgs = [
        "-prometheusAddr=[::1]:9097"
      ];
    };

    services.see = {
      funnel = true;
      urlParts.port = 5055;
      extraArgs = [
        "-prometheusAddr=[::1]:9096"
      ];
    };

    services.esp = {
      urlParts.port = 6053;
      extraArgs = [
        "-prometheusAddr=[::1]:9095"
      ];
    };
  };
}
