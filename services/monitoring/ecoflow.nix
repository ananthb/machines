{ config, lib, ... }:
let
  vs = config.vault-secrets.secrets;
in
{
  users = {
    groups = {
      ecoflow-exporter = lib.mkIf config.services.prometheus.exporters.ecoflow.enable (lib.mkDefault { });
      prometheus = lib.mkIf config.services.prometheus.exporters.ecoflow.enable (lib.mkDefault { });
    };
    users.prometheus = lib.mkIf config.services.prometheus.exporters.ecoflow.enable {
      isSystemUser = lib.mkDefault true;
      group = "prometheus";
      extraGroups = lib.mkAfter [ "ecoflow-exporter" ];
    };
  };

  services.prometheus.exporters.ecoflow = {
    enable = true;
    exporterType = "mqtt";
    ecoflowEmailFile = "${vs.ecoflow}/email";
    ecoflowPasswordFile = "${vs.ecoflow}/password";
    ecoflowDevicesPrettyNamesFile = "${vs.ecoflow}/devices_pretty_names";
  };

  systemd.services.prometheus-ecoflow-exporter = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  vault-secrets.secrets.ecoflow = {
    services = [ "prometheus-ecoflow-exporter" ];
    user = "prometheus";
    group = "ecoflow-exporter";
  };

}
