{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  services.actual.enable = true;
  services.actual.package = pkgs-unstable.actual-server;
  services.actual.settings.port = 3100;
  services.tsnsrv.services.ab = {
    funnel = true;
    urlParts.host = "localhost";
    urlParts.port = 3100;
  };
  systemd.services.actual.serviceConfig.EnvironmentFile =
    config.sops.templates."actual/config.env".path;

  systemd.services.tsnsrv-ab = {
    wants = [ "actual.service" ];
    after = [ "actual.service" ];
  };

  sops.templates."actual/config.env" = {
    content = ''
      ACTUAL_OPENID_DISCOVERY_URL="https://accounts.google.com/.well-known/openid-configuration"
      ACTUAL_OPENID_SERVER_HOSTNAME="https://ab.${config.sops.placeholder."tailscale_api/tailnet"}"
      ACTUAL_OPENID_CLIENT_ID="${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}"
      ACTUAL_OPENID_CLIENT_SECRET="${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}"
    '';
  };
  systemd.timers."actual-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services."actual-backup" = {
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      #!/bin/bash

      set -euo pipefail

      backup_target="/var/lib/actual"
      systemctl stop actual.service
      snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

      cleanup() {
        rm -rf "$snapshot_target"
        systemctl start actual.service
      }
      trap cleanup EXIT

      ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target" 
      ${config.my-scripts.kopia-backup} "$snapshot_target"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

}
