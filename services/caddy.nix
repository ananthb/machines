{ ... }:
{
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
