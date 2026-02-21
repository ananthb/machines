{ lib, pkgs, ... }:
{
  services.prometheus.exporters.libvirt = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.prometheus-libvirt-exporter.serviceConfig = {
    ExecStart = lib.mkForce ''
      ${pkgs.prometheus-libvirt-exporter}/bin/libvirt-exporter \
        --web.listen-address [::]:9177
    '';
    RestrictAddressFamilies = lib.mkForce [
      "AF_INET"
      "AF_INET6"
      "AF_UNIX"
    ];
    SupplementaryGroups = [ "libvirtd" ];
  };

}
