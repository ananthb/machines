{ config, pkgs, ... }:
{

  services.mealie = {
    enable = true;
    listenAddress = "[::]";
    database.createLocally = true;
    credentialsFile = config.sops.templates."mealie/env".path;
  };

  systemd.services."mealie-backup" = {
    startAt = "weekly";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      set -uo pipefail

      backup_api_url="http://localhost:9000/api/admin/backups"

      http() {
        ${pkgs.httpie}/bin/http -A bearer -a "$backup_api_key" \
          --check-status \
          --ignore-stdin \
          --timeout=10 \
          "$@"
      }

      # Delete all backups
       http GET "$backup_api_url" \
        | ${pkgs.jq}/bin/jq -r '.imports[].name' \
        | ${pkgs.findutils}/bin/xargs -I{} \
          ${pkgs.httpie}/bin/http -A bearer -a "$backup_api_key" \
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
      EnvironmentFile = "${config.sops.secrets."mealie/api_keys".path}";
    };
  };

  networking.firewall.allowedTCPPorts = [ 9000 ];

  sops.secrets = {
    "email/from/mealie" = { };
    "open-webui/api_key" = { };
    "mealie/api_keys" = { };
  };

  sops.templates."mealie/env" = {
    content = ''
      # general
      BASE_URL=https://mealie.kedi.dev

      # TODO: this blasted setting doesn't work
      #FORWARDED_ALLOW_IPS=[::1],127.0.0.1
      FORWARDED_ALLOW_IPS=*

      # auth
      ALLOW_PASSWORD_LOGIN=False
      OIDC_AUTH_ENABLED=True
      OIDC_SIGNUP_ENABLED=False
      OIDC_CLIENT_ID=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}
      OIDC_CLIENT_SECRET=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}
      OIDC_PROVIDER_NAME=Google
      OIDC_CONFIGURATION_URL=https://accounts.google.com/.well-known/openid-configuration

      # smtp
      SMTP_HOST=${config.sops.placeholder."email/smtp/host"}
      SMTP_FROM_EMAIL=${config.sops.placeholder."email/from/mealie"}
      SMTP_USER=${config.sops.placeholder."email/smtp/username"}
      SMTP_PASSWORD=${config.sops.placeholder."email/smtp/password"}

      # open-webui
      OPENAI_BASE_URL=http://endeavour:8090/ollama/v1
      OPENAI_MODEL=gemma3:12b
      OPENAI_API_KEY=${config.sops.placeholder."open-webui/api_key"}
    '';
  };
}
