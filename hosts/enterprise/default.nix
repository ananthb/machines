{ pkgs, system, ... }:

{
  homebrew.brews = [
    "mas"
    {
      name = "neovim";
      link = false;
    }
  ];
  homebrew.casks = [
    "google-chrome"
    "visual-studio-code"
    "wireshark"
    "vlc"
    "ghostty"
    "neovide"
    "jellyfin"
    "kopiaui"
    "qbittorrent"
    "cloudflare-warp"
    "scroll-reverser"
    "rectangle-pro"
    "ddpm"
    "browserosaurus"
  ];
  homebrew.masApps = { "Tailscale" = 1475387142; };
}
