{ ... }:
{
  services.prometheus.exporters.libvirt = {
    enable = true;
    openFirewall = true;
  };
}
