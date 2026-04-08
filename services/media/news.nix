{
  config,
  containerImages,
  ...
}: let
  vs = config.vault-secrets.secrets;
in {
  imports = [
    ../gcloud-oauth.nix
    ../monitoring/postgres.nix
  ];

  services.miniflux = {
    enable = true;
    adminCredentialsFile = "${vs.miniflux}/admin_creds";
    config = {
      LISTEN_ADDR = "[::]:8088";
      BASE_URL = "https://miniflux.kedi.dev";
      FETCH_YOUTUBE_WATCH_TIME = "1";
      METRICS_COLLECTOR = "1";
      DISABLE_LOCAL_AUTH = "1";
      OAUTH2_USER_CREATION = "1";
      OAUTH2_CLIENT_ID_FILE = "${vs.gcloud-oauth}/client_id";
      OAUTH2_CLIENT_SECRET_FILE = "${vs.gcloud-oauth}/client_secret";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://accounts.google.com";
      OAUTH2_PROVIDER = "google";
      OAUTH2_REDIRECT_URL = "https://miniflux.kedi.dev/oauth2/oidc/callback";
    };
  };

  my-services.kediTargets.miniflux = true;

  systemd.services = {
    miniflux = {
      partOf = ["kedi.target"];
      serviceConfig.SupplementaryGroups = ["news"];
    };
    miniflux-secrets.serviceConfig.UMask = "0027";
    wallabag = {
      partOf = ["kedi.target"];
      serviceConfig.SupplementaryGroups = ["news"];
    };
    wallabag-secrets.serviceConfig.UMask = "0027";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes;
  in {
    autoEscape = true;
    autoUpdate.enable = true;

    volumes = {
      wallabag-data = {};
      wallabag-images = {};
    };

    containers.wallabag.containerConfig = {
      name = "wallabag";
      image = containerImages.wallabag;
      volumes = [
        "${volumes.wallabag-data.ref}:/var/www/wallabag/data"
        "${volumes.wallabag-images.ref}:/var/www/wallabag/web/assets/images"
      ];
      publishPorts = ["8085:80"];
      environmentFiles = ["${vs.wallabag}/environment"];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      8085 # wallabag
      8088 # miniflux
    ];
    interfaces.podman0.allowedTCPPorts = [
      5432 # postgres
    ];
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      host wallabag wallabag 10.0.0.0/8 md5
    '';
    ensureDatabases = [
      "wallabag"
    ];
    ensureUsers = [
      {
        name = "wallabag";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  vault-secrets.secrets.miniflux = {
    services = ["miniflux"];
    secretsKey = null;
    group = "news";
    extraScript = ''
      umask 0027
      printf '%s' "$MINIFLUX_ADMIN_CREDS" > "$secretsPath/admin_creds"
    '';
  };

  vault-secrets.secrets.wallabag = {
    services = ["wallabag"];
    group = "news";
  };

  users.groups.news = {};

  my-services.kediTargets.wallabag = true;
}
