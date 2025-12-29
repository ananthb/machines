{ pkgs, ... }:
{
  services.prometheus.exporters = {
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
          https_2xx_via_warp:
            prober: http
            http:
              proxy_url: socks5://localhost:8888
              method: GET
              no_follow_redirects: true
              fail_if_not_ssl: true
      '';
    };

  };

}
