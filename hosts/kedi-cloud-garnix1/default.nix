# kedi-cloud-garnix1: Garnix-hosted NixOS server running cloud-friendly services.
{
  config,
  lib,
  pkgs,
  ...
}: let
  mkCaddyReverseProxies = import ../../lib/caddy-helpers.nix {inherit lib;};
in {
  imports = [
    ../shared/garnix.nix
    ./homepage.nix
    ../../services/actual.nix
    ../../services/mealie.nix
    ../../services/media/news.nix
    ../../services/vaultwarden.nix
    ../../services/monitoring/blackbox.nix
    ../../services/monitoring/grafana.nix
    ../../services/monitoring/probes.nix
    ../../services/monitoring/victoriametrics.nix
    ../../services/monitoring/victorialogs.nix
  ];

  networking = {
    hostName = "kedi-cloud-garnix1";
    interfaces.eth0.ipv6.addresses = [
      {
        address = "2a01:4f9:c014:4cf0::1";
        prefixLength = 64;
      }
    ];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    firewall.allowedTCPPorts = [80];
  };

  garnix.server.persistence = {
    enable = true;
    name = "kedi-cloud-garnix1";
  };

  environment.systemPackages = [pkgs.ghostty.terminfo];

  sops.defaultSopsFile = ../../secrets/kedi-cloud.yaml;

  # --- Service overrides for garnix ---

  services = {
    actual.settings.port = lib.mkForce 3002;

    mealie = {
      listenAddress = lib.mkForce "127.0.0.1";
      database.createLocally = true;
    };

    caddy = {
      enable = true;
      virtualHosts = mkCaddyReverseProxies {
        "actual.kedi.dev" = 3002;
        "miniflux.kedi.dev" = 8088;
        "wallabag.kedi.dev" = 8085;
        "mealie.kedi.dev" = 9000;
        "kedi.dev" = 8802;
        "metrics.kedi.dev" = 3000;
        "vaultwarden.kedi.dev" = 8222;
      };
    };

    prometheus.exporters.node = {
      enable = true;
      openFirewall = true;
    };
  };

  # --- Backup services not covered by service modules ---

  systemd.services = {
    "miniflux-backup" = config.my-services.mkBackupService {
      script = ''
        snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"
        trap '{ rm -rf "$snapshot_target"; }' EXIT
        ${pkgs.sudo}/bin/sudo -u postgres \
          ${config.services.postgresql.package}/bin/pg_dump \
            -Fc miniflux > "$snapshot_target/miniflux.dump"
        ${config.my-scripts.kopia-backup} "$snapshot_target" "/var/lib/miniflux"
      '';
    };

    "wallabag-backup" = config.my-services.mkBackupService {
      script = ''
        snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"
        trap '{ rm -rf "$snapshot_target"; }' EXIT
        ${pkgs.sudo}/bin/sudo -u postgres \
          ${config.services.postgresql.package}/bin/pg_dump \
            -Fc wallabag > "$snapshot_target/wallabag.dump"
        ${pkgs.podman}/bin/podman volume export wallabag-data \
          > "$snapshot_target/wallabag-data.tar"
        ${pkgs.podman}/bin/podman volume export wallabag-images \
          > "$snapshot_target/wallabag-images.tar"
        ${config.my-scripts.kopia-backup} "$snapshot_target" "/var/lib/wallabag"
      '';
    };

    "postgresql-backup" = config.my-services.mkBackupService {
      script = ''
        snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"
        trap '{ rm -rf "$snapshot_target"; }' EXIT
        ${pkgs.sudo}/bin/sudo -u postgres \
          ${config.services.postgresql.package}/bin/pg_dumpall \
            > "$snapshot_target/all-databases.sql"
        ${config.my-scripts.kopia-backup} "$snapshot_target" "/var/lib/postgresql"
      '';
    };
  };

  system.stateVersion = "25.05";
}
