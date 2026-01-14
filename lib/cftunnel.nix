# To add a new tunnel:
# 1. cloudflared tunnel login <the-token-you-see-in-dashboard>
# 2. cloudflared tunnel create ConvenientTunnelName
# 3. Add the tunnel ID and name below
# 4. Add the credentials to sops: sops secrets/cloudflare/tunnels/<tunnel-id>/credentials
{
  mkTunnels = ulaPrefix: {
    endeavour = [
      {
        tunnelId = "5fd5fbd5-fc21-4766-b92e-a8b577b4bda5";
        tunnelName = "kedi-apps-1";
        ingress = {
          "6a.kedi.dev" = "http://localhost:8123";
          "actual.kedi.dev" = "http://localhost:3001";
          "apps.kedi.dev" = "http://localhost:8082";
          "immich.kedi.dev" = "http://localhost:2283";
          "miniflux.kedi.dev" = "http://localhost:8088";
          "open-webui.kedi.dev" = "http://localhost:8090";
          "radicale.kedi.dev" = "http://localhost:5232";
          "seafile.kedi.dev" = "http://localhost:4000";
          "seerr.kedi.dev" = "http://localhost:5055";
          "vault.kedi.dev" = "http://localhost:8222";
          "wallabag.kedi.dev" = "http://localhost:8085";
        };
      }
    ];

    enterprise = [
      {
        tunnelId = "547c677a-cb80-471c-b5b2-c4ab61ff2750";
        tunnelName = "kedi-vms-1";
        ingress = {
          "win11.kedi.dev" = "rdp://192.168.122.11:3389";
        };
      }
    ];

    stargazer = [
      {
        tunnelId = "b6a4a4a7-3f48-4b10-a39f-fc2ef1f7b0c7";
        tunnelName = "kedi-ext-1";
        ingress = {
          "t1.kedi.dev" = "http://localhost:8123";
          "mealie.kedi.dev" = "http://localhost:9000";
        };
      }
    ];
  };

  mkCftunnel =
    { hostname, ulaPrefix }:
    let
      tunnels = (import ./cftunnel.nix).mkTunnels ulaPrefix;
      cfgs = tunnels.${hostname};
    in
    { config, ... }:
    {
      services.cloudflared = {
        enable = true;
        tunnels = builtins.listToAttrs (
          map (cfg: {
            name = cfg.tunnelName;
            value = {
              default = "http_status:404";
              ingress = cfg.ingress;
              credentialsFile = config.sops.secrets."cloudflare/tunnels/${cfg.tunnelId}/credentials".path;
            };
          }) cfgs
        );
      };

      sops.secrets = builtins.listToAttrs (
        map (cfg: {
          name = "cloudflare/tunnels/${cfg.tunnelId}/credentials";
          value = { };
        }) cfgs
      );
    };
}
