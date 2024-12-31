{
  pkgs,
  inputs,
  system,
  ...
}:
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  home.username = "ananth";
  home.homeDirectory = "/home/ananth";
  home.sessionVariables.EDITOR = "nvim";

  home.packages = [
    # Fonts
    pkgs.hack-font

    # Tools
    pkgs.nushell
    pkgs.fish
    pkgs.mosh
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
    pkgs.bruno
    pkgs.rpi-imager
    pkgs.vlc

    # Gnome extensions
    pkgs.gnomeExtensions.appindicator
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
