{
  config,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../warp.nix
    ../monitoring/postgres.nix
  ];

  # Media group membership
  users.groups.media.members = [
    username
    "qbittorrent"
    "radarr"
    "sonarr"
    "cross-seed"
  ];

  # Services
  services = {
    qbittorrent = {
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

    radarr = {
      enable = true;
      group = "media";
      openFirewall = true;
    };

    sonarr = {
      enable = true;
      group = "media";
      openFirewall = true;
    };

    prowlarr = {
      enable = true;
      openFirewall = true;
    };

    jellyseerr.enable = true;

    cross-seed = {
      enable = true;
      group = "media";
      settings = {
        torrentClients = [ "qbittorrent:http://localhost:8080" ];
        dataDirs = [ "/srv/media/Downloads" ];
        linkType = "hardlink";
        matchMode = "safe";
        action = "inject";
        duplicateCategories = true;
      };
      settingsFile = config.sops.templates."cross-seed/config.json".path;
    };

    postgresql = {
      enable = true;
      ensureDatabases = [
        "radarr-main"
        "radarr-log"
        "sonarr-main"
        "sonarr-log"
        "prowlarr-main"
        "prowlarr-log"
        "jellyseerr"
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
        {
          name = "jellyseerr";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    prometheus.exporters = {
      exportarr-radarr = {
        enable = true;
        url = "http://localhost:7878";
        port = 9708;
        apiKeyFile = config.sops.secrets."arr_apis/radarr".path;
      };

      exportarr-sonarr = {
        enable = true;
        url = "http://localhost:8989";
        port = 9709;
        apiKeyFile = config.sops.secrets."arr_apis/sonarr".path;
      };

      exportarr-prowlarr = {
        enable = true;
        url = "http://localhost:9696";
        port = 9710;
        apiKeyFile = config.sops.secrets."arr_apis/prowlarr".path;
      };
    };
  };

  systemd.services = {
    qbittorrent.serviceConfig.UMask = "0002";

    radarr = {
      serviceConfig.UMask = "0002";
      after = [ "postgresql.service" ];
      wants = [ "qbittorrent.service" ];
    };

    sonarr = {
      serviceConfig.UMask = "0002";
      after = [ "postgresql.service" ];
      wants = [ "postgresql.service" ];
    };

    prowlarr = {
      after = [
        "postgresql.service"
        "radarr.service"
        "sonarr.service"
      ];
      wants = [
        "postgresql.service"
        "radarr.service"
        "sonarr.service"
      ];
    };

    jellyseerr.environment = {
      DB_TYPE = "postgres";
      DB_SOCKET_PATH = "/var/run/postgresql";
      DB_USER = "jellyseerr";
      DB_NAME = "jellyseerr";
    };

    cross-seed = {
      after = [
        "qbittorrent.service"
        "prowlarr.service"
      ];
      wants = [
        "qbittorrent.service"
        "prowlarr.service"
      ];
      serviceConfig.UMask = "0002";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/media 0775 root media -"
    "d /srv/media/Downloads 0775 root media -"
    "d /srv/media/Movies 0775 root media -"
    "d /srv/media/Shows 0775 root media -"
  ];

  # Secrets
  sops.secrets = {
    "arr_apis/radarr".mode = "0444";
    "arr_apis/sonarr".mode = "0444";
    "arr_apis/prowlarr".mode = "0444";
  };

  # Indexers: 1=TorrentLeech, 2=Nyaa.si, 3=FearNoPeer
  sops.templates."cross-seed/config.json" = {
    owner = "cross-seed";
    content = builtins.toJSON {
      torznab = [
        "http://localhost:9696/1/api?apikey=${config.sops.placeholder."arr_apis/prowlarr"}"
        "http://localhost:9696/2/api?apikey=${config.sops.placeholder."arr_apis/prowlarr"}"
        "http://localhost:9696/3/api?apikey=${config.sops.placeholder."arr_apis/prowlarr"}"
        "http://localhost:9696/4/api?apikey=${config.sops.placeholder."arr_apis/prowlarr"}"
      ];
    };
  };
}
