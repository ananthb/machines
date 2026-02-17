{ config, pkgs, ... }:
let
  vs = config.vault-secrets.secrets;
in
{

  services.mealie = {
    enable = true;
    listenAddress = "[::1]";
    credentialsFile = "${vs.mealie}/environment";
  };

  systemd.services."mealie-backup" = {
    startAt = "weekly";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      set -uo pipefail

      backup_api_url="http://localhost:9000/api/admin/backups"

      http() {
        ${pkgs.httpie}/bin/http -A bearer -a "$MEALIE_BACKUP_API_KEY" \
          --check-status \
          --ignore-stdin \
          --timeout=10 \
          "$@"
      }

      # Delete all backups
       http GET "$backup_api_url" \
        | ${pkgs.jq}/bin/jq -r '.imports[].name' \
        | ${pkgs.findutils}/bin/xargs -I{} \
          ${pkgs.httpie}/bin/http -A bearer -a "$MEALIE_BACKUP_API_KEY" \
            --check-status \
            --ignore-stdin \
            --timeout=10 \
            DELETE "$backup_api_url/"{}

      # Create new backup
      http POST "$backup_api_url"

      # Upload new backup
      ${config.my-scripts.kopia-backup} /var/lib/mealie/backups
    '';
    serviceConfig = {
      User = "root";
      Type = "oneshot";
      EnvironmentFile = "${vs.mealie}/environment";
    };
  };

  vault-secrets.secrets.mealie = {
    services = [
      "mealie"
      "mealie-backup"
    ];
  };
}
