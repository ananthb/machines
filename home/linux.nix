{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
    ../programs/git.nix
    ../programs/gpg.nix
  ];

  home.packages = with pkgs; [ neovim ];

  sops.secrets."Yubico/u2f_keys" = {
    path = config.xdg.configHome + "/Yubico/u2f_keys";
  };
}
