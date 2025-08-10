{
  lib,
  config,
  pkgs,
  copyparty,
  ...
}:

{
  #
  # Copyparty
  #
  imports = [
    copyparty.nixosModules.default
  ];

  services = {
    copyparty = {
      enable = true;
      settings = {
        name = "Copyparty";
        ansi = true;

        #network
        i = "unix:777:/dev/shm/party.sock";

        # ssl/tls
        http-only = true;

        # idp
        idp-h-usr = "X-Tailscale-User-LoginName";
        idp-adm = "antsub@gmail.com";

        # zeroconf
        z = true;
        z-on = [
          "enp2s0"
          "enp4s0"
        ];

        # upload
        chmod-f = "664";
        chmod-d = "775";
        df = "10"; # reject uploads if we have less than 10GiB free
        nosubtle = "137"; # enable wasm hasher on chrome > 137

        # general db
        e2dsa = true;
        e2ts = true;
      };
      volumes = {
        "/" = {
          path = "/srv/drive/public";
          access = {
            rw = "*";
            A = "antsub@gmail.com";
          };
        };
        "/media" = {
          path = "/srv/media";
          access = {
            r = "*";
          };
        };
        "/ananth" = {
          path = "/srv/drive/ananth";
          access = {
            A = "antsub@gmail.com";
          };
        };
        "/arul" = {
          path = "/srv/drive/arul";
          access = {
            A = "arulpriya93@gmail.com";
          };
        };
        "/bhaskar" = {
          path = "/srv/drive/bhaskar";
          access = {
            A = "bhaskar.yampet@gmail.com";
          };
        };
        "/anu" = {
          path = "/srv/drive/anu";
          access = {
            A = "anu.bhsrmn@gmail.com";
          };
        };
      };
    };

    tsnsrv.services.cp = {
      urlParts.port = 3923; # ignored
      upstreamUnixAddr = "/dev/shm/party.sock";
    };
  };

  systemd.services.tsnsrv-cp.wants = [ "copyparty.service" ];
  systemd.services.tsnsrv-cp.after = [ "copyparty.service" ];
  systemd.services.tsnsrv-cp.serviceConfig.BindPaths = "/dev/shm";

  systemd.services.copyparty.serviceConfig.BindPaths = "/srv/drive";
  systemd.services.copyparty.serviceConfig.Group = lib.mkForce "media";
  systemd.services.copyparty.serviceConfig.UMask = lib.mkForce "0007";
  systemd.services.copyparty.unitConfig.requiresmountsfor = "/srv";

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
    copyparty.overlays.default

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
  # Jellyseer
  #
  services = {
    jellyseerr.enable = true;

    tsnsrv.services.see = {
      funnel = true;
      urlParts.port = 5055;
    };
  };

  systemd.services.tsnsrv-see.wants = [ "jellyseer.service" ];
  systemd.services.tsnsrv-see.after = [ "jellyseer.service" ];

  #
  # Secrets
  #
  sops.secrets = {
    "tsnsrv/nodes/copyparty" = { };
    "tsnsrv/nodes/jellyfin" = { };
    "tsnsrv/nodes/jellyseerr" = { };
    "tsnsrv/nodes/immich" = { };
    "email/smtp/username" = { };
    "email/smtp/password" = { };
    "email/smtp/host" = { };
    "email/from/immich" = { };
    "email/replyTo/immich" = { };
    "keys/oauth_clients/immich/client_id".owner = config.users.users.immich.name;
    "keys/oauth_clients/immich/client_secret".owner = config.users.users.immich.name;
    "keys/oauth_clients/immich/issuer_url".owner = config.users.users.immich.name;
    "keys/oauth_clients/immich/redirect_uris/mobile".owner = config.users.users.immich.name;
    "keys/oauth_clients/immich/redirect_uris/web".owner = config.users.users.immich.name;
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
          "issuerUrl": "${config.sops.placeholder."keys/oauth_clients/immich/issuer_url"}",
          "mobileOverrideEnabled": true,
          "mobileRedirectUri": "${
            config.sops.placeholder."keys/oauth_clients/immich/redirect_uris/mobile"
          }",
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
          "deleteDelay": 1
        }
      }
    '';
  };

}
