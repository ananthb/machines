{ config, pkgs, ... }:
let
  vs = config.vault-secrets.secrets;
in
{
  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "[::]:5232" ];
      auth = {
        type = "htpasswd";
        htpasswd_filename = "${vs.radicale}/htpasswd";
        htpasswd_encryption = "autodetect";
      };
    };
  };

  systemd.services."radicale-backup" = {
    startAt = "daily";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    preStart = "systemctl -q is-active radicale.service && systemctl stop radicale.service";
    script = ''
      backup_target="/var/lib/radicale"
      snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

      trap '{
        rm -rf "$snapshot_target"
      }' EXIT

      ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target" 
      ${config.my-scripts.kopia-backup} "$snapshot_target" "$backup_target"
    '';
    postStop = "systemctl start radicale.service";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  vault-secrets.secrets.radicale = {
    services = [ "radicale" ];
    user = "radicale";
    group = "radicale";
  };

}
