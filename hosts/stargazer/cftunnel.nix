{ config, ... }:
{
  services.cloudflared = {
    enable = true;
    tunnels."kedi" = {
      default = "http_status:404";
      ingress = {
        "t1.kedi.dev" = "http://localhost:8123";
        "mealie.kedi.dev" = "http://localhost:9000";
      };
      credentialsFile =
        config.sops.secrets."cloudflare/tunnels/b6a4a4a7-3f48-4b10-a39f-fc2ef1f7b0c7/credentials".path;
    };
  };

  sops.secrets."cloudflare/tunnels/b6a4a4a7-3f48-4b10-a39f-fc2ef1f7b0c7/credentials" = { };

}
