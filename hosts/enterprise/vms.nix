{ inputs, lib, ... }:
let
  inherit (inputs.NixVirt.lib) domain network;
in
{
  virtualisation.libvirt.connections."qemu:///system" = {
    networks = [
      {
        definition = network.writeXML {
          name = "default";
          uuid = "be431e55-852c-4f3d-b475-e24afd1dcbe7";
          forward.mode = "nat";
          bridge = {
            name = "virbr0";
            stp = "on";
            delay = 0;
          };
          mac.address = "52:54:00:3a:b0:32";
          ip = {
            address = "192.168.122.1";
            netmask = "255.255.255.0";
            dhcp = {
              range = {
                start = "192.168.122.2";
                end = "192.168.122.254";
              };
              host = [
                {
                  mac = "52:54:00:3e:51:ae";
                  ip = "192.168.122.11";
                  name = "win11";
                }
              ];
            };
          };
        };
        active = true;
        autostart = true;
      }
    ];
    domains = [
      {
        active = true;
        autostart = true;
        definition = domain.writeXML (
          lib.recursiveUpdate
            (domain.templates.windows {
              name = "win11";
              uuid = "9aa5f856-d6f3-492e-b94e-3d6318365482";
              memory = {
                count = 8388608;
                unit = "KiB";
              };
              vcpu = 4;
              nvram_path = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd";
            })
            {
              metadata = {
                "libosinfo:libosinfo"."@xmlns:libosinfo" = "http://libosinfo.org/xmlns/libvirt/domain/1.0";
                "libosinfo:libosinfo"."libosinfo:os"."@id" = "http://microsoft.com/win/11";
              };
              memoryBacking = {
                source.type = "memfd";
                access.mode = "shared";
              };
              devices = {
                graphics = {
                  gl = {
                    rendernode = "/dev/dri/by-path/pci-0000:00:02.0-render";
                  };
                };
                disk = [
                  {
                    type = "file";
                    device = "cdrom";
                    driver = {
                      name = "qemu";
                      type = "raw";
                    };
                    target = {
                      dev = "sdb";
                      bus = "sata";
                    };
                    readonly = { };
                  }
                  {
                    type = "file";
                    device = "disk";
                    driver = {
                      name = "qemu";
                      type = "qcow2";
                    };
                    source = {
                      file = "/var/lib/libvirt/images/win11.qcow2";
                    };
                    target = {
                      dev = "vda";
                      bus = "virtio";
                    };
                    boot = {
                      order = 2;
                    };
                  }
                ];
                interface = [
                  {
                    type = "network";
                    mac = {
                      address = "52:54:00:3e:51:ae";
                    };
                    source = {
                      network = "default";
                    };
                    model = {
                      type = "virtio";
                    };
                  }
                ];
              };
            }
        );
      }
    ];
  };
}
