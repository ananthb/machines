{
  config,
  pkgs,
  nixvim,
  username,
  ...
}@args:
{
  imports = [ nixvim.homeManagerModules.nixvim ];

  sops = {
    age.sshKeyPaths =
      let
        homeDir = (if pkgs.stdenv.isLinux then "/home/" else "/Users/") + username + "/.ssh/id_ed25519";
      in
      [ homeDir ];
    defaultSopsFile = ../secrets.yaml;

    secrets."keys/ssh/id_ed25519_sk" = {
      path = ".ssh/id_ed25519_sk";
    };
    secrets."keys/ssh/id_ed25519_sk.pub" = {
      path = ".ssh/id_ed25519_sk.pub";
    };
  };

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
