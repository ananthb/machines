{ config, ... }:
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets."miniflux/admin_creds".path;
    config.LISTEN_ADDR = "[::]:8088";
    config.BASE_URL = "https://miniflux.kedi.dev";
  };

  networking.firewall.allowedTCPPorts = [ 8088 ];

  sops.secrets."miniflux/admin_creds" = { };
}
