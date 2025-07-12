{
  pkgs,
  nixvim,
  username,
  ...
}@args:
let
  homeDir = (if pkgs.stdenv.isLinux then "/home/" else "/Users/") + username;
in
{
  imports = [ nixvim.homeManagerModules.nixvim ];

  home.homeDirectory = homeDir;
  home.username = username;
  home.sessionVariables.EDITOR = "nvim";

  sops = {
    age.sshKeyPaths =
      let
        sshKeyPath = homeDir + "/.ssh/id_ed25519";
      in
      [ sshKeyPath ];
    defaultSopsFile = ../secrets.yaml;

    secrets."keys/ssh/id_ed25519_sk" = {
      path = homeDir + "/.ssh/id_ed25519_sk";
    };
    secrets."keys/ssh/id_ed25519_sk.pub" = {
      path = homeDir + "/.ssh/id_ed25519_sk.pub";
    };
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
