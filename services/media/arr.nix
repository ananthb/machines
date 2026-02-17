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
        linkType = "hardlink";
        linkDirs = [ "/srv/media/Downloads/cross-seed" ];
        matchMode = "partial";
        action = "inject";
        duplicateCategories = true;
      };
      settingsFile = "${vs.arr}/cross-seed/config.json";
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
        apiKeyFile = "${vs.arr}/radarr";
      };

      exportarr-sonarr = {
        enable = true;
        url = "http://localhost:8989";
        port = 9709;
        apiKeyFile = "${vs.arr}/sonarr";
      };

      exportarr-prowlarr = {
        enable = true;
        url = "http://localhost:9696";
        port = 9710;
        apiKeyFile = "${vs.arr}/prowlarr";
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

  vault-secrets.secrets.arr = {
    services = [
      "radarr"
      "sonarr"
      "prowlarr"
      "cross-seed"
    ];
    secretsKey = null;
    group = "media";
    extraScript = ''
      umask 0077
      printf '%s' "$RADARR_API_KEY" > "$secretsPath/radarr"
      printf '%s' "$SONARR_API_KEY" > "$secretsPath/sonarr"
      printf '%s' "$PROWLARR_API_KEY" > "$secretsPath/prowlarr"

      mkdir -p "$secretsPath/cross-seed"
      cat > "$secretsPath/cross-seed/config.json" <<EOF
      {
        "radarr": ["http://localhost:7878/?apikey=''${RADARR_API_KEY}"],
        "sonarr": ["http://localhost:8989/?apikey=''${SONARR_API_KEY}"],
        "torznab": [
          "http://localhost:9696/1/api?apikey=''${PROWLARR_API_KEY}",
          "http://localhost:9696/2/api?apikey=''${PROWLARR_API_KEY}",
          "http://localhost:9696/3/api?apikey=''${PROWLARR_API_KEY}",
          "http://localhost:9696/4/api?apikey=''${PROWLARR_API_KEY}"
        ]
      }
      EOF
    '';
  };
}
