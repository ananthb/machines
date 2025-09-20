{
  config,
  ...
}:
{
  imports = [
    ./common.nix
  ];

  sops.secrets."Yubico/u2f_keys" = {
    path = config.xdg.configHome + "/Yubico/u2f_keys";
  };
}
