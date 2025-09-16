{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    jellyfin-web
    jellyfin-ffmpeg
  ];

  services = {
    jellyfin.enable = true;
    jellyfin.group = "media";
    jellyfin.openFirewall = true;

    meilisearch.enable = true;
    meilisearch.package = pkgs.meilisearch;
    meilisearch.listenAddress = "[::]";

    tsnsrv.services.tv = {
      funnel = true;
      urlParts.port = 8096;
    };

    jellyseerr.enable = true;

    tsnsrv.services.watch = {
      funnel = true;
      urlParts.port = 5055;
    };

    postgresql = {
      enable = true;
      ensureDatabases = [ "jellyseerr" ];
      ensureUsers = [
        {
          name = "jellyseerr";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

  };

  systemd.services = {
    tsnsrv-watch.wants = [ "jellyseerr.service" ];
    tsnsrv-watch.after = [ "jellyseerr.service" ];

    jellyseerr.environment = {
      DB_TYPE = "postgres";
      DB_SOCKET_PATH = "/var/run/postgresql";
      DB_USER = "jellyseerr";
      DB_NAME = "jellyseerr";
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

  services.nfs.server = {
    enable = true;
    exports = ''
      /export         *(ro,fsid=0)
      /export/media   *(ro)
    '';
  };

}
