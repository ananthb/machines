{ ... }:

{
  homebrew.brews = [
    "nut"
    "readsb"
  ];
  homebrew.casks =
    [ "wireshark" "jellyfin" "kopiaui" "utm" ];
  homebrew.masApps = { };

  launchd = {
    user = {
      agents = {
        readsb = {
          command = "/opt/homebrew/bin/readsb --net --aggressive";
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
          };
        };

        tsnet-serve-tv = {
          command = "/Users/ananth/Downloads/tsnet-serve -funnel -hostname tv -state-dir /Users/ananth/Downloads/state -backend localhost:8096";
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      };
    };
  };
}
