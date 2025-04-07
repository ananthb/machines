{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    wl-clipboard
    git-credential-manager
    gcr

    # Apps
    firefox
    google-chrome
    inputs.ghostty.packages.${system}.default
    jellyfin-media-player
    wireshark
    moolticute
    neovide
    zed-editor
    bruno
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

  fonts = { fontconfig.enable = true; };
}
