{
  config,
  ...
}:

{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      volumes = {
        ripe-atlas-etc = { };
        ripe-atlas-run = { };
        ripe-atlas-var-spool = { };
      };

      containers = {
        globalping-probe.containerConfig = {
          name = "globalping-probe";
          image = "docker.io/globalping/globalping-probe:latest";
          networks = [ "host" ];
          addCapabilities = [ "NET_RAW" ];
          environmentFiles = [
            config.sops.templates."globalping/probe.env".path
          ];
        };

        ripe-atlas-probe.containerConfig = {
          name = "ripe-atlas-probe";
          image = "ghcr.io/jamesits/ripe-atlas:latest-probe";
          networks = [ "host" ];
          dropCapabilities = [ "all" ];
          addCapabilities = [
            "NET_RAW"
            "KILL"
            "SETUID"
            "SETGID"
            "FOWNER"
            "CHOWN"
            "DAC_OVERRIDE"
          ];
          environments = {
            RXTXRPT = "yes";
          };
          volumes = [
            "${volumes.ripe-atlas-etc.ref}:/etc/ripe-atlas"
            "${volumes.ripe-atlas-run.ref}:/run/ripe-atlas"
            "${volumes.ripe-atlas-var-spool.ref}:/var/spool/ripe-atlas"
          ];
        };
      };
    };

  sops.secrets = {
    "globalping/probeToken" = { };
  };

  sops.templates = {
    "globalping/probe.env" = {
      content = ''
        GP_ADOPTION_TOKEN=${config.sops.placeholder."globalping/probeToken"}
      '';
    };
  };
}
