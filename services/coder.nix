{ config, ... }:

{
  services.coder = {
    enable = true;
    accessUrl = "https://coder.kedi.dev";
    listenAddress = "[::1]:3002";
    environment = {
      extra = {
        CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS = true;
        CODER_OAUTH2_GITHUB_ALLOWED_ORGS = "ananthb";
      };
      file = config.sops.templates."coder/env".path;
    };
  };

  sops.templates."coder/env" = {
    content = ''
      CODER_OAUTH2_GITHUB_CLIENT_ID=${config.sops.placeholder."github/oauth/kedi-coder/id"}
      CODER_OAUTH2_GITHUB_CLIENT_SECRET=${config.sops.placeholder."github/oauth/kedi-coder/secret"}
    '';
  };

  sops.secrets = {
    "github/oauth/kedi-coder/id" = { };
    "github/oauth/kedi-coder/secret" = { };
  };
}
