{ config, pkgs, ... }:
let
  vs = config.vault-secrets.secrets;
in
{
  services.actual.enable = true;
  services.actual.settings.port = 3001;

  systemd.services = {
    actual = {
      serviceConfig.EnvironmentFile = "${vs.actual}/environment";
      environment = {
        ACTUAL_OPENID_DISCOVERY_URL = "https://accounts.google.com/.well-known/openid-configuration";
        ACTUAL_OPENID_SERVER_HOSTNAME = "https://actual.kedi.dev";
      };
    };

    "actual-backup" = {
      startAt = "daily";
      environment.KOPIA_CHECK_FOR_UPDATES = "false";
      preStart = "systemctl -q is-active actual.service && systemctl stop actual.service";
      script = ''
        backup_target="/var/lib/actual"
        snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

        trap '{
          rm -rf "$snapshot_target"
        }' EXIT

        ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target" 
        ${config.my-scripts.kopia-backup} "$snapshot_target" "$backup_target"
      '';
      postStop = "systemctl start actual.service";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };

  vault-secrets.secrets.actual = {
    services = [ "actual" ];
  };

}
