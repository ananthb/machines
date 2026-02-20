{ containerImages, ... }:
{
  virtualisation.quadlet = {
    autoUpdate.enable = true;
    containers.immich-machine-learning = {
      containerConfig = {
        name = "immich-machine-learning";
        image = containerImages.immichMl;
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
