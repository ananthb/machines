_: {
  services = {
    # Time Machine server via Samba
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "server string" = "Time Machine";
          "server role" = "standalone server";

          # Listen only on Tailscale (lo required for internal communication)
          interfaces = "lo tailscale0";
          "bind interfaces only" = "yes";

          # Guest access
          "map to guest" = "Bad User";

          # macOS compatibility
          "vfs objects" = "catia fruit streams_xattr";
          "fruit:aapl" = "yes";
          "fruit:nfs_aces" = "no";
          "fruit:model" = "MacSamba";

          # Performance
          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY";
          "use sendfile" = "yes";
        };

        timemachine = {
          path = "/srv/timemachine";
          browseable = "yes";
          writeable = "yes";
          "guest ok" = "yes";
          "force user" = "nobody";
          "force group" = "nogroup";
          "fruit:time machine" = "yes";
          "fruit:time machine max size" = "1T";
        };
      };
    };

    # Avahi for Time Machine discovery
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/timemachine 0777 nobody nogroup -"
  ];
}
