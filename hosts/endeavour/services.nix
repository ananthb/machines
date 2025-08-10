{
  config,
  pkgs,
  ...
}:

{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  # Yubikey stuff
  services.udev.packages = with pkgs; [ yubikey-personalization ];
  services.pcscd.enable = true;

  # Enable resolved and avahi
  services.resolved.enable = true;
  services.avahi.enable = true;

  # Enable tailscale
  services.tailscale.enable = true;

  services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = false;

  services.tsnsrv = {
    enable = true;
    defaults.authKeyPath = config.sops.secrets."tsnsrv/auth_key".path;
    defaults.urlParts.host = "localhost";
  };

  # arr stack
  services.transmission = {
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

      download-dir = "/srv/media/Downloads";

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

  systemd.services.transmission.unitConfig.RequiresMountsFor = "/srv";

  services.radarr.enable = true;
  services.radarr.group = "media";
  systemd.services.radarr.wants = [
    "transmission.service"
    "prowlarr.service"
  ];

  services.sonarr.enable = true;
  services.sonarr.group = "media";
  systemd.services.sonarr.wants = [
    "transmission.service"
    "prowlarr.service"
  ];

  services.prowlarr.enable = true;
}
