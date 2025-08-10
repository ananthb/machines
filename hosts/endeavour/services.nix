{
  config,
  pkgs,
  ...
}:

{
  services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = false;

  services.prometheus.exporters = {
    postgres.enable = true;

    redis.enable = true;

    exportarr-radarr = {
      enable = true;
      url = "http://localhost:7878";
      port = 9708;
      apiKeyFile = config.sops.secrets."keys/arr_apis/radarr".path;
    };

    exportarr-sonarr = {
      enable = true;
      url = "http://localhost:8989";
      port = 9709;
      apiKeyFile = config.sops.secrets."keys/arr_apis/sonarr".path;
    };

    exportarr-prowlarr = {
      enable = true;
      url = "http://localhost:9696";
      port = 9710;
      apiKeyFile = config.sops.secrets."keys/arr_apis/prowlarr".path;
    };
  };

  # arr stack
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    group = "media";
    downloadDirPermissions = "775";
    settings = {
      rpc-bind-address = "[::]";
      rpc-whitelist = "*";
      rpc-host-whitelist = "*";

      umask = "002";
      proxy_url = "socks5://localhost:8080";

      download-dir = "/srv/media/Downloads";

      alt-speed-up = 1000; # 1000KB/s
      alt-speed-down = 1000; # 1000KB/s

      # Scheduling option docs:
      # https://github.com/transmission/transmission/blob/main/docs/Editing-Configuration-Files.md#scheduling
      alt-speed-time-enabled = true;
      alt-speed-time-begin = 540; # 9am
      alt-speed-time-end = 1020; # 5pm
      alt-speed-time-day = 127; # all days of the week
    };
  };

  systemd.services.transmission.unitConfig.RequiresMountsFor = "/srv";

  services.radarr.enable = true;
  services.radarr.group = "media";
  systemd.services.radarr.wants = [
    "transmission.service"
    "prowlarr.service"
  ];

  services.sonarr.enable = true;
  services.sonarr.group = "media";
  systemd.services.sonarr.wants = [
    "transmission.service"
    "prowlarr.service"
  ];

  services.prowlarr.enable = true;

  sops.secrets."keys/arr_apis/radarr".mode = "0444";
  sops.secrets."keys/arr_apis/sonarr".mode = "0444";
  sops.secrets."keys/arr_apis/prowlarr".mode = "0444";
}
