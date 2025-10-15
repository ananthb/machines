{ config, pkgs-unstable, ... }:
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

  sops.secrets."email/from/mealie" = { };

  sops.templates."mealie/env" = {
    content = ''
      BASE_URL=https://mle.${config.sops.placeholder."tailscale_api/tailnet"}
      OIDC_CLIENT_ID=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}
      OIDC_CLIENT_SECRET=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}
      SMTP_HOST=${config.sops.placeholder."email/smtp/host"}
      SMTP_FROM_EMAIL=${config.sops.placeholder."email/from/mealie"}
      SMTP_USER=${config.sops.placeholder."email/smtp/username"}
      SMTP_PASSWORD=${config.sops.placeholder."email/smtp/password"}
    '';
  };

}
