{
  pkgs,
  pkgs-unstable,
  ...
}:

{
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
          AuthSubnetWhitelist = "0.0.0.0/0";
          AuthSubnetWhitelistEnabled = true;
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
    package = pkgs-unstable.radarr;
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
    package = pkgs-unstable.sonarr;
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
    package = pkgs-unstable.prowlarr;
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
}
