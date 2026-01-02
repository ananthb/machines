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
    ../home/${hostname}.nix
    ./programs/shell.nix
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

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    delta
    devenv
    fzf
    git
    gnupg
    hack-font
    lazygit
    mosh
    nix-output-monitor
    ripgrep
  ];

  home.stateVersion = "24.05";
}
