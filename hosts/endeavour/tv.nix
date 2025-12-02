{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.tsnsrv.nixosModules.default
  ];

  environment.systemPackages = with pkgs; [
    jellyfin-web
    jellyfin-ffmpeg
  ];

  services.jellyfin = {
    enable = true;
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

  services.qbittorrent = {
    enable = true;
    group = "media";
    openFirewall = true;
    serverConfig = {
      LegalNotice.Accepted = true;
      BitTorrent = {
        MergeTrackersEnabled = true;
        Session = {
          AddTorrentStopped = false;
          DefaultSavePath = "/srv/media/Downloads";
          MaxActiveTorrents = -1;
          MaxActiveUploads = -1;
          MaxConnections = -1;
          MaxConnectionsPerTorrent = -1;
          MaxUploads = -1;
          MaxUploadsPerTorrent = -1;
          ProxyPeerConnections = false;
          QueueingSystemEnabled = true;
        };
      };
      Preferences = {
        WebUI = {
          Password_PBKDF2 = "@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)";
          AlternativeUIEnabled = true;
          RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
        };
      };
      Network = {
        Proxy = {
          AuthEnabled = false;
          HostnameLookupEnabled = true;
          IP = "127.0.0.1";
          Port = 8888;
          Type = "SOCKS5";
          Profiles = {
            BitTorrent = true;
            Misc = true;
            RSS = true;
          };
        };
      };
    };
  };

  systemd.services.qbittorrent.unitConfig.RequiresMountsFor = "/srv";
  systemd.services.qbittorrent.serviceConfig.UMask = "0002";

  services.radarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };
  systemd.services.radarr = {
    serviceConfig.UMask = "0002";
    after = [
      "postgresql.service"
      "transmission.service"
    ];
    wants = [
      "postgresql.service"
      "transmission.service"
    ];
  };

  services.sonarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };
  systemd.services.sonarr = {
    serviceConfig.UMask = "0002";
    after = [
      "postgresql.service"
      "transmission.service"
    ];
    wants = [
      "postgresql.service"
      "transmission.service"
    ];
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.prowlarr = {
    after = [
      "postgresql.service"
      "radarr.service"
      "sonarr.service"
      "transmission.service"
    ];
    wants = [
      "postgresql.service"
      "radarr.service"
      "sonarr.service"
      "transmission.service"
    ];
  };

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

  sops.secrets."tailscale_api/auth_key" = { };
}
