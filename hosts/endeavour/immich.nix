{
  config,
  pkgs-unstable,
  ...
}:
{
  services = {
    immich = {
      enable = true;
      host = "::";
      openFirewall = true;
      package = pkgs-unstable.immich;
      environment = {
        "IMMICH_CONFIG_FILE" = config.sops.templates."immich/config.json".path;
      };
      mediaLocation = "/srv/immich";
      accelerationDevices = [ "/dev/dri/renderD128" ];
      machine-learning.enable = false;
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

  systemd.services.immich-server = {
    environment.IMMICH_TELEMETRY_INCLUDE = "all";
    unitConfig.RequiresMountsFor = "/srv";
  };

  systemd.services.tsnsrv-imm.wants = [ "immich-server.service" ];
  systemd.services.tsnsrv-imm.after = [ "immich-server.service" ];

  systemd.services."immich-backup" = {
    # TODO: re-enable after we've trimmed down unnecessary files
    # startAt = "weekly";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${config.my-scripts.kopia-snapshot-backup} /srv/immich";
    };
  };

  sops.secrets = {
    "email/from/immich" = { };
    "gcloud/oauth_self-hosted_clients/id".owner = config.users.users.immich.name;
    "gcloud/oauth_self-hosted_clients/secret".owner = config.users.users.immich.name;
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
          "accel": "qsv",
          "accelDecode": true
        },
        "backup": {
          "database": {
            "enabled": true,
            "cronExpression": "50 * * * *",
            "keepLastAmount": 3
          }
        },
        "job": {
          "backgroundTask": {
            "concurrency": 1
          },
          "smartSearch": {
            "concurrency": 4
          },
          "metadataExtraction": {
            "concurrency": 1
          },
          "faceDetection": {
            "concurrency": 4
          },
          "search": {
            "concurrency": 1
          },
          "sidecar": {
            "concurrency": 1
          },
          "library": {
            "concurrency": 1
          },
          "migration": {
            "concurrency": 1
          },
          "thumbnailGeneration": {
            "concurrency": 1
          },
          "videoConversion": {
            "concurrency": 1
          },
          "notifications": {
            "concurrency": 1
          }
        },
        "logging": {
          "enabled": true,
          "level": "log"
        },
        "machineLearning": {
          "enabled": true,
          "urls": ["http://enterprise:3003"],
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
            "minFaces": 20
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
          "clientId": "${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}",
          "clientSecret": "${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}",
          "defaultStorageQuota": null,
          "enabled": true,
          "issuerUrl": "https://accounts.google.com/.well-known/openid-configuration",
          "mobileOverrideEnabled": true,
          "mobileRedirectUri": "https://imm.${
            config.sops.placeholder."tailscale_api/tailnet"
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
          "externalDomain": "https://imm.${config.sops.placeholder."tailscale_api/tailnet"}",
          "loginPageMessage": "Welcome to Ananth's Immich server",
          "publicUsers": true
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

}
