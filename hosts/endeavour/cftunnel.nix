{ config, ... }:
{
  services.cloudflared = {
    enable = true;
    tunnels."kedi" = {
      default = "http_status:404";
      ingress = {
        "6a.kedi.dev" = "http://voyager.local:8123";
        "actual.kedi.dev" = "http://voyager.local:3100";
        "apps.kedi.dev" = "http://voyager:8082"; # TODO: switch to .local after making it work
        "immich.kedi.dev" = "http://localhost:2283";
        "mealie.kedi.dev" = "http://voyager.local:9000";
        "open-webui.kedi.dev" = "http://localhost:8090";
        "radicale.kedi.dev" = "http://voyager.local:5232";
        "seafile.kedi.dev" = "http://localhost:4000";
        "vault.kedi.dev" = "http://voyager.local:8222";
      };
      credentialsFile =
        config.sops.secrets."cloudflared/tunnels/5fd5fbd5-fc21-4766-b92e-a8b577b4bda5/credentials".path;
    };
  };

  sops.secrets = {
    "cloudflared/tunnels/5fd5fbd5-fc21-4766-b92e-a8b577b4bda5/credentials" = { };
  };

}
