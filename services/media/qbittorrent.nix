{ pkgs, ... }:
{
  services.qbittorrent = {
    enable = true;
    group = "media";
    webuiPort = 8000;
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
          LocalHostAuth = false;
          AuthSubnetWhitelist = "0.0.0.0/0,::/0";
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
  systemd.services.qbittorrent.serviceConfig.UMask = "0002";
}
