# To add a new tunnel:
# 1. cloudflared tunnel login <the-token-you-see-in-dashboard>
# 2. cloudflared tunnel create ConvenientTunnelName
# 3. Add the tunnel ID and name below
# 4. Add the credentials to sops: sops secrets/cloudflare/tunnels/<tunnel-id>/credentials
#
# For dashboard-managed tunnels (required for browser-based RDP, etc.):
# - Add to `dashboardManaged` instead of `tunnels`
# - Configure public hostnames in Cloudflare Zero Trust dashboard
{
  # Locally-managed tunnels (ingress rules defined here)
  tunnels = {
    endeavour = [
      {
        tunnelId = "5fd5fbd5-fc21-4766-b92e-a8b577b4bda5";
        tunnelName = "kedi-apps-1";
        ingress = {
          "6a.kedi.dev" = "http://localhost:8123";
          "actual.kedi.dev" = "http://localhost:3001";
          "apps.kedi.dev" = "http://localhost:8802";
          "immich.kedi.dev" = "http://localhost:2283";
          "metrics.kedi.dev" = "http://localhost:3000";
          "miniflux.kedi.dev" = "http://localhost:8088";
          "radicale.kedi.dev" = "http://localhost:5232";
          "seafile.kedi.dev" = "http://localhost:4444";
          "seerr.kedi.dev" = "http://localhost:5055";
          "vault.kedi.dev" = "http://localhost:8222";
          "wallabag.kedi.dev" = "http://localhost:8085";
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

  # Dashboard-managed tunnels (ingress rules configured in Cloudflare dashboard)
  dashboardManaged = {
    enterprise = {
      tunnelId = "547c677a-cb80-471c-b5b2-c4ab61ff2750";
      tunnelName = "kedi-compute-1";
    };
  };

  # For locally-managed tunnels
  mkCftunnel =
    { hostname }:
    let
      cfgs = (import ./cftunnel.nix).tunnels.${hostname};
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
              inherit (cfg) ingress;
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

  # For dashboard-managed tunnels (config fetched from Cloudflare)
  mkDashboardManagedTunnel =
    { hostname }:
    let
      cfg = (import ./cftunnel.nix).dashboardManaged.${hostname};
    in
    { config, ... }:
    {
      services.cloudflared = {
        enable = true;
        tunnels.${cfg.tunnelName} = {
          credentialsFile = config.sops.secrets."cloudflare/tunnels/${cfg.tunnelId}/credentials".path;
          default = "http_status:404";
        };
      };

      sops.secrets."cloudflare/tunnels/${cfg.tunnelId}/credentials" = { };
    };
}
