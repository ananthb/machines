{ ... }:

{
  homebrew.brews = [
    "readsb"
    "meilisearch"
  ];
  homebrew.casks = [
    "wireshark"
    "jellyfin"
    "kopiaui"
    "utm"
  ];
  homebrew.masApps = { };

  launchd = {
    user = {
      agents = {
        readsb = {
          command = "/opt/homebrew/bin/readsb --quiet --gain auto --device-type rtlsdr --ppm 0 --max-range 350 --modeac --net --net-heartbeat 60 --net-heartbeat 60 --net-ro-size 1200 --net-ro-interval 0.1 --net-ri-port 30001 --net-ro-port 30002 --net-sbs-port 30003 --net-bo-port 30005 --net-connector feed.airplanes.live,30004,beast_reduce_plus_out,feed.airplanes.live,64004 --uuid-file ~/Library/Application Support/readsb/airplanes.live/airplanes-uuid";
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
          };
        };

        tsnet-serve-tv = {
          command = "/Users/ananth/Downloads/tsnet-serve -funnel -hostname tv -state-dir ~/Library/Application Support/tsnet-serve/tv -backend localhost:8096";
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      };
    };
  };
}
