{ config, pkgs, ... }:
{
  services = {
    radicale = {
      enable = true;
      settings = {
        server.hosts = [ "[::]:5232" ];
        auth = {
          type = "htpasswd";
          htpasswd_filename = "${config.sops.secrets."radicale/htpasswd".path}";
          htpasswd_encryption = "autodetect";
        };
      };
    };

    tsnsrv.services.cal = {
      funnel = true;
      urlParts.port = 5232;
    };
  };

  systemd.services.tsnsrv-cal = {
    wants = [ "radicale.service" ];
    after = [ "radicale.service" ];
  };

  systemd.services."radicale-backup" = {
    startAt = "daily";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    preStart = "systemctl stop radicale.service";
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
    serviceConfig.Type = "oneshot";
  };

  sops.secrets."radicale/htpasswd".owner = "radicale";

}
