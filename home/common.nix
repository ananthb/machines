{
  hostname,
  inputs,
  pkgs,
  username,
  ...
}:
let
  homeDir = (if pkgs.stdenv.isLinux then "/home/" else "/Users/") + username;
in
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./programs
    ../home/${hostname}.nix
  ];

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

    secrets."ssh/yubikey_5c" = {
      path = homeDir + "/.ssh/yubikey_5c";
    };
    secrets."ssh/yubikey_5c.pub" = {
      path = homeDir + "/.ssh/yubikey_5c.pub";
    };
    secrets."ssh/yubikey_5c_nano" = {
      path = homeDir + "/.ssh/yubikey_5c_nano";
    };
    secrets."ssh/yubikey_5c_nano.pub" = {
      path = homeDir + "/.ssh/yubikey_5c_nano.pub";
    };
  };

  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
  '';

  home.packages = with pkgs; [
    # Fonts
    hack-font

    # Shell
    nushell
    mosh
    oils-for-unix
    fish

    # Tools
    nix-output-monitor
    git
    lazygit
    jujutsu
    ripgrep
    delta
    fzf
    devenv
    gnupg
  ];

  home.stateVersion = "24.05";
}
