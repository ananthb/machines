{
  config,
  pkgs,
  username,
  ...
}:
{
  services = {
    # Time Machine server via Samba
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "server string" = "Time Machine";
          "server role" = "standalone server";

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
          "valid users" = username;
          browseable = "yes";
          writeable = "yes";
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

  systemd = {
    tmpfiles.rules = [
      "d /srv/timemachine 0750 ${username} users -"
    ];

    services.samba-setup-timemachine = {
      description = "Set up Samba user for Time Machine";
      wantedBy = [ "multi-user.target" ];
      before = [ "samba-smbd.service" ];
      after = [ "samba-nmbd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        SMB_USER=$(cat ${config.sops.secrets."samba/timemachinesrv/username".path})
        SMB_PASS=$(cat ${config.sops.secrets."samba/timemachinesrv/password".path})
        echo -e "$SMB_PASS\n$SMB_PASS" | ${pkgs.samba}/bin/smbpasswd -s -a "$SMB_USER"
      '';
    };
  };

  sops.secrets = {
    "samba/timemachinesrv/username" = { };
    "samba/timemachinesrv/password" = { };
  };
}
