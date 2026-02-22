{
  config,
  pkgs,
  username,
  ...
}:
let
  vs = config.vault-secrets.secrets;
in
{
  imports = [
    ((import ../../lib/caddy-ddns.nix).mkCaddyDdns { domains = [ "tv" ]; })
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
      defaults.authKeyPath = "${vs.tailscale-api}/auth_key";
      defaults.urlParts.host = "localhost";
      services.tv = {
        funnel = true;
        urlParts.port = 8096;
      };
    };

    caddy.virtualHosts."tv.kedi.dev" = {
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

  my-services.kediTargets.jellyfin = true;
  my-services.kediTargets.tsnsrv-tv = true;

  systemd.services = {
    jellyfin = {
      partOf = [ "kedi.target" ];
    };
    caddy = {
      after = [ "jellyfin.service" ];
      wants = [ "jellyfin.service" ];
      partOf = [ "kedi.target" ];
    };
    tsnsrv-tv = {
      wants = [ "jellyfin.service" ];
      after = [ "jellyfin.service" ];
      partOf = [ "kedi.target" ];
    };
  };

  vault-secrets.secrets.tailscale-api = {
    services = [
      "tsnsrv-tv"
    ];
  };

}
