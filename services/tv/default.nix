{
  config,
  pkgs,
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
      passwordFile = config.sops.secrets."ddclient/cf_token".path;
      protocol = "cloudflare";
      interval = "5min";
      usev4 = "disabled";
      usev6 = "cmdv6,cmdv6=${getIPv6}";
      zone = "kedi.dev";
      domains = [
        "tv.kedi.dev"
      ];
    };
  services.caddy.virtualHosts."tv.kedi.dev".extraConfig = ''
    reverse_proxy http://localhost:8096
  '';
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

}
