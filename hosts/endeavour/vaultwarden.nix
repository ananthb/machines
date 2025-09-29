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

      backup_target="/var/lib/bitwarden_rs"
      dump_file="$backup_target/vaultwarden_db.dump"

      # Dump database
      ${pkgs.sudo-rs}/bin/sudo -u vaultwarden \
        ${pkgs.postgresql_15}/bin/pg_dump \
          -Fc -U vaultwarden vaultwarden > "$dump_file"
      printf 'Dumped vaultwarden database to %s' "$dump_file"

      cleanup() {
        rm "$dump_file"
      }
      trap cleanup EXIT

      ${config.my-scripts.snapshot-backup} "$backup_target"
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
