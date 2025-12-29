{ config, ... }:
{
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.prowlarr = {
    after = [
      "postgresql.service"
      "radarr.service"
      "sonarr.service"
      "qbittorrent.service"
    ];
    wants = [
      "postgresql.service"
      "radarr.service"
      "sonarr.service"
      "qbittorrent.service"
    ];
  };

  services.prometheus.exporters.exportarr-prowlarr = {
    enable = true;
    url = "http://endeavour.local:9696";
    port = 9710;
    apiKeyFile = config.sops.secrets."arr_apis/prowlarr".path;

  };

  sops.secrets."arr_apis/prowlarr".mode = "0444";
}
