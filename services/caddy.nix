{ trustedIPs, ... }:
{
  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
        trusted_proxies static ${trustedIPs}
      }
    '';
  };

}
