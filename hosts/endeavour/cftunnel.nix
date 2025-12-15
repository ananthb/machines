{ config, ... }:
{
  services.cloudflared = {
    enable = true;
    tunnels."kedi" = {
      default = "http_status:404";
      ingress = {
        "6a.kedi.dev" = "http://[fdc0:6625:5195::45]:8123";
        "apps.kedi.dev" = "http://voyager:8082"; # TODO: move off of tailscale
        "davis.kedi.dev" = "http://[fdc0:6625:5195::45]:4101";
        "immich.kedi.dev" = "http://localhost:2283";
        "miniflux.kedi.dev" = "http://[fdc0:6625:5195::45]:8088";
        "open-webui.kedi.dev" = "http://localhost:8090";
        "seafile.kedi.dev" = "http://localhost:4000";
        "seerr.kedi.dev" = "http://[fdc0:6625:5195::45]:5055";
        "vault.kedi.dev" = "http://[fdc0:6625:5195::45]:8222";
        "wallabag.kedi.dev" = "http://[fdc0:6625:5195::45]:8085";
      };
      credentialsFile =
        config.sops.secrets."cloudflared/tunnels/5fd5fbd5-fc21-4766-b92e-a8b577b4bda5/credentials".path;
    };
  };

  sops.secrets = {
    "cloudflared/tunnels/5fd5fbd5-fc21-4766-b92e-a8b577b4bda5/credentials" = { };
  };

}
