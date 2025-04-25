{ pkgs, system, ... }:

{
  homebrew.brews = [ ];
  homebrew.casks =
    [ "wireshark" "jellyfin" "kopiaui" "qbittorrent" "cloudflare-warp" ];
  homebrew.masApps = { };
}
