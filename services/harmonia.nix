{
  config,
  ...
}:
{
  services.harmonia = {
    enable = true;
    signKeyPaths = [ config.sops.secrets."harmonia/signing-key".path ];
    settings.bind = "[::]:5000";
  };

  sops.secrets."harmonia/signing-key" = { };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}
