{ config, pkgs, ... }:

{
  services = {
    transmission = {
      enable = true;
      package = pkgs.transmission_4;
      group = "media";
      downloadDirPermissions = "775";
      settings = {
        rpc-bind-address = "[::]";
        rpc-whitelist = "*";
        rpc-host-whitelist = "*";

        umask = "002";
        proxy_url = "socks5://localhost:8080";

        watch-dir-enabled = true;

        alt-speed-up = 1000; # 1000KB/s
        alt-speed-down = 1000; # 1000KB/s

        # Scheduling option docs:
        # https://github.com/transmission/transmission/blob/main/docs/Editing-Configuration-Files.md#scheduling
        alt-speed-time-enabled = true;
        alt-speed-time-begin = 540; # 9am
        alt-speed-time-end = 1020; # 5pm
        alt-speed-time-day = 127; # all days of the week
      };
    };

    radarr = {
      enable = true;
      group = "media";
    };

    sonarr = {
      enable = true;
      group = "media";
    };

    prowlarr = {
      enable = true;
    };
  };
}
