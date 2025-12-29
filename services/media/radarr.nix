{ config, ... }:
{
  services.radarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };
  systemd.services.radarr = {
    serviceConfig.UMask = "0002";
    after = [
      "postgresql.service"
      "qbittorrent.service"
    ];
    wants = [
      "postgresql.service"
      "qbittorrent.service"
    ];
  };

  services.prometheus.exporters.exportarr-radarr = {
    enable = true;
    url = "http://localhost:7878";
    port = 9708;
    apiKeyFile = config.sops.secrets."arr_apis/radarr".path;
  };

  sops.secrets."arr_apis/radarr".mode = "0444";
}
