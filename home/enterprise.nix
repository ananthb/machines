{
  pkgs,
  ...
}:
{
  imports = [
    ./dev.nix
  ];

  home.packages = with pkgs; [
    discord
    element-desktop
    firefox
    gcr
    google-chrome
    ghostty
    gimp
    git-credential-manager
    gnomeExtensions.appindicator
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.gsconnect
    jellyfin-media-player
    junction
    rpi-imager
    slack
    signal-desktop
    telegram-desktop
    vlc
    vscode
    wireshark
    wl-clipboard
    zed-editor
  ];

  services.gnome-keyring.enable = true;

  dconf = {
    enable = true;
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-ac-timeout = 0;
      };
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

  xdg.desktopEntries.chrome-triton = {
    name = "Chrome (triton.one)";
    exec = "/etc/profiles/per-user/ananth/bin/google-chrome-stable --profile-directory=\"Profile 2\" --class=WorkProfile -- %u";
    terminal = false;
    icon = "google-chrome";
    type = "Application";
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [ "x-scheme-handler/org-protocol" ];
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
