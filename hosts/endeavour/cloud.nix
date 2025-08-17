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
      pods = {
        seafile-server = {
          networks = [ "podman" ];
        };
      };
      volumes = {
        seafile-server-mysql-data.volumeConfig = {
          type = "bind";
        };
        seafile-data.volumeConfig = {
          type = "bind";
        };
      };
      containers = {
        db = {
          containerConfig = {
            name = "seafile-mysql";
            image = "docker.io/library/mariadb:10.11";
            pod = pods.seafile-server.ref;
            environments = {
              MYSQL_LOG_CONSOLE = true;
              MARIADB_AUTO_UPGRADE = 1;
              MYSQL_ROOT_PASSWORD = "password";
            };
            volumes = [
              "${volumes.seafile-server-mysql-data.ref}:/var/lib/mysql"
            ];
          };
        };
        redis.containerConfig = {
          name = "seafile-redis";
          image = "docker.io/library/redis";
        };
        seafile = {
          containerConfig = {
            name = "seafile";
            image = "docker.io/seafileltd/seafile-mc:13.0-latest";
            volumes = [
              "${volumes.seafile-data.ref}:/shared"
            ];
            environments = {
              SEAFILE_MYSQL_DB_HOST = "127.0.0.1";
              SEAFILE_MYSQL_DB_PORT = 3306;
              SEAFILE_MYSQL_DB_USER = "seafile";
              SEAFILE_MYSQL_DB_PASSWORD = "password";
              INIT_SEAFILE_MYSQL_ROOT_PASSWORD = "password";
              SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
              SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
              SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";
              TIME_ZONE = "Asia/Kolkata";
              INIT_SEAFILE_ADMIN_EMAIL = "antsub@gmail.com";
              INIT_SEAFILE_ADMIN_PASSWORD = "change me soon";
              SEAFILE_SERVER_HOSTNAME = "https://sf.tail42937.ts.net";
              SEAFILE_SERVER_PROTOCOL = "http";
              SITE_ROOT = "/";
              NON_ROOT = false;
              JWT_PRIVATE_KEY = "some-key";
              SEAFILE_LOG_TO_STDOUT = false;
              ENABLE_SEADOC = true;
              SEADOC_SERVER_URL = "${SEAFILE_SERVER_PROTOCOL}://${SEAFILE_SERVER_HOSTNAME}/sdoc-server";
              CACHE_PROVIDER = "redis";
              REDIS_HOST = "127.0.0.1";
              REDIS_PORT = 6379;
              ENABLE_NOTIFICATION_SERVER = false;
              INNER_NOTIFICATIN_SERVER_URL = "http://notification-server:8083";
              NOTIFICATION_SERVER_URL = "${SEAFILE_SERVER_PROTOCOL}://${SEAFILE_SERVER_HOSTNAME}/notification";
              ENABLE_SEAFILE_AI = false;
              SEAFILE_AI_SERVER_URL = "http://seafile-ai:8888";
              SEAFILE_AI_SECRET_KEY = "key";
              MD_FILE_COUNT_LIMIT = 100000;
            };
          };
        };
      };
    };

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

}
