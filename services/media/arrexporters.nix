{ config, ... }:
{
  services.prometheus.exporters = {
    exportarr-radarr = {
      enable = true;
      url = "http://endeavour.local:7878";
      port = 9708;
      apiKeyFile = config.sops.secrets."arr_apis/radarr".path;
    };

    exportarr-sonarr = {
      enable = true;
      url = "http://endeavour.local:8989";
      port = 9709;
      apiKeyFile = config.sops.secrets."arr_apis/sonarr".path;
    };

    exportarr-prowlarr = {
      enable = true;
      url = "http://endeavour.local:9696";
      port = 9710;
      apiKeyFile = config.sops.secrets."arr_apis/prowlarr".path;
    };

  };

  sops.secrets = {
    "arr_apis/radarr".mode = "0444";
    "arr_apis/sonarr".mode = "0444";
    "arr_apis/prowlarr".mode = "0444";
  };

}
