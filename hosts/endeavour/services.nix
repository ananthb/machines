{ pkgs, ... }:

{
  # Enable the OpenSSH daemon.
  openssh.enable = true;
  openssh.settings.PermitRootLogin = "no";
  openssh.settings.PasswordAuthentication = false;

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
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
    };
  };

  esphome = {
    enable = true;
  };

  jellyfin.enable = true;
  jellyfin.group = "media";
  jellyfin.openFirewall = true;

  transmission = {
    enable = true;
    package = pkgs.transmission_4;
    group = "media";
    downloadDirPermissions = "770";
    settings = {
      umask = "002";
      proxy_url = "socks5://localhost:8080";
      
      alt-speed-up = 1000;    # 1000KB/s
      alt-speed-down = 1000;  # 1000KB/s

      # Scheduling option docs:
      # https://github.com/transmission/transmission/blob/main/docs/Editing-Configuration-Files.md#scheduling
      alt-speed-time-enabled = true;
      alt-speed-time-begin = 540;     # 9am
      alt-speed-time-end = 1020;      # 5pm
      alt-speed-time-day = 127;       # all days of the week
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
    openFirewall = true;
  };
}
