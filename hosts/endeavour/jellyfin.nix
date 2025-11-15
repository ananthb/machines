{
  config,
  inputs,
  pkgs-unstable,
  ...
}:
{
  imports = [
    inputs.tsnsrv.nixosModules.default
  ];

  environment.systemPackages = with pkgs-unstable; [
    jellyfin-web
    jellyfin-ffmpeg
  ];

  services.jellyfin = {
    enable = true;
    package = pkgs-unstable.jellyfin;
    group = "media";
    openFirewall = true;
  };

  services.tsnsrv = {
    enable = true;

    defaults.authKeyPath = config.sops.secrets."tailscale_api/auth_key".path;
    defaults.urlParts.host = "localhost";

    services.tv = {
      funnel = true;
      urlParts.port = 8096;
    };
  };

  systemd.services.tsnsrv-tv.wants = [ "jellyfin.service" ];
  systemd.services.tsnsrv-tv.after = [ "jellyfin.service" ];

  nixpkgs.overlays = [
    # Modify jellyfin-web index.html for the intro-skipper plugin to work.
    # intro skipper plugin has to be installed from the UI.
    (final: prev: {
      jellyfin-web = prev.jellyfin-web.overrideAttrs (
        finalAttrs: previousAttrs: {
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

  sops.secrets."tailscale_api/auth_key" = { };

}
