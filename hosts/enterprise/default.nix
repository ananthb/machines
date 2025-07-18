{ config, ... }:

{
  homebrew.brews = [
    "readsb"
  ];
  homebrew.casks = [
    "kopiaui"
    "utm"
    "jellyfin-media-player"
  ];
  homebrew.masApps = { };

  launchd = {
    user = {
      agents = {
        readsb = {
          script = ''
            	    /opt/homebrew/bin/readsb \
                          --gain auto \
                          --device-type rtlsdr \
                          --ppm 0 \
                          --max-range 350 \
                          --modeac \
            	          --lat $(cat $LAT_PATH) \
            	          --lon $(cat $LON_PATH) \
                          --net \
                          --net-heartbeat 60 \
                          --net-ro-size 1200 \
                          --net-ro-interval 0.1 \
                          --net-ri-port 30001 \
                          --net-ro-port 30002 \
                          --net-sbs-port 30003 \
                          --net-bo-port 30005 \
                          --net-connector feed.airplanes.live,30004,beast_reduce_plus_out,feed.airplanes.live,64004 \
                          --net-connector feed1.adsbexchange.com,30004,beast_reduce_out,feed2.adsbexchange.com,64004 \
                          --uuid-file /Users/ananth/Library/Application\ Support/readsb/uuid.txt
            	  '';
          serviceConfig = {
            EnvironmentVariables = {
              LAT_PATH = config.sops.secrets."home/6a/latitude".path;
              LON_PATH = config.sops.secrets."home/6a/longitude".path;
            };
            ProcessType = "Background";
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = "/Users/ananth/Library/Logs/readsb/readsb.log";
            StandardErrorPath = "/Users/ananth/Library/Logs/readsb/readsb.log";
          };
        };

        mlat-client-airplanes-live = {
          script = ''
                          /Users/ananth/src/mlat-client/.venv/bin/python3
            	        /Users/ananth/src/mlat-client/.venv/bin/mlat-client \
                            --input-type dump1090 \
                            --no-udp \
                            --privacy \
                            --input-connect 127.0.0.1:30005 \
                            --server feed.airplanes.live:31090 \
                            --user buntutintu \
            		    --lat $(cat $LAT_PATH) \
            		    --lon $(cat $LON_PATH) \
                            --alt $(cat $ALT_PATH)m \
                            --results beast,connect,localhost:30005 \
                            --results basestation,listen,31003 \
                            --results beast,listen,30157 \
                            --uuid-file /Users/ananth/Library/Application\ Support/mlat-client/airplanes-uuid.txt
            	    '';
          serviceConfig = {
            EnvironmentVariables = {
              LAT_PATH = config.sops.secrets."home/6a/latitude".path;
              LON_PATH = config.sops.secrets."home/6a/longitude".path;
              ALT_PATH = config.sops.secrets."home/6a/elevation".path;
            };
            ProcessType = "Background";
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = "/Users/ananth/Library/Logs/mlat-client/airplanes-live.log";
            StandardErrorPath = "/Users/ananth/Library/Logs/mlat-client/airplanes-live.log";
          };
        };

        mlat-client-adsbexchange = {
          script = ''
                        /Users/ananth/src/mlat-client/.venv/bin/python3
            	      /Users/ananth/src/mlat-client/.venv/bin/mlat-client \
            	      --input-type dump1090 \
            	      --no-udp \
            	      --privacy \
            	      --input-connect 127.0.0.1:30005 \
            	      --server feed.adsbexchange.com:31090 \
            	      --user blasduncds \
            	      --lat $(cat $LAT_PATH) \
            	      --lon $(cat $LON_PATH) \
                      --alt $(cat $ALT_PATH)m \
            	      --results beast,connect,localhost:30005 \
            	      --results basestation,listen,31004 \
            	      --results beast,listen,30158 \
            	      --uuid-file /Users/ananth/Library/Application\ Support/mlat-client/adsbexchange-uuid.txt
          '';
          serviceConfig = {
            EnvironmentVariables = {
              LAT_PATH = config.sops.secrets."home/6a/latitude".path;
              LON_PATH = config.sops.secrets."home/6a/longitude".path;
              ALT_PATH = config.sops.secrets."home/6a/elevation".path;
            };
            ProcessType = "Background";
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = "/Users/ananth/Library/Logs/mlat-client/adsbexchange.log";
            StandardErrorPath = "/Users/ananth/Library/Logs/mlat-client/adsbexchange.log";
          };
        };
      };
    };
  };
}
