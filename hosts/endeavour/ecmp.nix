{ pkgs, ... }:
let
  ecmpV6Script = pkgs.writeShellScript "ecmp-v6" ''
    set -euo pipefail
    state_dir="/run/ecmp-v6"
    state_file="$state_dir/state"
    script_version="2"
    mkdir -p "$state_dir"

    link_id_for_network() {
      local network_file="$1"
      for f in /run/systemd/netif/links/*; do
        [ -f "$f" ] || continue
        if grep -q "NETWORK_FILE=$network_file" "$f"; then
          basename "$f"
          return 0
        fi
      done
      return 1
    }

    l2="$(link_id_for_network /etc/systemd/network/20-enp2s0.network || true)"
    l3="$(link_id_for_network /etc/systemd/network/30-enp4s0.network || true)"
    if [ -z "$l2" ] || [ -z "$l3" ]; then
      exit 0
    fi

    cur_hash="$(
      { echo "$script_version";
        cat /run/systemd/netif/links/$l2 /run/systemd/netif/links/$l3 \
            /run/systemd/netif/leases/$l2 /run/systemd/netif/leases/$l3;
      } | sha256sum | awk '{print $1}'
    )"
    if [ -f "$state_file" ] && [ "$cur_hash" = "$(cat "$state_file")" ]; then
      exit 0
    fi
    echo "$cur_hash" > "$state_file"

    gw2="$(
      ip -6 route show default proto ra dev enp2s0 \
        | awk '{for (i=1; i<=NF; i++) if ($i=="via") {print $(i+1); exit}}'
    )"
    gw4="$(
      ip -6 route show default proto ra dev enp4s0 \
        | awk '{for (i=1; i<=NF; i++) if ($i=="via") {print $(i+1); exit}}'
    )"
    if [ -n "$gw2" ]; then
      ip -6 route replace table 1001 default via "$gw2" dev enp2s0
    fi
    if [ -n "$gw4" ]; then
      ip -6 route replace table 1002 default via "$gw4" dev enp4s0
    fi
    ip -6 route flush cache
  '';
in
{
  systemd = {
    network.networks."20-enp2s0".routes = [
      {
        Destination = "0.0.0.0/0";
        Gateway = "192.168.29.1";
        Table = 1001;
      }
    ];
    network.networks."30-enp4s0".routes = [
      {
        Destination = "0.0.0.0/0";
        Gateway = "10.15.16.1";
        Table = 1002;
      }
    ];

    services.ecmp-v6 = {
      description = "Install IPv6 default routes for uplink tables";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ecmpV6Script;
      };
      path = [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gawk
        pkgs.iproute2
      ];
    };

    paths.ecmp-v6 = {
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        Unit = "ecmp-v6.service";
        PathChanged = [
          "/run/systemd/netif/links"
          "/run/systemd/netif/leases"
        ];
      };
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.fib_multipath_hash_policy" = 1;
    "net.ipv4.fib_multipath_use_neigh" = 1;
    "net.ipv6.fib_multipath_hash_policy" = 1;
    "net.ipv6.fib_multipath_use_neigh" = 1;
  };
}
