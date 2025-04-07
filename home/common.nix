{ lib, pkgs, inputs, system, username, ... }@args: {
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  home.username = username;
  home.homeDirectory = lib.mkDefault
    (if lib.strings.hasSuffix "darwin" system then
      "/home/${username}"
    else
      "/Users/${username}");
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
    git-credential-manager
    gcr
    unzip
  ];

  home.stateVersion = "24.05";
}
