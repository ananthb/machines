{
  config,
  ...
}:
let
  vs = config.vault-secrets.secrets;
in
{
  imports = [
    ./monitoring/postgres.nix
  ];

  services.immich = {
    enable = true;
    machine-learning.enable = false;
    host = "::";
    openFirewall = true;
    environment = {
      "IMMICH_CONFIG_FILE" = "${vs.immich}/config.json";
      "IMMICH_TRUSTED_PROXIES" = "::1,127.0.0.0/8";
      "IMMICH_TELEMETRY_INCLUDE" = "all";
    };
    accelerationDevices = [ "/dev/dri/renderD128" ];
  };

  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  systemd.services."immich-backup" = {
    # TODO: re-enable after we've trimmed down unnecessary files
    # startAt = "weekly";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${config.my-scripts.kopia-snapshot-backup} /srv/immich";
    };
  };

  vault-secrets.secrets.immich = {
    services = [
      "immich-server"
      "immich-microservices"
    ];
    environmentKey = null;
    user = "immich";
    group = "immich";
  };

}
