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
  ];

  programs = {
    gnome-shell = {
      enable = true;
      extensions = with pkgs.gnomeExtensions; [
        {package = appindicator;}
        {package = gsconnect;}
        {package = night-theme-switcher;}
        {package = paperwm;}
        {package = system-monitor;}
        {package = tailscale-status;}
      ];
    };

    git = {
      signing = {
        format = "ssh";
        key = "~/.ssh/yubikey_5c_nano";
        signByDefault = true;
      };
      settings.credential = {
        helper = "!/etc/profiles/per-user/ananth/bin/gh auth git-credential";
        "https://github.com".username = "ananthb";
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # Exclude codespace hosts (cs.* and cs-*) so the YubiKey
    # IdentityFile doesn't block `gh codespace ssh` when the
    # device isn't plugged in. cosmonaut's doctor flags a bare
    # `Host *` here for exactly this reason.
    matchBlocks."* !cs-* !cs.*" = {
      identityFile = "~/.ssh/yubikey_5c";
    };
  };
}
