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

  systemd.timers."radicale-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services."radicale-backup" = {
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      backup_target="/var/lib/radicale"
      systemctl stop radicale.service
      snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"

      cleanup() {
        rm -rf "$snapshot_target"
        systemctl start radicale.service
      }
      trap cleanup EXIT

      ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target" 
      ${config.my-scripts.kopia-backup} "$snapshot_target" "$backup_target"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  sops.secrets."radicale/htpasswd".owner = "radicale";

}
