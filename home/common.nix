{
  pkgs,
  inputs,
  username,
  ...
}@args:
{
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  home.username = username;
  home.sessionVariables.EDITOR = "nvim";

  programs = import ./programs args;

  home.packages = with pkgs; [
    # Fonts
    hack-font

    # Shell
    nushell
    mosh
    oils-for-unix
    fish

    # Tools
    atool
    tree
    git
    ripgrep
    curl
    httpie
    htop
    delta
    tokei
    fzf
    unzip
    nix-output-monitor
    kopia
    flyctl
  ];

  home.stateVersion = "24.05";
}
