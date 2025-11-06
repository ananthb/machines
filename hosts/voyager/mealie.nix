{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  services.mealie = {
    enable = true;
    package = pkgs-unstable.mealie;
    listenAddress = "[::1]";
    database.createLocally = true;
    settings = {
      ALLOW_PASSWORD_LOGIN = "False";
      OIDC_AUTH_ENABLED = "True";
      OIDC_SIGNUP_ENABLED = "False";
      OIDC_PROVIDER_NAME = "Google";
      OIDC_CONFIGURATION_URL = "https://accounts.google.com/.well-known/openid-configuration";
      OPENAI_BASE_URL = "http://enterprise:11434/v1";
      OPENAI_MODEL = "gemma3:12b";
    };
    credentialsFile = config.sops.templates."mealie/env".path;
  };

  services.tsnsrv.services.mle = {
    funnel = true;
    urlParts.port = 9000;
  };

  systemd.services = {
    tsnsrv-mle.wants = [ "mealie.service" ];
    tsnsrv-mle.after = [ "mealie.service" ];
  };

  systemd.services."mealie-backup" = {
    startAt = "weekly";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    script = ''
      backup_api_url="http://localhost:9000/api/admin/backups"

      http() {
        ${pkgs.httpie}/bin/http -A bearer -a "$backups_key" \
          --check-status \
          --ignore-stdin \
          --timeout=2.5 \
          "$@"
      }

      # Delete all backups
       http GET "$backup_api_url" \
        | ${pkgs.jq}/bin/jq -r '.imports[].name' \
        | ${pkgs.findutils}/bin/xargs -I{} \
          ${pkgs.httpie}/bin/http -A bearer -a "$backups_key" \
            --check-status \
            --ignore-stdin \
            --timeout=2.5 \
            DELETE "$backup_api_url/"{}

      # Create new backup
      http POST "$backup_api_url"

      # Upload new backup
      ${config.my-scripts.kopia-backup} /var/lib/mealie/backups
    '';
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "${config.sops.secrets."mealie/api_keys".path}";
    };
  };

  sops.secrets = {
    "email/from/mealie" = { };
    "mealie/api_keys" = { };
  };

  sops.templates."mealie/env" = {
    content = ''
      BASE_URL=https://mle.${config.sops.placeholder."tailscale_api/tailnet"}
      OIDC_CLIENT_ID=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}
      OIDC_CLIENT_SECRET=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}
      SMTP_HOST=${config.sops.placeholder."email/smtp/host"}
      SMTP_FROM_EMAIL=${config.sops.placeholder."email/from/mealie"}
      SMTP_USER=${config.sops.placeholder."email/smtp/username"}
      SMTP_PASSWORD=${config.sops.placeholder."email/smtp/password"}
      OPENAI_API_KEY=hunter2
    '';
  };

}
