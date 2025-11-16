{ config, ... }:
{
  virtualisation.quadlet = {
    autoEscape = true;
    autoUpdate.enable = true;

    containers.globalping-probe = {
      containerConfig = {
        name = "globalping-probe";
        image = "docker.io/globalping/globalping-probe:latest";
        networks = [ "host" ];
        restartPolicy = "always";
        addCapabilities = [ "NET_RAW" ];
        environmentFiles = [
          config.sops.templates."globalping/probe.env".path
        ];
      };
    };
  };

  sops.secrets."globalping/probeToken" = { };
  sops.templates."globalping/probe.env" = {
    content = ''
      GP_ADOPTION_TOKEN=${config.sops.placeholder."globalping/probeToken"}
    '';
  };
}
