{
  config,
  pkgs,
  system,
  trustedIPs,
  username,
  ...
}:
{
  imports = [
    ./jellyfin.nix
    ./prowlarr.nix
    ./qbittorrent.nix
    ./radarr.nix
    ./sonarr.nix
  ];

  users.groups.media.members = [
    username
    "jellyfin"
    "radarr"
    "sonarr"
    "qbittorrent"
  ];

  # Jellyfin direct ingress
  services.ddclient =
    let
      getIPv6 = pkgs.writeShellScript "get-ipv6" ''
                # ------------------------------------------------------------------
                # ddclient custom IPv6 getter
                # Criteria: 
                #   1. Must be set on enp2s0 in the 2400::/11 Global Unicast Address Space
                #   2. Must end with :50 (static suffix)
                # ------------------------------------------------------------------

        	${pkgs.iproute2}/bin/ip -6 addr show dev enp2s0 scope global | \
                  ${pkgs.gawk}/bin/awk '/inet6 24[0-1].*::50\// { sub(/\/.*$/, "", $2); print $2 }'
      '';
    in
    {
      enable = true;
      passwordFile = config.sops.secrets."cloudflare/api_tokens/ddns".path;
      protocol = "cloudflare";
      interval = "5min";
      usev4 = "disabled";
      usev6 = "cmdv6,cmdv6=${getIPv6}";
      zone = "kedi.dev";
      domains = [
        "tv.kedi.dev"
      ];
    };

  systemd = {
    services.jellyfin.after = [ "caddy.service" ];
    services.jellyfin.wants = [ "caddy.service" ];
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/zhangjiayin/caddy-geoip2@v0.0.0-20251110021726-8aee010bbbb8"
	"github.com/mholt/caddy-dynamicdns@v0.0.0-20251020155855-d8f490a28db6"
        "github.com/mietzen/caddy-dynamicdns-cmd-source@v0.2.0"
        "github.com/caddy-dns/cloudflare@v0.2.2"
      ];
      hash = "sha256-iOuW5lP6lDONhz7ZMON6p/yYi3ln5B71Ds8Wuiu0bls=";
    };

    globalConfig = ''
      email srv.acme@kedi.dev
      acme_ca https://acme-v02.api.letsencrypt.org/directory

      geoip2 {
        accountId         {$MM_ACCOUNT_ID}
        databaseDirectory "/var/lib/caddy"
        licenseKey        "{$MM_LICENSE_KEY}"
        lockFile          "/run/caddy/geoip2.lock"
        editionID         "GeoLite2-City,GeoLite2-ASN"
        updateUrl         "https://updates.maxmind.com"
        updateFrequency   86400   # in seconds
      }
    '';

    virtualHosts."tv.kedi.dev" = {
      extraConfig = ''
        # TODO: doesn't work for some reason
        @geofilter expression {geoip2.country_code} == "IN"

        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options "nosniff"
          X-XSS-Protection "1; mode=block"
        }

        reverse_proxy localhost:8096
      '';
    };
  };

  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = config.sops.templates."caddy/maxmind.env".path;
    RuntimeDirectory = "caddy";
  };

  networking.firewall.allowedTCPPorts = [ 443 ];

  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "radarr-main"
      "radarr-log"
      "sonarr-main"
      "sonarr-log"
      "prowlarr-main"
      "prowlarr-log"
    ];
    ensureUsers = [
      {
        name = "radarr";
        ensureClauses.login = true;
      }
      {
        name = "sonarr";
        ensureClauses.login = true;
      }
      {
        name = "prowlarr";
        ensureClauses.login = true;
      }
    ];
  };

  sops.secrets = {
    "cloudflare/api_tokens/ddns" = { };
    "maxmind/account_id" = { };
    "maxmind/license_key" = { };
  };

  sops.templates."caddy/maxmind.env".content = ''
    MM_ACCOUNT_ID=${config.sops.placeholder."maxmind/account_id"}
    MM_LICENSE_KEY=${config.sops.placeholder."maxmind/license_key"}
  '';

}
