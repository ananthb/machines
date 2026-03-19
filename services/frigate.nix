{settings}: {
  config,
  pkgs,
  ...
}: let
  containerImages = import ../lib/container-images.nix;

  frigateConfig = pkgs.writeText "frigate-config.yml" (builtins.toJSON (settings
    // {
      database.path = "/db/frigate.db";
    }));

  inherit (config.virtualisation.quadlet) volumes;
in {
  virtualisation.quadlet = {
    volumes = {
      frigate-db = {};
    };

    containers = {
      frigate = {
        containerConfig = {
          name = "frigate";
          image = containerImages.frigate;
          autoUpdate = "registry";
          networks = ["host"];
          volumes = [
            "${frigateConfig}:/config/config.yml:ro"
            "${volumes.frigate-db.ref}:/db"
            "/srv/frigate/recordings:/media/frigate/recordings"
            "/srv/frigate/clips:/media/frigate/clips"
            "/srv/frigate/exports:/media/frigate/exports"
          ];
          environments = {
            FRIGATE_RTSP_PASSWORD = "";
          };
          devices = ["/dev/dri:/dev/dri"];
          podmanArgs = ["--shm-size=256m" "--privileged"];
        };
        unitConfig = {
          RequiresMountsFor = "/srv";
        };
        serviceConfig = {
          Restart = "on-failure";
        };
      };
    };
  };
}
