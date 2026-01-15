{ config, ... }:
{
  services.prometheus.exporters.ecoflow = {
    enable = true;
    exporterType = "mqtt";
    ecoflowEmailFile = config.sops.secrets."ecoflow/email".path;
    ecoflowPasswordFile = config.sops.secrets."ecoflow/password".path;
    ecoflowDevicesPrettyNamesFile = config.sops.secrets."ecoflow/devices_pretty_names".path;
  };

  systemd.services.prometheus-ecoflow-exporter = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  sops.secrets = {
    "ecoflow/email".mode = "0444";
    "ecoflow/password".mode = "0444";
    "ecoflow/devices_pretty_names".mode = "0444";
  };
}
