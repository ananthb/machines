{
  config,
  pkgs,
  ...
}:
let
  vs = config.vault-secrets.secrets;
in
{
  imports = [
    ./monitoring/postgres.nix
  ];

  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      DATABASE_URL = "postgresql://vaultwarden@/vaultwarden?host=/run/postgresql";

      ROCKET_ADDRESS = "::";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";

      # sign ups
      INVITATIONS_ALLOWED = true;
      SIGNUPS_ALLOWED = false;
    };
    environmentFile = "${vs.vaultwarden}/environment";
  };

  systemd.services."vaultwarden-backup" = {
    startAt = "daily";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    preStart = "systemctl -q is-active vaultwarden.service && systemctl stop vaultwarden.service";
    script = ''
      backup_target="/var/lib/${config.systemd.services.vaultwarden.serviceConfig.StateDirectory}"
      snapshot_target="$(${pkgs.mktemp}/bin/mktemp -d)"
      dump_file="$snapshot_target/db.dump"
        
      trap '{
        rm -f "$dump_file"
        rm -rf "$snapshot_target"
      }' EXIT

      # Dump database
      ${pkgs.sudo-rs}/bin/sudo -u vaultwarden \
        ${pkgs.postgresql_16}/bin/pg_dump \
          -Fc -U vaultwarden vaultwarden > "$dump_file"
      printf 'Dumped database to %s' "$dump_file"

      ${pkgs.rsync}/bin/rsync -avz "$backup_target/" "$snapshot_target"

      ${config.my-scripts.kopia-backup} "$snapshot_target" "$backup_target"
    '';
    postStop = "systemctl start vaultwarden.service";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "vaultwarden"
    ];
    ensureUsers = [
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  vault-secrets.secrets.vaultwarden = {
    services = [ "vaultwarden" ];
  };
}
