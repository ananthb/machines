{
  pkgs,
  ...
}:
{
  imports = [
    ../programs/nixvim.nix
    ../programs/nushell.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard
    git-credential-manager
    gcr

    # Apps
    firefox
    google-chrome
    ghostty
    jellyfin-media-player
    wireshark
    zed-editor
    rpi-imager
    vlc
    vscode
    neovide
    gimp

    gnomeExtensions.appindicator
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.gsconnect
  ];

  services.gnome-keyring.enable = true;

  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          appindicator.extensionUuid
          night-theme-switcher.extensionUuid
          gsconnect.extensionUuid
          system-monitor.extensionUuid
        ];
      };
    };
  };

  programs.git.settings = {
    credential = {
      helper = "manager";
      "https://github.com".username = "ananthb";
      credentialStore = "secretservice";
    };
  };

  fonts = {
    fontconfig.enable = true;
  };
}
