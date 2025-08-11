{
  config,
  ...
}:
{
  imports = [
    ./common.nix
  ];

  sops.secrets."keys/Yubico/u2f_keys" = {
    path = config.xdg.configHome + "/Yubico/u2f_keys";
  };
}
