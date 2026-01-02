{
  config,
  ...
}:
{
  imports = [
    ./common.nix
    ./programs/git.nix
    ./programs/gpg.nix
  ];

  sops.secrets."Yubico/u2f_keys" = {
    path = config.xdg.configHome + "/Yubico/u2f_keys";
  };
}
