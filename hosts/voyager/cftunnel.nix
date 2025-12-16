{ config, ... }:
{
  services.cloudflared = {
    enable = true;
    tunnels."kedi" = {
      default = "http_status:404";
      ingress = {
        "6a.kedi.dev" = "http://localhost:8123";
        "apps.kedi.dev" = "http://localhost:8082";
        "davis.kedi.dev" = "http://localhost:4101";
        "immich.kedi.dev" = "http://[fdc0:6625:5195::50]:2283";
        "miniflux.kedi.dev" = "http://localhost:8088";
        "open-webui.kedi.dev" = "http://[fdc0:6625:5195::50]:8090";
        "seafile.kedi.dev" = "http://[fdc0:6625:5195::50]:4000";
        "seerr.kedi.dev" = "http://localhost:5055";
        # TODO: enable when we've moved it back to voyager
	# "vault.kedi.dev" = "http://localhost:8222";
        "wallabag.kedi.dev" = "http://localhost:8085";
      };
      credentialsFile =
        config.sops.secrets."cloudflared/tunnels/5fd5fbd5-fc21-4766-b92e-a8b577b4bda5/credentials".path;
    };
  };

  sops.secrets = {
    "cloudflared/tunnels/5fd5fbd5-fc21-4766-b92e-a8b577b4bda5/credentials" = { };
  };

}
