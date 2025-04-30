{ pkgs, system, ... }:

{
  homebrew.brews = [ "nut" ];
  homebrew.casks =
    [ "wireshark" "jellyfin" "kopiaui" "qbittorrent" "cloudflare-warp" ];
  homebrew.masApps = { };
}
