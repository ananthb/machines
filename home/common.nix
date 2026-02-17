{
  pkgs,
  username,
  ...
}:
let
  homeDir = (if pkgs.stdenv.isLinux then "/home/" else "/Users/") + username;
in
{
  imports = [
    ./shell.nix
  ];

  home = {
    homeDirectory = homeDir;
    inherit username;
    sessionVariables.EDITOR = "nvim";
  };

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    git
    hack-font
    htop
    mosh
    nix-output-monitor
  ];

  home.stateVersion = "24.05";
}
