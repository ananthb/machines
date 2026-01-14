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

  sops = {
    age.sshKeyPaths =
      let
        sshKeyPath = homeDir + "/.ssh/id_ed25519";
      in
      [ sshKeyPath ];
    defaultSopsFile = ../secrets.yaml;

    secrets = {
      "ssh/yubikey_5c" = {
        path = homeDir + "/.ssh/yubikey_5c";
      };
      "ssh/yubikey_5c.pub" = {
        path = homeDir + "/.ssh/yubikey_5c.pub";
      };
      "ssh/yubikey_5c_nano" = {
        path = homeDir + "/.ssh/yubikey_5c_nano";
      };
      "ssh/yubikey_5c_nano.pub" = {
        path = homeDir + "/.ssh/yubikey_5c_nano.pub";
      };
    };
  };

  # Fix for sops-nix LaunchAgent on macOS
  launchd.agents.sops-nix = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      EnvironmentVariables = {
        PATH = pkgs.lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
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
