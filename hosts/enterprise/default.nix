{ pkgs, system, ... }:

{
  homebrew.brews = [ "nut" ];
  homebrew.casks =
    [ "wireshark" "jellyfin" "kopiaui" "qbittorrent" "cloudflare-warp" ];
  homebrew.masApps = { };

  launchd = {
    user = {
      agents = {
        dump1090 = {
          command = "dump1090 --net";
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      };
    };
  };
}
