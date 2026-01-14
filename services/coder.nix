{ config, ... }:
{
  services.coder = {
    enable = true;
    accessUrl = "https://coder.kedi.dev";
    listenAddress = "[::1]:3030";
    environment = {
      extra = {
        CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS = "true";
        CODER_OAUTH2_GITHUB_ALLOWED_ORGS = "ananthb";
        DOCKER_HOST = "unix:///run/podman/podman.sock";
      };
      file = config.sops.templates."coder/env".path;
    };
  };

  users.users.coder.extraGroups = [ "podman" ];

  sops.templates."coder/env" = {
    text = ''
      CODER_OAUTH2_GITHUB_CLIENT_ID=${config.sops.placeholder."github/oauth/kedi-coder/id"}
      CODER_OAUTH2_GITHUB_CLIENT_SECRET=${config.sops.placeholder."github/oauth/kedi-coder/secret"}
    '';
  };

  sops.secrets = {
    "github/oauth/kedi-coder/id" = { };
    "github/oauth/kedi-coder/secret" = { };
  };
}
