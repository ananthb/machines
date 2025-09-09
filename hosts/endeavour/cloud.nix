{
  config,
  pkgs,
  ...
}:

{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks pods volumes;
    in
    {
      autoEscape = true;
      autoUpdate.enable = true;

      networks = {
        seafile = { };
      };

      volumes = {
        seafile-mysql-data = { };
        seafile-caddy-data = { };
      };

      pods = {
        seafile.podConfig = {
          networks = [
            networks.seafile.ref
          ];
          volumes = [
            "/srv/seafile/seafile-data:/shared"
            "${config.sops.templates."seafile/Caddyfile".path}:/etc/caddy/Caddyfile"
            "${volumes.seafile-mysql-data.ref}:/var/lib/mysql"
          ];
          publishPorts = [ "4000:4000" ];
        };
      };

      containers = {
        seafile-caddy.containerConfig = {
          name = "seafile-caddy";
          image = "docker.io/library/caddy:2";
          pod = pods.seafile.ref;
        };

        seafile-mysql.containerConfig = {
          name = "seafile-mysql";
          image = "docker.io/library/mariadb:10.11";
          pod = pods.seafile.ref;
          environments = {
            MYSQL_LOG_CONSOLE = "true";
            MARIADB_AUTO_UPGRADE = "1";
            MYSQL_ROOT_PASSWORD = "password";
          };
        };

        seafile-redis.containerConfig = {
          name = "seafile-redis";
          image = "docker.io/library/redis";
          pod = pods.seafile.ref;
        };

        seafile-server.containerConfig = {
          name = "seafile";
          image = "docker.io/seafileltd/seafile-mc:13.0-latest";
          pod = pods.seafile.ref;
          environmentFiles = [ config.sops.templates."seafile/seafile.env".path ];
          environments = {
            TIME_ZONE = "Asia/Kolkata";
            INIT_SEAFILE_ADMIN_EMAIL = "admin@example.com";
            INIT_SEAFILE_ADMIN_PASSWORD = "change me soon";
            SEAFILE_SERVER_PROTOCOL = "https";
            SITE_ROOT = "/";
            NON_ROOT = "false";
            SEAFILE_LOG_TO_STDOUT = "true";

            ENABLE_SEADOC = "true";

            SEAFILE_MYSQL_DB_HOST = "127.0.0.1";
            SEAFILE_MYSQL_DB_PORT = "3306";
            SEAFILE_MYSQL_DB_USER = "root";
            SEAFILE_MYSQL_DB_PASSWORD = "password";
            INIT_SEAFILE_MYSQL_ROOT_PASSWORD = "password";
            SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
            SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
            SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";

            CACHE_PROVIDER = "redis";
            REDIS_HOST = "127.0.0.1";
            REDIS_PORT = "6379";

            ENABLE_NOTIFICATION_SERVER = "false";
            INNER_NOTIFICATION_SERVER_URL = "http://127.0.0.1:8083";
            ENABLE_SEAFILE_AI = "false";
            SEAFILE_AI_SERVER_URL = "http://seafile-ai:8888";
            SEAFILE_AI_SECRET_KEY = "key";
            MD_FILE_COUNT_LIMIT = "100000";
          };
        };

        seadoc.containerConfig = {
          name = "seadoc";
          image = "docker.io/seafileltd/sdoc-server:2.0-latest";
          volumes = [
            "/srv/seafile/seadoc:/shared"
          ];
          networks = [
            networks.seafile.ref
          ];
          environmentFiles = [ config.sops.templates."seafile/seadoc.env".path ];
          environments = {
            DB_HOST = "seafile-mysql";
            DB_PORT = "3306";
            DB_USER = "root";
            DB_PASSWORD = "password";
            DB_NAME = "seadoc_db";
            TIME_ZONE = "Asia/Kolkata";
            NON_ROOT = "false";
            SEAHUB_SERVICE_URL = "http://seafile:4000";
          };
        };
      };
    };

  services.tsnsrv.services = {
    sf = {
      funnel = true;
      urlParts.host = "127.0.0.1";
      urlParts.port = 4000;
    };
  };

  sops.templates."seafile/Caddyfile" = {
    content = ''
      :4000 {
        header Access-Control-Allow-Origin

        handle_path /seafhttp* {
          reverse_proxy 127.0.0.1:8082
        }

        handle_path /notification* {
          reverse_proxy 127.0.0.1:8083
        }

        redir /seafdav /seafdav/ permanent
        reverse_proxy /seafdav/* 127.0.0.1:8080

        reverse_proxy /media* 127.0.0.1:80 {
          header_down -Access-Control-Allow-Origin
        }

        reverse_proxy /sdoc-server/* seadoc:7070 {
          header_down Access-Control-Allow-Origin "https://sf.${
            config.sops.placeholder."keys/tailscale_api/tailnet"
          }"
        }
        reverse_proxy /socket.io seadoc:7070 {
          header_down Access-Control-Allow-Origin "https://sf.${
            config.sops.placeholder."keys/tailscale_api/tailnet"
          }"
        }

        reverse_proxy 127.0.0.1:8000
      }
    '';
  };

  sops.templates."seafile/seafile.env" = {
    content = ''
      JWT_PRIVATE_KEY=${config.sops.placeholder."keys/seafile/jwt_private_key"}
      SEAFILE_SERVER_HOSTNAME=sf.${config.sops.placeholder."keys/tailscale_api/tailnet"}
      SEAFILE_SERVER_PROTOCOL=https
      SEADOC_SERVER_URL=https://sf.${config.sops.placeholder."keys/tailscale_api/tailnet"}/sdoc-server
      NOTIFICATION_SERVER_URL=https://sf.${
        config.sops.placeholder."keys/tailscale_api/tailnet"
      }/notification
    '';
  };

  sops.templates."seafile/seadoc.env" = {
    content = ''
      JWT_PRIVATE_KEY=${config.sops.placeholder."keys/seafile/jwt_private_key"}
      SEAFILE_SERVER_HOSTNAME=sf.${config.sops.placeholder."keys/tailscale_api/tailnet"}
      SEAFILE_SERVER_PROTOCOL=https
    '';
  };

  sops.secrets."keys/seafile/jwt_private_key" = { };

  #
  # Immich
  #
  services = {
    immich = {
      enable = true;
      environment = {
        "IMMICH_CONFIG_FILE" = config.sops.templates."immich/config.json".path;
      };
      mediaLocation = "/srv/immich";
    };

    tsnsrv.services.imm = {
      funnel = true;
      urlParts.port = 2283;
    };
  };

  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  systemd.services.immich-server.environment = {
    IMMICH_TELEMETRY_INCLUDE = "all";
  };
  systemd.services.immich.unitConfig.requiresmountsfor = "/srv";

  systemd.services.tsnsrv-imm.wants = [ "immich-server.service" ];
  systemd.services.tsnsrv-imm.after = [ "immich-server.service" ];

  sops.secrets = {
    "email/from/immich" = { };
    "keys/oauth_clients/immich/client_id".owner = config.users.users.immich.name;
    "keys/oauth_clients/immich/client_secret".owner = config.users.users.immich.name;
  };

  sops.templates."immich/config.json" = {
    owner = config.users.users.immich.name;
    content = ''
      {
        "ffmpeg": {
          "crf": 23,
          "threads": 0,
          "preset": "ultrafast",
          "targetVideoCodec": "h264",
          "acceptedVideoCodecs": ["h264"],
          "targetAudioCodec": "aac",
          "acceptedAudioCodecs": ["aac", "mp3", "libopus", "pcm_s16le"],
          "acceptedContainers": ["mov", "ogg", "webm"],
          "targetResolution": "720",
          "maxBitrate": "0",
          "bframes": -1,
          "refs": 0,
          "gopSize": 0,
          "temporalAQ": false,
          "cqMode": "auto",
          "twoPass": false,
          "preferredHwDevice": "auto",
          "transcode": "required",
          "tonemap": "hable",
          "accel": "disabled",
          "accelDecode": false
        },
        "backup": {
          "database": {
            "enabled": true,
            "cronExpression": "0 02 * * *",
            "keepLastAmount": 14
          }
        },
        "job": {
          "backgroundTask": {
            "concurrency": 2
          },
          "smartSearch": {
            "concurrency": 1
          },
          "metadataExtraction": {
            "concurrency": 2
          },
          "faceDetection": {
            "concurrency": 1
          },
          "search": {
            "concurrency": 4
          },
          "sidecar": {
            "concurrency": 4
          },
          "library": {
            "concurrency": 4
          },
          "migration": {
            "concurrency": 4
          },
          "thumbnailGeneration": {
            "concurrency": 4
          },
          "videoConversion": {
            "concurrency": 1
          },
          "notifications": {
            "concurrency": 4
          }
        },
        "logging": {
          "enabled": true,
          "level": "log"
        },
        "machineLearning": {
          "enabled": true,
          "urls": ["http://localhost:3003"],
          "clip": {
            "enabled": true,
            "modelName": "ViT-B-32__openai"
          },
          "duplicateDetection": {
            "enabled": true,
            "maxDistance": 0.01
          },
          "facialRecognition": {
            "enabled": true,
            "modelName": "buffalo_l",
            "minScore": 0.7,
            "maxDistance": 0.5,
            "minFaces": 3
          }
        },
        "map": {
          "enabled": true,
          "lightStyle": "https://tiles.immich.cloud/v1/style/light.json",
          "darkStyle": "https://tiles.immich.cloud/v1/style/dark.json"
        },
        "reverseGeocoding": {
          "enabled": true
        },
        "metadata": {
          "faces": {
            "import": true
          }
        },
        "oauth": {
          "autoLaunch": false,
          "autoRegister": false,
          "buttonText": "Sign in with Google",
          "clientId": "${config.sops.placeholder."keys/oauth_clients/immich/client_id"}",
          "clientSecret": "${config.sops.placeholder."keys/oauth_clients/immich/client_secret"}",
          "defaultStorageQuota": null,
          "enabled": true,
          "issuerUrl": "https://accounts.google.com/.well-known/openid-configuration",
          "mobileOverrideEnabled": true,
          "mobileRedirectUri": "https://imm.${
            config.sops.placeholder."keys/tailscale_api/tailnet"
          }/api/oauth/mobile-redirect",
          "scope": "openid email profile",
          "signingAlgorithm": "RS256",
          "profileSigningAlgorithm": "none",
          "storageLabelClaim": "preferred_username",
          "storageQuotaClaim": "immich_quota"
        },
        "passwordLogin": {
          "enabled": false
        },
        "storageTemplate": {
          "enabled": false,
          "hashVerificationEnabled": true,
          "template": "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}"
        },
        "image": {
          "thumbnail": {
            "format": "webp",
            "size": 250,
            "quality": 80
          },
          "preview": {
            "format": "jpeg",
            "size": 1440,
            "quality": 80
          },
          "colorspace": "p3",
          "extractEmbedded": true
        },
        "newVersionCheck": {
          "enabled": false
        },
        "trash": {
          "enabled": true,
          "days": 30
        },
        "theme": {
          "customCss": ""
        },
        "library": {
          "scan": {
            "enabled": true,
            "cronExpression": "0 0 * * *"
          },
          "watch": {
            "enabled": false
          }
        },
        "server": {
          "externalDomain": "https://imm.${config.sops.placeholder."keys/tailscale_api/tailnet"}",
          "loginPageMessage": ""
        },
        "notifications": {
          "smtp": {
            "enabled": false,
            "from": "${config.sops.placeholder."email/from/immich"}",
            "replyTo": "${config.sops.placeholder."email/from/immich"}",
            "transport": {
              "ignoreCert": false,
              "host": "${config.sops.placeholder."email/smtp/host"}",
              "port": 587,
              "username": "${config.sops.placeholder."email/smtp/username"}",
              "password": "${config.sops.placeholder."email/smtp/password"}"}
          }
        },
        "user": {
          "deleteDelay": 7
        }
      }
    '';
  };

  #
  # Jellyfin
  #
  services = {
    jellyfin.enable = true;
    jellyfin.group = "media";
    jellyfin.openFirewall = true;

    meilisearch.enable = true;
    meilisearch.package = pkgs.meilisearch;

    tsnsrv.services.tv = {
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

  #
  # Open WebUI
  #
  services.open-webui = {
    enable = true;
    package = pkgs.open-webui.overrideAttrs (old: {
      propagatedBuildInputs =
        old.propagatedBuildInputs
        ++ (with pkgs.python3Packages; [
          # Socks Proxy
          pysocks
          socksio
          httpx
          httpx-socks

          # Youtube transcription plugin
          yt-dlp
        ]);
    });
    port = 8090;
    environmentFile = config.sops.templates."open-webui/env".path;
  };

  sops.secrets = {
    "keys/oauth_clients/open-webui/client_id" = { };
    "keys/oauth_clients/open-webui/client_secret" = { };
    "keys/google_pse_api/id" = { };
    "keys/google_pse_api/key" = { };
  };

  sops.templates."open-webui/env" = {
    mode = "0444";
    content = ''
      # general
      http_proxy="socks5://localhost:8888"
      https_proxy="socks5://localhost:8888"
      no_proxy=".${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      ENV="prod"
      WEBUI_URL="https://ai.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      DATABASE_URL="postgresql://open-webui@/open-webui?host=/run/postgresql"
      ENABLE_PERSISTENT_CONFIG="False"
      BYPASS_MODEL_ACCESS_CONTROL="True"

      # ollama api
      ENABLE_OLLAMA_API
      OLLAMA_BASE_URLS="http://enterprise.${
        config.sops.placeholder."keys/tailscale_api/tailnet"
      }:11434;http://discovery.${config.sops.placeholder."keys/tailscale_api/tailnet"}:11434"
      EMABLE_OPENAI_API="False"

      # auth
      ENABLE_LOGIN_FORM="False"
      ENABLE_OAUTH_PERSISTENT_CONFIG="False"
      ENABLE_SIGNUP="True"
      ENABLE_OAUTH_SIGNUP="True"
      OAUTH_UPDATE_PICTURE_ON_LOGIN="True"

      # Google OpenID
      GOOGLE_CLIENT_ID="${config.sops.placeholder."keys/oauth_clients/open-webui/client_id"}"
      GOOGLE_CLIENT_SECRET="${config.sops.placeholder."keys/oauth_clients/open-webui/client_secret"}"
      GOOGLE_REDIRECT_URI="https://ai.${
        config.sops.placeholder."keys/tailscale_api/tailnet"
      }/oauth/google/callback"
      OPENID_PROVIDER_URL="https://accounts.google.com/.well-known/openid-configuration"

      # See http://github.com/open-webui/open-webui/discussions/10571
      HF_ENDPOINT=https://hf-mirror.com/ 

      # See https://github.com/nixos/nixpkgs/issues/430433
      FRONTEND_BUILD_DIR="${config.services.open-webui.stateDir}/build";
      DATA_DIR="${config.services.open-webui.stateDir}/data";
      STATIC_DIR="${config.services.open-webui.stateDir}/static";

      # web search
      ENABLE_WEB_SEARCH="True"
      WEB_SEARCH_TRUST_ENV="True"
      WEB_SEARCH_ENGINE="google_pse"
      GOOGLE_PSE_ENGINE_ID="${config.sops.placeholder."keys/google_pse_api/id"}"
      GOOGLE_PSE_API_KEY="${config.sops.placeholder."keys/google_pse_api/key"}"

      # RAG
      PDF_EXTRACT_IMAGES="True"
    '';
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "open-webui" ];
    ensureUsers = [
      {
        name = "open-webui";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  services.tsnsrv.services.ai = {
    funnel = true;
    urlParts.host = "127.0.0.1";
    urlParts.port = 8090;
  };

}
