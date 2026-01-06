{ config, ... }:
{
  services.prometheus.exporters.ecoflow = {
    enable = true;
    exporterType = "mqtt";
    ecoflowEmailFile = config.sops.secrets."ecoflow/email".path;
    ecoflowPasswordFile = config.sops.secrets."ecoflow/password".path;
    ecoflowDevicesPrettyNamesFile = config.sops.secrets."ecoflow/devices_pretty_names".path;
  };

  sops.secrets = {
    "ecoflow/email" = { };
    "ecoflow/password" = { };
    "ecoflow/devices_pretty_names" = { };
  };
}
