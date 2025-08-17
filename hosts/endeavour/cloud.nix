{
  config,
  pkgs,
  ...
}:

{
  #
  # Seafile
  #
  services.seafile = {
    enable = true;
    dataDir = "/srv/seafile";
    adminEmail = "antsub@gmail.com";
    initialAdminPassword = "change me later";

    ccnetSettings.General.SERVICE_URL = "https://sf.tail42937.ts.net";

    seahubExtraConf = ''
      import os

      ENABLE_SETTINGS_VIA_WEB = False
      TIME_ZONE = "Asia/Kolkata"
      SITE_NAME = "Ananth's File Server"
      SITE_TITLE = "Our Cloud"

      fqdn = os.environ.get("SEAFILE_FQDN")

      # Security Settings
      # Please refer https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts for details.
      ALLOWED_HOSTS = [f".{fqdn}"]


      # Whether to use a secure cookie for the CSRF cookie
      # https://docs.djangoproject.com/en/3.2/ref/settings/#csrf-cookie-secure
      CSRF_COOKIE_SECURE = True

      # The value of the SameSite flag on the CSRF cookie
      # https://docs.djangoproject.com/en/3.2/ref/settings/#csrf-cookie-samesite
      CSRF_COOKIE_SAMESITE = 'Strict'

      # https://docs.djangoproject.com/en/3.2/ref/settings/#csrf-trusted-origins
      CSRF_TRUSTED_ORIGINS = [f"https://{fqdn}"]


      # OAuth Settings
      ENABLE_OAUTH = True
      OAUTH_ENABLE_INSECURE_TRANSPORT = True

      OAUTH_CLIENT_ID = os.environ.get("OAUTH_CLIENT_ID")
      OAUTH_CLIENT_SECRET = os.environ.get("OAUTH_CLIENT_SECRET")
      OAUTH_REDIRECT_URL = f"https://{fqdn}/oauth/callback/"

      # The following shoud NOT be changed if you are using Google as OAuth provider.
      OAUTH_PROVIDER_DOMAIN = 'google.com'
      OAUTH_AUTHORIZATION_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
      OAUTH_TOKEN_URL = 'https://www.googleapis.com/oauth2/v4/token'
      OAUTH_USER_INFO_URL = 'https://www.googleapis.com/oauth2/v1/userinfo'
      OAUTH_SCOPE = [
          "openid",
          "https://www.googleapis.com/auth/userinfo.email",
          "https://www.googleapis.com/auth/userinfo.profile",
      ]
      OAUTH_ATTRIBUTE_MAP = {
          "id": (True, "uid"),
          "name": (False, "name"),
          "email": (False, "contact_email"),
      }


      # SMTP Settings
      EMAIL_USE_TLS = True
      EMAIL_HOST = os.environ.get("EMAIL_HOST")
      EMAIL_HOST_USER = os.environ.get("EMAIL_HOST_USER")
      EMAIL_HOST_PASSWORD = os.environ.get("EMAIL_HOST_PASSWORD")
      EMAIL_PORT = os.environ.get("EMAIL_PORT")
      DEFAULT_FROM_EMAIL = os.environ.get("SEAFILE_EMAIL")
      SERVER_EMAIL = os.environ.get("SEAFILE_EMAIL")
    '';

    seafileSettings = {
      history.keep_days = "14"; # Remove deleted files after 14 days
      fileserver = {
        host = "unix:/run/seafile/server.sock";
      };
    };

    # Enable weekly collection of freed blocks
    gc = {
      enable = true;
      dates = [ "Sun 03:00:00" ];
    };
  };

  services.caddy.enable = true;
  services.caddy.globalConfig = ''
    auto_https off

    servers {
      trusted_proxies static ::1
    }
  '';
  services.caddy.virtualHosts.":8383" = {
    extraConfig = ''
      handle_path /seafhttp* {
        uri strip_prefix /seafhttp

        reverse_proxy unix//run/seafile/server.sock {
          transport http {
            dial_timeout 36000s
            read_timeout 36000s
            write_timeout 36000s
          }
        }
      }

      handle {
        reverse_proxy unix//run/seahub/gunicorn.sock {
          transport http {
            read_timeout 1200s
          }
        }
      }
    '';
  };

  systemd.targets.seafile.wants = [ "tsnsrv-sf.service" ];
  systemd.services.seahub.serviceConfig.EnvironmentFile =
    config.sops.templates."seafile/seahub_settings.env".path;

  sops.secrets = {
    "keys/oauth_clients/seafile/client_id" = { };
    "keys/oauth_clients/seafile/client_secret" = { };
    "email/from/seafile" = { };
  };
  sops.templates."seafile/seahub_settings.env" = {
    owner = config.users.users.seafile.name;
    content = ''
      SEAFILE_FQDN="sf.${config.sops.placeholder."keys/tailscale_api/tailnet"}"
      OAUTH_CLIENT_ID="${config.sops.placeholder."keys/oauth_clients/seafile/client_id"}"
      OAUTH_CLIENT_SECRET="${config.sops.placeholder."keys/oauth_clients/seafile/client_secret"}"
      EMAIL_HOST="${config.sops.placeholder."email/smtp/host"}"
      EMAIL_PORT="587"
      EMAIL_HOST_USER="${config.sops.placeholder."email/smtp/username"}"
      EMAIL_HOST_PASSWORD="${config.sops.placeholder."email/smtp/password"}"
      SEAFILE_EMAIL="${config.sops.placeholder."email/from/seafile"}"
    '';
  };

  services.tsnsrv.services.sf = {
    urlParts.port = 8383;
  };
  systemd.services.tsnsrv-sf.wants = [
    "seaf-server.service"
    "seaf-http.service"
    "seahub.service"
  ];
  systemd.services.tsnsrv-sf.after = [
    "seaf-server.service"
    "seaf-http.service"
    "seahub.service"
  ];

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
