{
  inputs,
  lib,
  pkgs,
  ...
}:
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
        active = false;
        autostart = false;
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

  # Allow host to listen on VM IPs when VMs are down (for socket activation)
  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

  systemd = {
    # Socket activation for VMs on RDP - template unit with IP as instance
    # Usage: systemctl enable --now vm-rdp@192.168.122.11.socket
    sockets."vm-rdp@" = {
      description = "Socket activation for VM RDP (%i)";
      after = [
        "libvirtd.service"
      ];
      requires = [ "libvirtd.service" ];
      socketConfig = {
        ListenStream = "%i:3389";
        FreeBind = true;
        Accept = false;
      };
    };

    services."vm-rdp@" = {
      description = "Start VM and proxy RDP connection (%i)";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "notify";
        ExecStart =
          pkgs.writeShellScript "vm-rdp-proxy" ''
            set -euo pipefail

            VM_IP="$1"
            RDP_PORT="3389"

            # Find VM name by looking up which domain has this IP in DHCP reservation
            VM_NAME=$(${pkgs.libvirt}/bin/virsh net-dumpxml default | \
              ${pkgs.gnugrep}/bin/grep -B1 "ip='$VM_IP'" | \
              ${pkgs.gnugrep}/bin/grep -oP "name='\K[^']+")

            if [ -z "$VM_NAME" ]; then
              echo "No VM found with IP $VM_IP in DHCP reservations"
              exit 1
            fi

            echo "Found VM: $VM_NAME for IP: $VM_IP"

            # Check if VM is already running
            if ! ${pkgs.libvirt}/bin/virsh domstate "$VM_NAME" 2>/dev/null | grep -q "running"; then
              echo "Starting VM $VM_NAME..."
              ${pkgs.libvirt}/bin/virsh start "$VM_NAME"
            fi

            # Wait for RDP port to be available on the VM
            echo "Waiting for RDP service on $VM_IP:$RDP_PORT..."
            for i in $(seq 1 120); do
              if ${pkgs.netcat}/bin/nc -z "$VM_IP" "$RDP_PORT" 2>/dev/null; then
                echo "RDP service is ready"
                break
              fi
              sleep 1
            done

            # Proxy the connection
            exec ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd "$VM_IP:$RDP_PORT"
          ''
          + " %i";
      };
    };

    # Enable socket activation for win11 VM
    sockets."vm-rdp@192.168.122.11" = {
      wantedBy = [ "sockets.target" ];
      overrideStrategy = "asDropin";
    };
  };
}
