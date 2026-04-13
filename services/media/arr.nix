{
  config,
  containerImages,
  lib,
  pkgs,
  username,
  ...
}: let
  vs = config.vault-secrets.secrets;
in {
  imports = [
    ../warp.nix
    ../monitoring/postgres.nix
  ];

  # Media group membership
  users.groups.media.members = [
    username
    "caddy"
  ];

  # Services
  services = {
    rtorrent = {
      enable = true;
      group = "media";

      downloadDir = "/srv/media/Downloads";
      configText = ''
        # SOCKS5 proxy via Cloudflare WARP
        network.proxy_address.set = 127.0.0.1:8888

        # Performance tuning
        pieces.memory.max.set = 2048M
        network.max_open_files.set = 600
        network.max_open_sockets.set = 300

        # "slow" throttle: 10 MiB/s upload for seeded torrents
        throttle.up = slow, 10240

        # Ratio handling: seed to 2.0 then throttle (never stop)
        group2.seeding.ratio.min.set = 200
        group2.seeding.ratio.max.set = 300
        group2.seeding.ratio.upload.set = 1M
        method.set = group.seeding.ratio.command, "d.throttle_name.set=slow"
      '';
    };

    # SCGI proxy for Radarr/Sonarr/Prowlarr to reach rTorrent
    caddy.virtualHosts."http://localhost:8000" = {
      extraConfig = ''
        reverse_proxy unix//run/rtorrent/rpc.sock {
          transport scgi
        }
      '';
    };

    flood = {
      enable = true;
      port = 18080;
      host = "::";
      extraArgs = [
        "--rtsocket"
        "/run/rtorrent/rpc.sock"
        "--noauth"
      ];
    };

    radarr = {
      enable = true;
      group = "media";
    };

    sonarr = {
      enable = true;
      group = "media";
    };

    prowlarr = {
      enable = true;
    };

    seerr.enable = true;

    bazarr = {
      enable = true;
      group = "media";
    };

    cross-seed = {
      enable = true;
      group = "media";
      settings = {
        torrentClients = ["rtorrent:http://localhost:8000/RPC2"];
        dataDirs = ["/srv/media/Downloads"];
        linkType = "hardlink";
        linkDirs = ["/srv/media/cross-seed"];
        matchMode = "partial";
        action = "inject";
        duplicateCategories = true;
        searchCadence = "1d";
        excludeRecentSearch = "45d";
        excludeOlder = "180d";
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
        "seerr"
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
          name = "seerr";
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

  my-services.kediTargets = {
    rtorrent = true;
    flood = true;
    radarr = true;
    sonarr = true;
    prowlarr = true;
    bazarr = true;
    seerr = true;
    cross-seed = true;
    flaresolverr = true;
    stacks = true;
  };

  systemd.services = {
    rtorrent = {
      serviceConfig.UMask = "0002";
      serviceConfig.SupplementaryGroups = ["media"];
      partOf = ["kedi.target"];
      unitConfig.ConditionPathIsMountPoint = "/srv";
    };

    flood = {
      serviceConfig.SupplementaryGroups = ["media"];
      path = [pkgs.mediainfo];
      after = ["rtorrent.service"];
      requires = ["rtorrent.service"];
      partOf = ["kedi.target"];
    };

    radarr = {
      serviceConfig.UMask = lib.mkForce "0002";
      serviceConfig.SupplementaryGroups = ["media"];
      after = ["postgresql.service"];
      wants = ["rtorrent.service"];
      partOf = ["kedi.target"];
      unitConfig.ConditionPathIsMountPoint = "/srv";
    };

    sonarr = {
      serviceConfig.UMask = lib.mkForce "0002";
      serviceConfig.SupplementaryGroups = ["media"];
      after = ["postgresql.service"];
      wants = ["postgresql.service"];
      partOf = ["kedi.target"];
      unitConfig.ConditionPathIsMountPoint = "/srv";
    };

    prowlarr = {
      serviceConfig.SupplementaryGroups = ["media"];
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
      partOf = ["kedi.target"];
      unitConfig.ConditionPathIsMountPoint = "/srv";
    };

    bazarr = {
      serviceConfig.UMask = lib.mkForce "0002";
      serviceConfig.SupplementaryGroups = ["media"];
      after = ["radarr.service" "sonarr.service"];
      wants = ["radarr.service" "sonarr.service"];
      partOf = ["kedi.target"];
      unitConfig.ConditionPathIsMountPoint = "/srv";
    };

    seerr = {
      environment = {
        DB_TYPE = "postgres";
        DB_SOCKET_PATH = "/var/run/postgresql";
        DB_USER = "seerr";
        DB_NAME = "seerr";
        HTTP_PROXY = "socks5h://127.0.0.1:8888";
        HTTPS_PROXY = "socks5h://127.0.0.1:8888";
      };
      after = ["postgresql.service"];
      wants = ["postgresql.service"];
      partOf = ["kedi.target"];
      unitConfig.ConditionPathIsMountPoint = "/srv";
    };

    cross-seed = {
      after = [
        "rtorrent.service"
        "prowlarr.service"
      ];
      wants = [
        "rtorrent.service"
        "prowlarr.service"
      ];
      serviceConfig.UMask = "0002";
      serviceConfig.SupplementaryGroups = ["media"];
      partOf = ["kedi.target"];
      unitConfig.ConditionPathIsMountPoint = "/srv";
    };

    flaresolverr.partOf = ["kedi.target"];

    stacks = {
      partOf = ["kedi.target"];
      unitConfig.ConditionPathIsMountPoint = "/srv";
    };

    prometheus-exportarr-radarr-exporter.unitConfig.ConditionPathIsMountPoint = "/srv";
    prometheus-exportarr-sonarr-exporter.unitConfig.ConditionPathIsMountPoint = "/srv";
    prometheus-exportarr-prowlarr-exporter.unitConfig.ConditionPathIsMountPoint = "/srv";
    prometheus-exportarr-radarr-exporter.serviceConfig.SupplementaryGroups = ["media"];
    prometheus-exportarr-sonarr-exporter.serviceConfig.SupplementaryGroups = ["media"];
    prometheus-exportarr-prowlarr-exporter.serviceConfig.SupplementaryGroups = ["media"];
  };

  # Stacks (Anna's Archive download manager) + FlareSolverr
  virtualisation.quadlet = {
    autoEscape = true;
    autoUpdate.enable = true;

    networks.stacks = {};

    volumes = {
      stacks-config = {};
      stacks-logs = {};
      stacks-incomplete = {};
    };

    containers = let
      stacksNetwork = config.virtualisation.quadlet.networks.stacks.ref;
      inherit (config.virtualisation.quadlet) volumes;
    in {
      flaresolverr = {
        containerConfig = {
          name = "flaresolverr";
          image = containerImages.flaresolverr;
          autoUpdate = "registry";
          networks = [stacksNetwork];
          environments = {
            LOG_LEVEL = "info";
            TZ = config.time.timeZone;
          };
        };
        serviceConfig.Restart = "on-failure";
      };

      stacks = {
        containerConfig = {
          name = "stacks";
          image = containerImages.stacks;
          autoUpdate = "registry";
          networks = [stacksNetwork];
          publishPorts = ["7788:7788"];
          volumes = [
            "${volumes.stacks-config.ref}:/opt/stacks/config"
            "/srv/media/Books:/opt/stacks/download"
            "${volumes.stacks-logs.ref}:/opt/stacks/logs"
            "${volumes.stacks-incomplete.ref}:/opt/stacks/incomplete"
          ];
          environments = {
            USERNAME = "admin";
            PASSWORD = "stacks";
            SOLVERR_URL = "http://flaresolverr:8191";
            TZ = config.time.timeZone;
          };
        };
        serviceConfig.Restart = "on-failure";
        unitConfig = {
          RequiresMountsFor = "/srv";
          After = "flaresolverr.service";
          Wants = "flaresolverr.service";
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/media 0775 root media -"
    "d /srv/media/Downloads 0775 root media -"
    "d /srv/media/Movies 0775 root media -"
    "d /srv/media/Shows 0775 root media -"
    "d /srv/media/Books 0775 root media -"
  ];

  vault-secrets.secrets.arr = {
    services = [
      "radarr"
      "sonarr"
      "prowlarr"
      "cross-seed"
      "prometheus-exportarr-radarr-exporter"
      "prometheus-exportarr-sonarr-exporter"
      "prometheus-exportarr-prowlarr-exporter"
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
          "http://localhost:9696/3/api?apikey=''${PROWLARR_API_KEY}",
          "http://localhost:9696/4/api?apikey=''${PROWLARR_API_KEY}"
        ]
      }
      EOF
    '';
  };
}
