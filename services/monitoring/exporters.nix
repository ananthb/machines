{ config, pkgs, ... }:
{
  services.prometheus.exporters = {
    postgres.enable = true;
    postgres.runAsLocalSuperUser = true;

    exportarr-radarr = {
      enable = true;
      url = "http://endeavour:7878";
      port = 9708;
      apiKeyFile = config.sops.secrets."arr_apis/radarr".path;
    };

    exportarr-sonarr = {
      enable = true;
      url = "http://endeavour:8989";
      port = 9709;
      apiKeyFile = config.sops.secrets."arr_apis/sonarr".path;
    };

    exportarr-prowlarr = {
      enable = true;
      url = "http://endeavour:9696";
      port = 9710;
      apiKeyFile = config.sops.secrets."arr_apis/prowlarr".path;
    };

    blackbox = {
      enable = true;
      configFile = pkgs.writeText "blackbox_exporter.conf" ''
        modules:
          icmp:
            prober: icmp
          http_2xx:
            prober: http
            http:
              method: GET
              no_follow_redirects: true
              fail_if_ssl: true
          https_2xx:
            prober: http
            http:
              method: GET
              no_follow_redirects: true
              fail_if_not_ssl: true
      '';
    };

  };

  sops.secrets = {
    "arr_apis/radarr".mode = "0444";
    "arr_apis/sonarr".mode = "0444";
    "arr_apis/prowlarr".mode = "0444";
  };

}
