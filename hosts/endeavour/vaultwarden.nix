{ config, pkgs, ... }:

{
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      DATABASE_URL = "postgresql://vaultwarden@/vaultwarden?host=/run/postgresql";

      ROCKET_ADDRESS = "::1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";

      # sign ups
      INVITATIONS_ALLOWED = true;
      SIGNUPS_ALLOWED = false;
    };
    environmentFile = config.sops.templates."vaultwarden/secrets.env".path;
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "vaultwarden" ];
    ensureUsers = [
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  services.tsnsrv.services."vault" = {
    funnel = true;
    urlParts.port = 8222;
  };

  systemd.timers."vaultwarden-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.services."vaultwarden-backup" = {
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      #!/bin/bash

      set -euo pipefail

      db_backup_dir="/var/lib/bitwarden_rs/backups"
      mkdir -p "$db_backup_dir"

      # Prune old backups from the backup directory
      deleted_files=$(find "$db_backup_dir" -type f -name "*.dump" -mtime +3 -print -delete)
      if [[ -n "$deleted_files" ]]; then
        printf 'deleted old volume backups %s\n' "$deleted_files"
      fi

      # Dump database
      dump_file="$db_backup_dir/vaultwarden_db-$(date --utc --iso-8601=second).dump"
      ${pkgs.sudo-rs}/bin/sudo -u vaultwarden \
        ${pkgs.postgresql_15}/bin/pg_dump \
          -Fc -U vaultwarden vaultwarden > "$dump_file"

      printf 'Dumped vaultwarden database to %s' "$dump_file"

      ${config.my-scripts.snapshot-backup} /var/lib/bitwarden_rs
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  sops.templates."vaultwarden/secrets.env" = {
    content = ''
      DOMAIN=https://vault.${config.sops.placeholder."tailscale_api/tailnet"}
      ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin_token"}

      # smtp
      SMTP_HOST=${config.sops.placeholder."email/smtp/host"}
      SMTP_PORT=587
      SMTP_SECURITY=starttls
      SMTP_USERNAME=${config.sops.placeholder."email/smtp/username"}
      SMTP_PASSWORD=${config.sops.placeholder."email/smtp/password"}
      SMTP_FROM=${config.sops.placeholder."email/from/vaultwarden"}
      SMTP_FROM_NAME=Ananth's Secret Vault

      # push notifications
      PUSH_ENABLED=true
      PUSH_RELAY_URI=https://api.bitwarden.eu
      PUSH_IDENTITY_URI=https://identity.bitwarden.eu
      PUSH_INSTALLATION_ID=${config.sops.placeholder."vaultwarden/installation_id"}
      PUSH_INSTALLATION_KEY=${config.sops.placeholder."vaultwarden/installation_key"}
    '';
  };

  sops.secrets = {
    "email/from/vaultwarden" = { };
    "vaultwarden/admin_token" = { };
    "vaultwarden/installation_id" = { };
    "vaultwarden/installation_key" = { };
  };
}
