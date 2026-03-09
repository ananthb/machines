{pkgs, ...}: {
  home.packages = with pkgs; [
    discord
    element-desktop
    firefox
    gcr
    ghostty
    gimp
    google-chrome
    jamesdsp
    jellyfin-media-player
    rpi-imager
    signal-desktop
    slack
    telegram-desktop
    vlc
    vscode
    wireshark
    wl-clipboard
    zed-editor
  ];

  programs = {
    gnome-shell = {
      enable = true;
      extensions = with pkgs.gnomeExtensions; [
        {package = another-window-session-manager;}
        {package = appindicator;}
        {package = gsconnect;}
        {package = night-theme-switcher;}
        {package = system-monitor;}
        {package = tailscale-status;}
        {package = tiling-shell;}
      ];
    };

    git.settings = {
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/yubikey_5c";
      commit.gpgsign = "true";
      credential = {
        helper = "!/etc/profiles/per-user/ananth/bin/gh auth git-credential";
        "https://github.com".username = "ananthb";
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      identityFile = "~/.ssh/yubikey_5c";
    };
  };
}
