{
  username,
  config,
  ...
}:
{
  sops.secrets."keys/Yubico/u2f_keys" = {
    path = config.xdg.configHome + "/Yubico/u2f_keys";
  };

  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
  '';
}
