{ ... }:
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
      "qbittorrent.service"
    ];
    wants = [
      "postgresql.service"
      "qbittorrent.service"
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
      "qbittorrent.service"
    ];
    wants = [
      "postgresql.service"
      "qbittorrent.service"
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
      "qbittorrent.service"
    ];
    wants = [
      "postgresql.service"
      "radarr.service"
      "sonarr.service"
      "qbittorrent.service"
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
