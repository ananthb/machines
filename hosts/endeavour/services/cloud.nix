{ config, pkgs, ... }:

{
  services = {
    immich = {
      enable = true;
      environment = {
        "IMMICH_CONFIG_FILE" = config.sops.templates."immich/config.json".path;
      };
    };

    jellyfin.enable = true;
    jellyfin.group = "media";
    jellyfin.openFirewall = true;

    meilisearch.enable = true;
    meilisearch.package = pkgs.meilisearch;

    jellyseerr = {
      enable = true;
    };

    tsnsrv.services.imm = {
      funnel = true;
      urlParts.port = 2283;
      extraArgs = [
        "-prometheusAddr=[::1]:9097"
      ];
    };

    tsnsrv.services.tv = {
      funnel = true;
      urlParts.port = 8096;
      extraArgs = [
        "-prometheusAddr=[::1]:9096"
      ];
    };

    tsnsrv.services.see = {
      funnel = true;
      urlParts.port = 5055;
      extraArgs = [
        "-prometheusAddr=[::1]:9095"
      ];
    };
  };

  sops.secrets."tsnsrv/nodes/jellyfin" = { };
  sops.secrets."tsnsrv/nodes/jellyseerr" = { };
  sops.secrets."tsnsrv/nodes/immich" = { };
  sops.secrets."email/from/immich" = { };
  sops.secrets."email/replyTo/immich" = { };
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
            "concurrency": 5
          },
          "smartSearch": {
            "concurrency": 2
          },
          "metadataExtraction": {
            "concurrency": 5
          },
          "faceDetection": {
            "concurrency": 2
          },
          "search": {
            "concurrency": 5
          },
          "sidecar": {
            "concurrency": 5
          },
          "library": {
            "concurrency": 5
          },
          "migration": {
            "concurrency": 5
          },
          "thumbnailGeneration": {
            "concurrency": 3
          },
          "videoConversion": {
            "concurrency": 1
          },
          "notifications": {
            "concurrency": 5
          }
        },
        "logging": {
          "enabled": true,
          "level": "log"
        },
        "machineLearning": {
          "enabled": true,
          "urls": ["http://immich-machine-learning:3003"],
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
            "import": false
          }
        },
        "oauth": {
          "autoLaunch": true,
          "autoRegister": false,
          "buttonText": "Sign in with Google",
          "clientId": "${config.sops.placeholder."oauth_clients/immich/client_id"}",
          "clientSecret": "${config.sops.placeholder."oauth_clients/immich/client_secret"}",
          "defaultStorageQuota": null,
          "enabled": false,
          "issuerUrl": "${config.sops.placeholder."oauth_clients/immich/issuer_url"}",
          "mobileOverrideEnabled": true,
          "mobileRedirectUri": "${config.sops.placeholder."oauth_clients/immich/redirect_uris/mobile"}",
          "scope": "openid email profile",
          "signingAlgorithm": "RS256",
          "profileSigningAlgorithm": "none",
          "storageLabelClaim": "preferred_username",
          "storageQuotaClaim": "immich_quota"
        },
        "passwordLogin": {
          "enabled": true
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
          "extractEmbedded": false
        },
        "newVersionCheck": {
          "enabled": true
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
          "externalDomain": "https://${config.sops.placeholder."tsnsrv/nodes/immich"}.${
            config.sops.placeholder."tsnsrv/tailnet"
          }",
          "loginPageMessage": ""
        },
        "notifications": {
          "smtp": {
            "enabled": false,
            "from": "${config.sops.placeholder."email/from/immich"}",
            "replyTo": "${config.sops.placeholder."email/replyTo/immich"}",
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

  sops.secrets = {
    "oauth_clients/immich/client_id".owner = config.users.users.immich.name;
    "oauth_clients/immich/client_secret".owner = config.users.users.immich.name;
    "oauth_clients/immich/issuer_url".owner = config.users.users.immich.name;
    "oauth_clients/immich/redirect_uris/mobile".owner = config.users.users.immich.name;
    "oauth_clients/immich/redirect_uris/web".owner = config.users.users.immich.name;
  };
}
