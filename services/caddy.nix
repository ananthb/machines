_: {
  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
        trusted_proxies static ::1 127.0.0.0/8
      }
    '';
  };

}
