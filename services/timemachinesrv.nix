_: {
  services = {
    # Time Machine server via Samba
    samba = {
      enable = true;
      nmbd.enable = false;
      openFirewall = false;
      settings = {
        global = {
          "server string" = "Time Machine";
          "server role" = "standalone server";

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
          public = "yes";
          "guest ok" = "yes";
          "force user" = "nobody";
          "force group" = "nogroup";
          "create mask" = "0666";
          "directory mask" = "0777";
          "fruit:time machine" = "yes";
          "fruit:time machine max size" = "1T";
        };
      };
    };

  };

  systemd = {
    tmpfiles.rules = [
      "d /srv/timemachine 0777 nobody nogroup -"
    ];

    services.samba-smbd = {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
    };
  };
}
