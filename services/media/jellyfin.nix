{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ../caddy.nix
  ];

  users.groups.media.members = [
    username
    "jellyfin"
  ];

  environment.systemPackages = with pkgs; [
    jellyfin-web
    jellyfin-ffmpeg
  ];

  nixpkgs.overlays = [
    # Modify jellyfin-web index.html for the intro-skipper plugin to work.
    # intro skipper plugin has to be installed from the UI.
    (_final: prev: {
      jellyfin-web = prev.jellyfin-web.overrideAttrs (
        _finalAttrs: _previousAttrs: {
          installPhase = ''
            runHook preInstall

            # this is the important line
            sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html

            mkdir -p $out/share
            cp -a dist $out/share/jellyfin-web

            runHook postInstall
          '';
        }
      );
    })
  ];

  services = {
    jellyfin = {
      enable = true;
      group = "media";
      openFirewall = true;
    };

    tsnsrv = {
      enable = true;
      defaults.authKeyPath = config.sops.secrets."tailscale_api/auth_key".path;
      defaults.urlParts.host = "localhost";
      services.tv = {
        funnel = true;
        urlParts.port = 8096;
      };
    };

    caddy = {
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
                    #   2. Must end with static ip suffix
                    # ------------------------------------------------------------------------

            	${pkgs.iproute2}/bin/ip -6 addr show scope global | \
                      ${pkgs.gawk}/bin/awk '/inet6 24[0-1].*::0f\// { sub(/\/.*$/, "", $2); print $2 }'
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
  };

  systemd.services = {
    caddy = {
      after = [ "jellyfin.service" ];
      wants = [ "jellyfin.service" ];
      serviceConfig = {
        EnvironmentFile = config.sops.templates."caddy/secrets.env".path;
      };
    };
    tsnsrv-tv.wants = [ "jellyfin.service" ];
    tsnsrv-tv.after = [ "jellyfin.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 443 ];

  sops.secrets = {
    "cloudflare/api_tokens/ddns" = { };
    "tailscale_api/auth_key" = { };
  };

  sops.templates."caddy/secrets.env".content = ''
    CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare/api_tokens/ddns"}
  '';

}
