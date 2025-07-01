{
  username,
  ...
}:
{

  home.homeDirectory = "/home/${username}";

  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
  '';
}
