# Caddy with dynamic DNS for IPv6
# Creates a NixOS module that configures Caddy with cloudflare DDNS
# for keeping AAAA records up to date with the host's IPv6 address.
#
# Usage:
#   imports = [ (lib/caddy-ddns.nix).mkCaddyDdns { domains = [ "tv" "*.coder" ]; } ];
{
  mkCaddyDdns =
    { domains }:
    {
      config,
      pkgs,
      ipv6Token,
      ...
    }:
    let
      getIPv6 = pkgs.writeShellScript "get-ipv6" ''
        # ------------------------------------------------------------------------
        # ddns custom IPv6 getter
        # Returns a GUA (Global Unicast Address) IPv6 address
        # filtered by the token set for this host (${ipv6Token})
        # GUA addresses are in the 2000::/3 range (start with 2 or 3)
        # ------------------------------------------------------------------------

        ${pkgs.iproute2}/bin/ip -6 addr show scope global | \
          ${pkgs.gawk}/bin/awk '/inet6 [23].*${ipv6Token}\// { sub(/\/.*$/, "", $2); print $2; exit }'
      '';

      domainList = builtins.concatStringsSep " " domains;
    in
    {
      imports = [ ../services/caddy.nix ];

      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/mholt/caddy-dynamicdns@v0.0.0-20251020155855-d8f490a28db6"
            "github.com/mietzen/caddy-dynamicdns-cmd-source@v0.2.0"
            "github.com/caddy-dns/cloudflare@v0.2.2"
          ];
          hash = "sha256-kNPGPreK/BPvkfjIrDKDKxoTUIZxF1k9sEy3VhsT2iI=";
        };

        globalConfig = ''
          email srv.acme@kedi.dev
          acme_ca https://acme-v02.api.letsencrypt.org/directory

          dynamic_dns {
            provider cloudflare {$CLOUDFLARE_API_TOKEN}
            domains {
              kedi.dev ${domainList}
            }
            ip_source command ${getIPv6}
            versions ipv6
            check_interval 5m
            ttl 1h
          }
        '';
      };

      systemd.services.caddy.serviceConfig = {
        EnvironmentFile = config.sops.templates."caddy/secrets.env".path;
      };

      networking.firewall.allowedTCPPorts = [ 443 ];

      sops.secrets."cloudflare/api_tokens/ddns" = { };

      sops.templates."caddy/secrets.env".content = ''
        CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare/api_tokens/ddns"}
      '';
    };
}
