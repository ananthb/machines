{
  config,
  pkgs,
  ...
}:
{

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
    environmentFile = config.sops.templates."vaultwarden/secrets.env".path;
  };

  networking.firewall.allowedTCPPorts = [ 8222 ];

  systemd.services."vaultwarden-backup" = {
    startAt = "daily";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    preStart = "systemctl is-active vaultwarden.service && systemctl stop vaultwarden.service";
    script = ''
      backup_target="/var/lib/vaultwarden"
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

  sops.secrets = {
    "email/from/vaultwarden" = { };
    "vaultwarden/admin_token" = { };
    "vaultwarden/installation_id" = { };
    "vaultwarden/installation_key" = { };
  };

  sops.templates."vaultwarden/secrets.env".content = ''
    DOMAIN=https://vault.kedi.dev
    ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin_token"}

    # smtp
    SMTP_HOST=${config.sops.placeholder."email/smtp/host"}
    SMTP_PORT=587
    SMTP_SECURITY=starttls
    SMTP_USERNAME=${config.sops.placeholder."email/smtp/username"}
    SMTP_PASSWORD=${config.sops.placeholder."email/smtp/password"}
    SMTP_FROM=${config.sops.placeholder."email/from/vaultwarden"}
    SMTP_FROM_NAME=KEDI Vaultwarden

    # push notifications
    PUSH_ENABLED=true
    PUSH_RELAY_URI=https://api.bitwarden.eu
    PUSH_IDENTITY_URI=https://identity.bitwarden.eu
    PUSH_INSTALLATION_ID=${config.sops.placeholder."vaultwarden/installation_id"}
    PUSH_INSTALLATION_KEY=${config.sops.placeholder."vaultwarden/installation_key"}
  '';
}
