{ config, ... }:

{
  services.coder = {
    enable = true;
    accessUrl = "https://coder.kedi.dev";
    listenAddress = "[::1]:3002";
    environment.file = config.sops.templates."coder/env".path;
  };

  sops.templates."coder/env" = {
    content = ''
      CODER_OIDC_ISSUER_URL=https://accounts.google.com
      CODER_OIDC_EMAIL_DOMAIN=
      CODER_OIDC_CLIENT_ID=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}
      CODER_OIDC_CLIENT_SECRET=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}
    '';
  };

  sops.secrets = {
    "gcloud/oauth_self-hosted_clients/id" = { };
    "gcloud/oauth_self-hosted_clients/secret" = { };
  };
}
