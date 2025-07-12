{
  pkgs,
  username,
  ...
}:
{

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
    moolticute
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

  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
  '';

  programs.git.extraConfig = {
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
