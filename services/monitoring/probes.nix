{
  config,
  containerImages,
  inputs,
  ...
}: let
  vs = config.vault-secrets.secrets;
in {
  imports = [
    inputs.starla.nixosModules.default
  ];

  users.groups."globalping-probe" = {};

  # Starla RIPE Atlas probe (replaces ripe-atlas-probe container)
  services.starla = {
    enable = true;
    reportInterfaceStats = true;
  };

  virtualisation.quadlet = {
    containers = {
      globalping-probe.containerConfig = {
        name = "globalping-probe";
        image = containerImages.globalpingProbe;
        networks = ["host"];
        addCapabilities = ["NET_RAW"];
        environmentFiles = [
          "${vs.globalping}/environment"
        ];
      };
    };
  };

  vault-secrets.secrets.globalping = {
    services = ["globalping-probe"];
    group = config.users.groups."globalping-probe".name;
  };
}
