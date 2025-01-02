{
  pkgs,
  inputs,
  system,
  username,
  ...
}:
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.sessionVariables.EDITOR = "nvim";

  home.packages = [
    # Fonts
    pkgs.hack-font

    # Shell
    pkgs.nushell
    pkgs.fish
    pkgs.mosh
    pkgs.wl-clipboard

    # Tools
    pkgs.atool
    pkgs.tree
    pkgs.git
    pkgs.curl
    pkgs.ripgrep
    pkgs.httpie
    pkgs.htop
    pkgs.delta
    pkgs.tokei
    pkgs.fzf
    pkgs.git-credential-manager
    pkgs.gcr
    pkgs.hugo
    pkgs.wrangler
    pkgs.flyctl
    pkgs.unzip

    # Languages
    pkgs.nodejs
    pkgs.pnpm
    pkgs.zig
    pkgs.go

    # Apps
    pkgs.firefox
    pkgs.google-chrome
    pkgs.alacritty
    inputs.ghostty.packages.${system}.default
    pkgs.jellyfin-media-player
    pkgs.wireshark
    pkgs.moolticute
    pkgs.neovide
    pkgs.zed-editor
    pkgs.bruno
    pkgs.rpi-imager
    pkgs.vlc

    # Gnome extensions
    pkgs.gnomeExtensions.appindicator
    pkgs.gnomeExtensions.night-theme-switcher
  ];

  services.gnome-keyring.enable = true;

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "org.gnome.shell.extensions.appindicator"
      ];
    };
  };

  fonts = {
    fontconfig.enable = true;
  };

  programs = import ./programs pkgs;

  home.stateVersion = "24.05";
}
