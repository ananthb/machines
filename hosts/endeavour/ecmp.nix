{ pkgs, ... }:
let
  qbittorrentEcmpV6Script = pkgs.writeShellScript "qbt-ecmp-v6" ''
    set -euo pipefail
    state_dir="/run/qbittorrent-ecmp-v6"
    state_file="$state_dir/state"
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
      cat /run/systemd/netif/links/$l2 /run/systemd/netif/links/$l3 \
          /run/systemd/netif/leases/$l2 /run/systemd/netif/leases/$l3 \
        | sha256sum | awk '{print $1}'
    )"
    if [ -f "$state_file" ] && [ "$cur_hash" = "$(cat "$state_file")" ]; then
      exit 0
    fi
    echo "$cur_hash" > "$state_file"

    gws=()
    for dev in enp2s0 enp4s0; do
      gw="$(ip -6 route show default proto ra dev "$dev" | awk -v d="$dev" '{print $3 "@" d}' | head -n 1)"
      if [ -n "$gw" ]; then
        gws+=("$gw")
      fi
    done
    if [ "''${#gws[@]}" -eq 0 ]; then
      exit 0
    fi
    if [ "''${#gws[@]}" -eq 1 ]; then
      ip -6 route replace table 1002 default via "''${gws[0]%@*}" dev "''${gws[0]#*@}"
    else
      ip -6 route replace table 1002 default \
        nexthop via "''${gws[0]%@*}" dev "''${gws[0]#*@}" weight 1 \
        nexthop via "''${gws[1]%@*}" dev "''${gws[1]#*@}" weight 1
    fi
    ip -6 route flush cache
  '';
in
{
  systemd = {
    network.networks."20-enp2s0".routes = [
      {
        Destination = "0.0.0.0/0";
        Table = 1002;
        MultiPathRoute = [
          "192.168.29.1@enp2s0 1"
          "10.15.16.1@enp4s0 1"
        ];
      }
    ];

    services.qbittorrent-ecmp-v6 = {
      description = "Install IPv6 ECMP default route for qBittorrent policy table";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = qbittorrentEcmpV6Script;
      };
      path = [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gawk
        pkgs.iproute2
      ];
    };

    paths.qbittorrent-ecmp-v6 = {
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        Unit = "qbittorrent-ecmp-v6.service";
        PathChanged = [
          "/run/systemd/netif/links"
          "/run/systemd/netif/leases"
        ];
      };
    };
  };

  boot.kernel.sysctl."net.ipv4.fib_multipath_hash_policy" = 1;
}
