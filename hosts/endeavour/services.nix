{
  config,
  pkgs,
  ...
}:

{
  services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = false;

  services.prometheus.exporters = {
    postgres.enable = true;
    postgres.runAsLocalSuperUser = true;

    redis.enable = true;

    nut = {
      enable = true;
      nutUser = "nutmon";
      passwordPath = config.sops.secrets."passwords/nut/nutmon".path;
    };

  };

  # arr stack
  services.qbittorrent = {
    enable = true;
    group = "media";
    serverConfig = {
      LegalNotice.Accepted = true;
      BitTorrent = {
        MergeTrackersEnabled = true;
        Session = {
          AddTorrentStopped = false;
          DefaultSavePath = "/srv/media/Downloads";
          MaxActiveTorrents = -1;
          MaxActiveUploads = -1;
          QueueingSystemEnabled = true;
          ProxyPeerConnections = false;
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

  services.radarr.enable = true;
  services.radarr.group = "media";
  systemd.services.radarr.serviceConfig.UMask = "0002";
  systemd.services.radarr.wants = [
    "transmission.service"
    "prowlarr.service"
  ];

  services.sonarr.enable = true;
  services.sonarr.group = "media";
  systemd.services.sonarr.serviceConfig.UMask = "0002";
  systemd.services.sonarr.wants = [
    "transmission.service"
    "prowlarr.service"
  ];

  services.prowlarr.enable = true;

  sops.secrets."passwords/nut/nutmon".mode = "0444";
}
