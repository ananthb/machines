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

    secrets."keys/ssh/yubikey_5c" = {
      path = homeDir + "/.ssh/yubikey_5c";
    };
    secrets."keys/ssh/yubikey_5c.pub" = {
      path = homeDir + "/.ssh/yubikey_5c.pub";
    };
    secrets."keys/ssh/yubikey_5c_nano" = {
      path = homeDir + "/.ssh/yubikey_5c_nano";
    };
    secrets."keys/ssh/yubikey_5c_nano.pub" = {
      path = homeDir + "/.ssh/yubikey_5c_nano.pub";
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
    lazygit
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
    devenv
  ];

  home.stateVersion = "24.05";
}
