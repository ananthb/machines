_: {
  services = {
    # Time Machine server via Samba
    samba = {
      enable = true;
      nmbd.enable = false;
      openFirewall = true;
      settings = {
        global = {
          "server string" = "Time Machine";
          "server role" = "standalone server";

          # Listen only on Tailscale
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
      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?>
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
              <type>_smb._tcp</type>
              <port>445</port>
            </service>
            <service>
              <type>_device-info._tcp</type>
              <port>9</port>
              <txt-record>model=TimeCapsule8,119</txt-record>
            </service>
            <service>
              <type>_adisk._tcp</type>
              <port>9</port>
              <txt-record>dk0=adVN=timemachine,adVF=0x82</txt-record>
              <txt-record>sys=adVF=0x100</txt-record>
            </service>
          </service-group>
        '';
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
