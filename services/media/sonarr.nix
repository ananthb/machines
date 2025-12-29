{ config, ... }:
{
  services.sonarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };
  systemd.services.sonarr = {
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

  services.prometheus.exporters.exportarr-sonarr = {
    enable = true;
    url = "http://localhost:8989";
    port = 9709;
    apiKeyFile = config.sops.secrets."arr_apis/sonarr".path;
  };

  sops.secrets."arr_apis/sonarr".mode = "0444";

}
