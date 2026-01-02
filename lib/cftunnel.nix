{
  tunnels = {
    endeavour = {
      tunnelId = "5fd5fbd5-fc21-4766-b92e-a8b577b4bda5";
      tunnelName = "kedi";
      ingress = {
        "6a.kedi.dev" = "http://localhost:8123";
        "actual.kedi.dev" = "http://localhost:3001";
        "apps.kedi.dev" = "http://localhost:8082";
        "davis.kedi.dev" = "http://localhost:4101";
        "immich.kedi.dev" = "http://[fdc0:6625:5195::55]:2283";
        "miniflux.kedi.dev" = "http://localhost:8088";
        "open-webui.kedi.dev" = "http://localhost:8090";
        "radicale.kedi.dev" = "http://localhost:5232";
        "seafile.kedi.dev" = "http://[fdc0:6625:5195::55]:4000";
        "seerr.kedi.dev" = "http://localhost:5055";
        "vault.kedi.dev" = "http://localhost:8222";
        "wallabag.kedi.dev" = "http://localhost:8085";
      };
    };

    enterprise = {
      tunnelId = "5fd5fbd5-fc21-4766-b92e-a8b577b4bda5";
      tunnelName = "kedi";
      ingress = {
        "6a.kedi.dev" = "http://[fdc0:6625:5195::50]:8123";
        "actual.kedi.dev" = "http://[fdc0:6625:5195::50]:3001";
        "apps.kedi.dev" = "http://endeavour:8082";
        "davis.kedi.dev" = "http://[fdc0:6625:5195::50]:4101";
        "immich.kedi.dev" = "http://localhost:2283";
        "miniflux.kedi.dev" = "http://[fdc0:6625:5195::50]:8088";
        "open-webui.kedi.dev" = "http://[fdc0:6625:5195::50]:8090";
        "radicale.kedi.dev" = "http://[fdc0:6625:5195::50]:5232";
        "seafile.kedi.dev" = "http://localhost:4000";
        "seerr.kedi.dev" = "http://[fdc0:6625:5195::50]:5055";
        "vault.kedi.dev" = "http://[fdc0:6625:5195::50]:8222";
        "wallabag.kedi.dev" = "http://[fdc0:6625:5195::50]:8085";
      };
    };

    stargazer = {
      tunnelId = "b6a4a4a7-3f48-4b10-a39f-fc2ef1f7b0c7";
      tunnelName = "kedi";
      ingress = {
        "t1.kedi.dev" = "http://localhost:8123";
        "mealie.kedi.dev" = "http://localhost:9000";
      };
    };
  };

  mkCftunnel =
    { hostname }:
    let
      tunnels = (import ./cftunnel.nix).tunnels;
      cfg = tunnels.${hostname};
    in
    { config, ... }:
    {
      services.cloudflared = {
        enable = true;
        tunnels.${cfg.tunnelName} = {
          default = "http_status:404";
          ingress = cfg.ingress;
          credentialsFile = config.sops.secrets."cloudflare/tunnels/${cfg.tunnelId}/credentials".path;
        };
      };

      sops.secrets."cloudflare/tunnels/${cfg.tunnelId}/credentials" = { };
    };
}
