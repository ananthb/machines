{ inputs, lib, ... }:
let
  inherit (inputs.NixVirt.lib) domain;
in
{
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      {
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
