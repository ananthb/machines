{ ... }:

{
  homebrew.brews = [
    "readsb"
    "meilisearch"
    "tsnet-serve"
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
          serviceConfig = {
            Program = "/opt/homebrew/bin/readsb";
            ProgramArguments = [
              "--quiet"
              "--gain" "auto"
              "--device-type" "rtlsdr"
              "--ppm" "0"
              "--max-range" "350"
              "--modeac"
              "--net"
              "--net-heartbeat" "60"
              "--net-ro-size" "1200"
              "--net-ro-interval" "0.1"
              "--net-ri-port" "30001"
              "--net-ro-port" "30002"
              "--net-sbs-port" "30003"
              "--net-bo-port" "30005"
              "--net-connector" "feed.airplanes.live,30004,beast_reduce_plus_out,feed.airplanes.live,64004"
              "--uuid-file" "/Users/ananth/Library/Application\ Support/readsb/airplanes.live/airplanes-uuid"
            ];
            ProcessType = "Background";
            KeepAlive = true;
            RunAtLoad = true;
          };
        };

        mlat-client = {
          serviceConfig = {
            Program = "/Users/ananth/src/mlat-client/.venv/bin/python3";
            ProgramArguments = [
              "/Users/ananth/src/mlat-client/.venv/bin/mlat-client"
              "--input-type" "dump1090"
              "--no-udp"
              "--privacy"
              "--input-connect" "127.0.0.1:30005"
              "--server" "feed.airplanes.live:31090"
              "--user" "buntutintu"
              "--alt" "10m"
              "--results" "beast,connect,localhost:30005"
              "--results" "basestation,listen,31003"
              "--results" "beast,listen,30157"
              "--uuid-file" "/Users/ananth/Library/Application\ Support/readsb/airplanes.live/airplanes-uuid"
            ];
            ProcessType = "Background";
            KeepAlive = true;
            RunAtLoad = true;
          };
        };

        tsnet-serve-tv = {
          serviceConfig = {
            Program = "/Users/ananth/Downloads/tsnet-serve";
            ProgramArguments = [
              "-funnel"
              "-hostname" "tv"
              "-state-dir" "/Users/ananth/Library/Application\ Support/tsnet-serve/tv"
              "-backend" "localhost:8096"
            ];
            ProcessType = "Background";
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      };
    };
  };
}
