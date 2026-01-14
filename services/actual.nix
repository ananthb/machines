{ config, pkgs, ... }:
{
  services.actual.enable = true;
  services.actual.settings.port = 3001;

  systemd.services.actual.serviceConfig.EnvironmentFile =
    config.sops.templates."actual/config.env".path;

  systemd.services = {
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

  sops.templates."actual/config.env".content = ''
    ACTUAL_OPENID_DISCOVERY_URL=https://accounts.google.com/.well-known/openid-configuration
    ACTUAL_OPENID_SERVER_HOSTNAME=https://actual.kedi.dev
    ACTUAL_OPENID_CLIENT_ID=${config.sops.placeholder."gcloud/oauth/self-hosted_clients/id"}
    ACTUAL_OPENID_CLIENT_SECRET=${config.sops.placeholder."gcloud/oauth/self-hosted_clients/secret"}
  '';

  sops.secrets = {
    "gcloud/oauth/self-hosted_clients/id" = { };
    "gcloud/oauth/self-hosted_clients/secret" = { };
  };

}
