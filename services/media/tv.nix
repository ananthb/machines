{
  config,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../caddy.nix
    ./jellyfin.nix
  ];

  users.groups.media.members = [
    username
    "jellyfin"
  ];

  systemd = {
    services.jellyfin.after = [ "caddy.service" ];
    services.jellyfin.wants = [ "caddy.service" ];
  };

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

    globalConfig =

      let
        getIPv6 = pkgs.writeShellScript "get-ipv6" ''
                  # ------------------------------------------------------------------------
                  # ddns custom IPv6 getter
                  # Criteria: 
                  #   1. Must be set on enp87s0 in the 2400::/11 Global Unicast Address Space
                  #   2. Must end with ::55 (static suffix)
                  # ------------------------------------------------------------------------

          	${pkgs.iproute2}/bin/ip -6 addr show dev enp87s0 scope global | \
                    ${pkgs.gawk}/bin/awk '/inet6 24[0-1].*::55\// { sub(/\/.*$/, "", $2); print $2 }'
        '';
      in

      ''
              email srv.acme@kedi.dev
              acme_ca https://acme-v02.api.letsencrypt.org/directory

              dynamic_dns {
                provider cloudflare {$CLOUDFLARE_API_TOKEN}
        	domains {
        	  kedi.dev tv
        	}
                ip_source command ${getIPv6}
        	versions ipv6
                check_interval 5m
                ttl 1h
              }
      '';

    virtualHosts."tv.kedi.dev" = {
      extraConfig = ''
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options    "nosniff"
          X-XSS-Protection          "1; mode=block"
        }

        reverse_proxy localhost:8096
      '';
    };
  };

  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = config.sops.templates."caddy/secrets.env".path;
  };

  networking.firewall.allowedTCPPorts = [ 443 ];

  sops.secrets = {
    "cloudflare/api_tokens/ddns" = { };
  };

  sops.templates."caddy/secrets.env".content = ''
    CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare/api_tokens/ddns"}
  '';

}
