{ config, lib, ... }:
let
  vs = config.vault-secrets.secrets;
in
{
  users.groups.ecoflow-exporter = lib.mkDefault { };
  users.users.prometheus = lib.mkIf (config.users.users ? prometheus) {
    extraGroups = lib.mkAfter [ "ecoflow-exporter" ];
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
