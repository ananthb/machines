{ ... }:
{
  virtualisation.quadlet = {
    autoUpdate.enable = true;
    containers.immich-machine-learning = {
      containerConfig = {
        name = "immich-machine-learning";
        image = "ghcr.io/immich-app/immich-machine-learning:release";
        autoUpdate = "registry";
        publishPorts = [ "3003:3003" ];
        volumes = [
          "immich-model-cache:/cache"
        ];
      };
      serviceConfig = {
        Restart = "on-failure";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 3003 ];
}
