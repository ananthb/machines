{
  pkgs,
  nixvim,
  username,
  ...
}@args:
{
  imports = [ nixvim.homeManagerModules.nixvim ];

  sops = {
    defaultSopsFile = ../secrets.yaml;
  };

  home.username = username;
  home.sessionVariables.EDITOR = "nvim";

  home.file = {
    ".ssh/id_ed25519_sk.pub".source = ../keys/ssh/id_ed25519_sk.pub;
  };

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
