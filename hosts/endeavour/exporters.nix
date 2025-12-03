{ pkgs, ... }:
{
  services.prometheus.exporters = {
    blackbox = {
      enable = true;
      configFile = pkgs.writeText "blackbox_exporter.conf" ''
        modules:
          https_2xx_via_warp:
            prober: http
            http:
              proxy_url: socks5://localhost:8888
              method: GET
              no_follow_redirects: true
              fail_if_not_ssl: true
      '';

    };

    # TODO: fix this
    mysqld = {
      enable = false;
      runAsLocalSuperUser = true;
      listenAddress = "[::]";
      configFile = pkgs.writeText "config.my-cnf" "";
    };

    postgres.enable = true;
    postgres.runAsLocalSuperUser = true;

    smartctl.enable = true;
  };

  # Caddy webserver
  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
        trusted_proxies static ::1 127.0.0.0/8 fdc0:6625:5195::0/64 10.15.16.0/24
      }
    '';
  };

}
