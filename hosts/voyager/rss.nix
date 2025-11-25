{ config, ... }:
{
  networking.firewall.allowedTCPPorts = [ 8088 ];

  sops.secrets."miniflux/admin_creds" = { };
}
