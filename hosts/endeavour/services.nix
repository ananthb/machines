{ pkgs, ...}:

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
  jellyfin.openFirewall = true;

  transmission.enable = true;
  transmission.package = pkgs.transmission_4;
  transmission.settings.umask = "002";

  radarr = {
    enable = true;
  };

  sonarr = {
    enable = true;
  };

  prowlarr = {
    enable = true;
  };

  jellyseerr = {
    enable = true;
    openFirewall = true;
  };
}
