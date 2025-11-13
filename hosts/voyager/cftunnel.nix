{ config, ... }:
{
  services.cloudflared = {
    enable = true;
    tunnels."kedi" = {
      default = "http_status:404";
      ingress = {
        "6a.kedi.dev" = "http://localhost:8123";
        "actual.kedi.dev" = "http://localhost:3100";
        "immich.kedi.dev" = "http://endeavour:2283";
        "mealie.kedi.dev" = "http://localhost:9000";
        "open-webui.kedi.dev" = "http://endeavour:8090";
        "radicale.kedi.dev" = "http://localhost:5232";
        "seafile.kedi.dev" = "http://endeavour:4000";
        "vault.kedi.dev" = "http://localhost:8222";
      };
      credentialsFile =
        config.sops.secrets."cloudflared/tunnels/5fd5fbd5-fc21-4766-b92e-a8b577b4bda5/credentials".path;
    };
  };

  sops.secrets = {
    "cloudflared/tunnels/5fd5fbd5-fc21-4766-b92e-a8b577b4bda5/credentials" = { };
  };

}
