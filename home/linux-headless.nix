{
  pkgs,
  username,
  ...
}:
{

  home.homeDirectory = "/home/${username}";

  home.packages = with pkgs; [
    git-credential-manager
    gcr
  ];

  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
  '';
}
