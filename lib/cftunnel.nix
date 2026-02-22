# To add a new tunnel:
# 1. cloudflared tunnel login <the-token-you-see-in-dashboard>
# 2. cloudflared tunnel create ConvenientTunnelName
# 3. Add the tunnel ID and name below
# 4. Add the credentials to Vault (vault-secrets) under the tunnel secret path
#
# For browser-based RDP:
# - Add a Private Network route in Cloudflare Zero Trust dashboard (Networks → Tunnels → Private Network)
# - Add an Access Target (Access → Infrastructure → Targets) for the RDP host IP
# - Create an Access Application with Browser Rendering → RDP enabled
{
  tunnels = {
    endeavour = [
      {
        tunnelId = "5fd5fbd5-fc21-4766-b92e-a8b577b4bda5";
        tunnelName = "kedi-apps-1";
        ingress = {
          "kedi.dev" = "http://localhost:8802";
          "6a.kedi.dev" = "http://localhost:8123";
          "actual.kedi.dev" = "http://localhost:3001";
          "calibre.kedi.dev" = "http://localhost:8086";
          "immich.kedi.dev" = "http://localhost:2283";
          "metrics.kedi.dev" = "http://localhost:3000";
          "miniflux.kedi.dev" = "http://localhost:8088";
          "seafile.kedi.dev" = "http://localhost:4444";
          "seerr.kedi.dev" = "http://localhost:5055";
          "vault.kedi.dev" = "http://localhost:8222";
          "wallabag.kedi.dev" = "http://localhost:8085";
        };
      }
    ];

    enterprise = [
      {
        tunnelId = "cc636509-3456-4589-ae08-d4be710305a5";
        tunnelName = "kedi-compute-1";
        ingress = {
          "coder.kedi.dev" = "http://localhost:3030";
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
    { hostname }:
    let
      cfgs = (import ./cftunnel.nix).tunnels.${hostname};
    in
    { config, ... }:
    let
      vs = config.vault-secrets.secrets;
    in
    {
      services.cloudflared = {
        enable = true;
        tunnels = builtins.listToAttrs (
          map (cfg: {
            name = cfg.tunnelId;
            value = {
              default = "http_status:404";
              inherit (cfg) ingress;
              credentialsFile = "${vs."cloudflare-tunnel-${cfg.tunnelId}"}/credentials";
            };
          }) cfgs
        );
      };

      vault-secrets.secrets = builtins.listToAttrs (
        map (cfg: {
          name = "cloudflare-tunnel-${cfg.tunnelId}";
          value = {
            services = [ "cloudflared-tunnel-${cfg.tunnelId}" ];
          };
        }) cfgs
      );
    };
}
