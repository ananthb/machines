{ ... }:

{
  homebrew.brews = [ "nut" "dump1090-mutability" ];
  homebrew.casks =
    [ "wireshark" "jellyfin" "kopiaui" "qbittorrent" "cloudflare-warp" ];
  homebrew.masApps = { };

  launchd = {
    user = {
      agents = {
        dump1090 = {
          command = "dump1090 --net --aggressive";
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      };
    };
  };
}
