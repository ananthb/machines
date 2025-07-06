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

  prometheus.exporters.node = {
    enable = true;
    port = 9100;
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
    enabledCollectors = [ "systemd" ];
    extraFlags = [
      "--collector.ethtool"
      "--collector.softirqs"
      "--collector.tcpstat"
      "--collector.wifi"
    ];
  };

  # Enable tailscale
  tailscale.enable = true;

  cloudflare-warp.enable = true;
  cloudflare-warp.openFirewall = false;

  grafana = {
    enable = true;
  };

  victoriametrics = {
    enable = true;
  };

  home-assistant = {
    enable = true;
    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"

      # home stuff
      "esphome"
      "apple_tv"
      "cast"
      "androidtv_remote"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      smartir
      frigate
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

      name = "6A";
      unit_system = "metric";
      time_zone = "Asia/Kolkata";
      temperature_unit = "C";
      currency = "INR";
      country = "IN";
      external_url = "https://6a.tail42937.ts.net";
      internal_url = "http://endeavour.local:8123";
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
    downloadDirPermissions = "770";
    settings = {
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
      urlParts.host = "127.0.0.1";
      urlParts.port = 3000;
    };

    services.vm = {
      urlParts.port = 8428;
    };

    services."6a" = {
      funnel = true;
      urlParts.port = 8123;
    };

    services.tv = {
      funnel = true;
      urlParts.host = "127.0.0.1";
      urlParts.port = 8096;
    };

    services.see = {
      funnel = true;
      urlParts.port = 5055;
    };

    services.dl = {
      urlParts.port = 9091;
    };

    services.esp = {
      urlParts.port = 6053;
    };
  };
}
