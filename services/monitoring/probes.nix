{
  config,
  containerImages,
  ...
}:
let
  vs = config.vault-secrets.secrets;
in
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
          image = containerImages.globalpingProbe;
          networks = [ "host" ];
          addCapabilities = [ "NET_RAW" ];
          environmentFiles = [
            "${vs.globalping}/environment"
          ];
        };

        ripe-atlas-probe.containerConfig = {
          name = "ripe-atlas-probe";
          image = containerImages.ripeAtlasProbe;
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

  vault-secrets.secrets.globalping = {
    services = [ "globalping-probe" ];
  };

}
